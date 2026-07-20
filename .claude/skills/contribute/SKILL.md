---
name: contribute
description: Push this project's own edits to its skills, agents, or hooks back upstream into core ADLC as a pull request — the inverse of /sync. Use when the operator asks to contribute, upstream, or push back a framework-surface improvement made while using ADLC.
---

# /contribute

The inverse of `.claude/skills/sync/SKILL.md`: pushes a local framework-surface edit **up** into
core ADLC. Outward-facing — opens a PR against a *different* repository — same posture as
`.claude/skills/release/SKILL.md`: **always confirm with the operator before pushing anything.**

## 1. Locate the framework

Read `.claude/adlc.manifest.json` for `source`. Prefer the local path if it resolves; otherwise
`git clone`/`fetch` the recorded URL to a temp checkout and branch there.

## 2. Diff against the authoring source

Map every deployed path back to its authoring path in the framework checkout:

- `.claude/skills/<name>/SKILL.md` → `adlc/.claude/skills/<name>/SKILL.md`
- `.claude/agents/<name>.md` → `adlc/.claude/agents/<name>.md`
- `.claude/hooks/<name>.sh` → `adlc/.claude/hooks/<name>.sh`
- `.claude/code-quality/<name>.md` → `adlc/.claude/code-quality/<name>.md`
- `docs/flow/models.md` → `adlc/templates/flow/models.md`
- `docs/flow/board.md` → `adlc/templates/flow/board.md` — **re-templatize the filled
  `{OWNER}`/`{NUMBER}` coordinates back to placeholders** before diffing; those are
  project-specific and never upstreamed.

## 3. Partition — never push project-specific content

- **Upstreamable:** genuine skill/agent/hook/code-quality edits, and the mechanic (non-coordinate)
  parts of `docs/flow/{board,models}.md`.
- **Never pushed:** `adlc-customizations/**`, filled board coordinates, any project doc
  (`docs/code/**`, `docs/architecture/**`, `docs/design/**`, `docs/specs/**`), this project's own
  `CLAUDE.md` content, `.claude/settings.json` local edits, the manifest itself, and any deployed
  file that was never actually edited.

## 4. Confirm

Present the full upstreamable diff to the operator and **stop for explicit confirmation** — this
is outward-facing and never automatic, exactly like a release publish.

## 5. Push

On confirmation: in the framework checkout, create a new branch, apply the upstreamable changes,
and `gh pr create` against core ADLC. If the operator lacks push access to that repo, fall back to
a fork + PR, or emit the diff as a patch file instead. Reuse the same copy/diff engine `/sync`
uses (`scripts/adlc-sync.sh`, if present) applied in reverse, rather than re-deriving the mapping.

The round trip: a change proposed here flows up via this PR, merges into core ADLC, and reaches
every other consumer the next time they run `/sync`. Core ADLC stays the one authoritative
source — this skill only *proposes* an edit to it.

## Failure handling

If the framework source can't be located, a path can't be cleanly mapped back to its authoring
location, or the operator doesn't confirm, stop and report — never push a partial or unconfirmed
change.
