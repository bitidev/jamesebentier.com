---
name: setup-machine
description: Gets the developer's local machine ready for issue work — gh auth, .env, and RTK (Rust Token Killer) readiness, then validates repo access. Run right after `adlc-init`, or any time the local environment needs (re)configuring.
---

# /setup-machine

`/adlc-init` prepares the **repo** for ADLC; `/setup-machine` prepares the **developer's machine** to work it — the onboarding sequence is `/adlc-init` → `/setup-machine` → start work. Runs entirely in the main session; no agent dispatch.

## 1. gh Auth

Verify `gh auth status`. If not authenticated, guide the operator through `gh auth login` (install from https://cli.github.com if `gh` itself is missing). Confirm the repo auto-detects from `git remote`:
```bash
gh repo view --json nameWithOwner --jq .nameWithOwner
```
`GITHUB_TOKEN`/`GH_TOKEN` is optional — a non-interactive/CI-only alternative to `gh auth login`. Leave it unset for the normal interactive flow.

## 2. RTK (Rust Token Killer) Readiness

Check, in order:
1. `rtk --version` — binary present?
2. `rtk gain` — confirms the token-killer variant (collision guard: a same-named but unrelated "Rust Type Kit" package exists).
3. `grep -q "rtk hook claude" ~/.claude/settings.json` — PreToolUse hook wired?

Unlike `/adlc-init`'s read-only version of this same check, fix what's missing here: `cargo install rtk` (needs a Rust toolchain — `curl https://sh.rustup.rs -sSf | sh` if absent), re-run `rtk gain` to confirm the variant, then add the hook to `~/.claude/settings.json`'s `PreToolUse` if it isn't already there:
`{"matcher": "Bash", "hooks": [{"type": "command", "command": "rtk hook claude"}]}`
Non-blocking — note any remaining gap and continue. The operator restarts their Claude Code session for a newly-added hook to take effect.

## 3. .env Setup

Copy `.env.sample` → `.env` if missing. Prompt only for the variables the project's `.env.sample` marks as required — never assume defaults for user-specific values (emails, tokens, project keys), and ignore example placeholder values. GitHub auth needs no `.env` variable (it comes from `gh auth login`). For deeper OS- or stack-specific setup issues, see `adlc/templates/setup-guide.md` (resolved via the framework source in `.claude/adlc.manifest.json`, same as `/adlc-init`).

## 4. Script Execution & Validation

Steps 1-3 (gh auth, RTK, `.env`) must be complete first. Then run the project's own setup scripts, if any, with the now-populated variables, and validate:
```bash
gh auth status && echo "authenticated"
gh issue list --state open --limit 3 && echo "issues access verified"
```

## Failure handling

Report exactly what's blocked and the concrete next action — `gh` not installed, not authenticated, an RTK collision with the wrong package, a required `.env` value still unset. Don't guess at credentials or silently skip a failing check.
