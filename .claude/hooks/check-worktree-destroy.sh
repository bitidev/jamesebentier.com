#!/usr/bin/env bash
# Blocks Bash tool calls that destroy worktrees a session does not own.
#
# WHY THIS EXISTS
#
# Multiple concurrent Runner sessions share ONE repo and ONE .claude/worktrees/.
# Blanket worktree-destruction ops (`git worktree prune`, list-piped/looped/
# globbed `git worktree remove`, `rm -rf .claude/worktrees`) delete sibling
# sessions' worktrees, losing their uncommitted work. This hook allows only the
# sanctioned single-path cleanup (`git worktree remove <one-explicit-path>`) and
# blocks the blanket shapes.
#
# MODEL: PreToolUse, matcher Bash. The tool input arrives as JSON on stdin; the
# command is read from .tool_input.command (same as the adlc-init PostToolUse
# Bash hook). Non-zero exit blocks the call; the reason is printed to stderr.
#
# FAIL SAFE: on a genuine parse ambiguity around a worktree-remove target
# (variable/command-substitution/glob/multiple targets/no explicit path) this
# hook BLOCKS — nuking a sibling session is worse than a false block, which the
# user can clear with the bypass below.
#
# Emergency bypass: set ALLOW_WORKTREE_DESTROY=1 in the environment.

if [ "${ALLOW_WORKTREE_DESTROY}" = "1" ]; then
  exit 0
fi

# Read the tool call and extract the Bash command. An empty/unparseable
# envelope means there is nothing to inspect (no command to guard) — allow.
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$cmd" ]; then
  exit 0
fi

matches() { printf '%s' "$cmd" | grep -Eq "$1"; }

block() {
  echo "WORKTREE DESTROY BLOCKED: $1" >&2
  echo "Why: multiple Runner sessions share one repo and one .claude/worktrees/." >&2
  echo "This command can delete a SIBLING session's worktree and its uncommitted work." >&2
  echo "" >&2
  echo "Safe alternative: remove ONLY your own worktree, by exact path:" >&2
  echo "  git worktree remove <your-own-worktree-path>" >&2
  echo "Never 'git worktree prune' or blanket-remove the shared .claude/worktrees/." >&2
  echo "Emergency bypass (use only if you truly own every target): ALLOW_WORKTREE_DESTROY=1" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Rule A — `git worktree prune` (any flags). Prunes EVERY worktree whose dir is
# missing, including sibling sessions' — never safe in a shared checkout.
# ---------------------------------------------------------------------------
if matches 'worktree[[:space:]]+prune'; then
  block "'git worktree prune' removes every worktree with a missing dir, not just yours."
fi

# A destructive target is one whose removal destroys the shared worktree store:
#   * .claude/worktrees and anything under/globbing it (subpaths, /* globs)
#   * the parent .claude directory itself (as a standalone token, e.g. `rm .claude`)
#   * a .claude/* glob (expands to include worktrees/)
# It deliberately does NOT match a specific sibling file under .claude such as
# `.claude/settings.json` — removing that does not destroy the worktree store.
CLAUDE_STORE='\.claude/worktrees|\.claude/\*|\.claude([[:space:]]|[;&|]|$)'

# A recursive flag: a short flag cluster containing r or R in EITHER case
# (-r/-R/-rf/-Rf/-fr/-fR, GNU+BSD), or the long-form --recursive. Case matters:
# BSD and GNU both accept capital -R, so a lowercase-only match is a real hole.
RECURSIVE_FLAG='(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)'

# ---------------------------------------------------------------------------
# Rule C — recursive `rm` targeting the shared worktree store. Closes the holes
# a linear "flag-before-path, lowercase-r-only" regex left open:
#   * capital -R / -Rf / -fR  (case-insensitive flag cluster)
#   * long-form --recursive --force
#   * flag AFTER the path (`rm .claude/worktrees -rf` — GNU getopt reorders)
#   * parent-dir / parent-glob targets (`rm -rf .claude`, `rm -rf .claude/*`)
# Each `rm ...` invocation is isolated up to the next shell separator (so an
# unrelated `.claude/...` token elsewhere in a chained command cannot cause a
# false block, and a flag/target on either side of the path is still seen), then
# tested for a recursive flag AND a destructive target within that one segment.
# The leading `(^|[^[:alnum:]_])` is a word boundary so `perform`/`chmod`/etc.
# are not misread as an `rm` invocation.
# ---------------------------------------------------------------------------
rm_segments=$(printf '%s' "$cmd" | grep -Eo '(^|[^[:alnum:]_])rm[[:space:]]+[^;&|]*')
while IFS= read -r seg; do
  [ -z "$seg" ] && continue
  if printf '%s' "$seg" | grep -Eq "$RECURSIVE_FLAG" \
     && printf '%s' "$seg" | grep -Eq "$CLAUDE_STORE"; then
    block "recursive 'rm' of the shared .claude worktree store destroys sibling worktrees."
  fi
done <<< "$rm_segments"

# ---------------------------------------------------------------------------
# Rule D — `find`-based deletion of the shared worktree store. An rm-only rule
# is blind to `find .claude/worktrees -delete` and
# `find .claude/worktrees -exec rm -rf {} +`, which delete just as thoroughly.
# Block when a `find` invocation references a destructive target AND carries a
# deletion action (-delete, -exec, or -execdir).
# ---------------------------------------------------------------------------
if matches '(^|[^[:alnum:]_])find[[:space:]]'; then
  if matches "$CLAUDE_STORE" && matches '(-delete|-execdir|-exec)([[:space:]]|$)'; then
    block "'find' with -delete/-exec against the .claude worktree store removes sibling worktrees."
  fi
fi

# ---------------------------------------------------------------------------
# Rule B — blanket/looped/globbed `git worktree remove`. Only a single explicit
# path is allowed (`/work`'s sanctioned post-merge cleanup of its OWN worktree).
# ---------------------------------------------------------------------------
if matches 'worktree[[:space:]]+remove'; then
  # More than one `worktree remove` in the command — a loop body or chained
  # multi-remove. Block.
  remove_count=$(printf '%s' "$cmd" | grep -Eo 'worktree[[:space:]]+remove' | grep -c .)
  if [ "$remove_count" -gt 1 ]; then
    block "multiple 'git worktree remove' in one command (loop/chain) can hit siblings' worktrees."
  fi

  # Piped from a worktree listing (`git worktree list ... | ... worktree remove`).
  if matches 'worktree[[:space:]]+list'; then
    block "'git worktree list' piped into 'worktree remove' removes every listed worktree."
  fi

  # xargs feeding worktree remove.
  if matches '\bxargs\b'; then
    block "'xargs ... git worktree remove' removes every piped worktree, not just yours."
  fi

  # for/while loop iterating worktrees.
  if matches '(^|[;&|`(){}[:space:]])(for|while)[[:space:]]'; then
    block "a for/while loop around 'git worktree remove' iterates over siblings' worktrees."
  fi

  # Isolate the remove target: everything after the first `worktree remove` up to
  # the next command separator.
  target=$(printf '%s' "$cmd" \
    | grep -Eo 'worktree[[:space:]]+remove[[:space:]]+[^;&|]*' \
    | head -1 \
    | sed -E 's/^worktree[[:space:]]+remove[[:space:]]+//')

  # Glob in the target (e.g. .../worktrees/*).
  if printf '%s' "$target" | grep -q '[*?]'; then
    block "a glob in 'git worktree remove' target matches every worktree under the pattern."
  fi

  # Variable or command substitution in the target — the resolved value is
  # unknown at guard time, so it could expand to any/all worktrees. Fail safe.
  if printf '%s' "$target" | grep -Eq '\$|`'; then
    block "'git worktree remove' target uses a variable/command-substitution — cannot verify it names only your worktree."
  fi

  # Count non-flag tokens in the target. Exactly one = a single explicit path
  # (ALLOW). Zero (no path, or flags only) or more than one = ambiguous/blanket
  # (BLOCK, fail safe).
  path_tokens=0
  for tok in $target; do
    case "$tok" in
      -*) : ;;            # a flag (e.g. --force / -f) — not a path
      *) path_tokens=$((path_tokens + 1)) ;;
    esac
  done
  if [ "$path_tokens" -ne 1 ]; then
    block "'git worktree remove' does not name exactly one explicit worktree path (found $path_tokens)."
  fi

  # Single explicit path — the sanctioned cleanup. Allow.
  exit 0
fi

# Nothing worktree-destructive detected.
exit 0
