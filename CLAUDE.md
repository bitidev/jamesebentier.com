# Claude Code Instructions

This project runs on the ADLC skill flow. Work through the skills in `.claude/skills/` —
there is no orchestrator or dispatch relay; you (the session) coordinate directly and dispatch
the four agents in `.claude/agents/` (`builder`, `test`, `planner`, `reviewer`) yourself.

## Two hard rules, no exceptions

- **Never commit to main.** All work happens on an issue/task branch, in its own git worktree
  (never in the main checkout).
- **Never merge a pull request unless the operator explicitly instructs it in that moment.**
  Default is always present-and-wait — the operator merges. A standing "you can merge these"
  from earlier in the conversation does not count; each merge needs its own explicit
  go-ahead. Respect the repo's configured merge method; never force-push and never bypass a
  required check to force a merge through.

## Entry points

- **`/work <issue-number>`** — take an issue from Ready to Done: claim, design gate (features),
  implement via `builder` (+ `test`), PR with an advisory review and theatre-check, post-merge
  cleanup. Use this whenever the operator says "work on / implement / fix #N".
- **`/triage`** — screen new issues onto the board; move Triage items to Ready/Backlog/closed.
- **`/release [patch|minor|major]`** — cut and publish a release.
- **`/harden <subsystem>`** — quality-hardening sweep of one subsystem.
- **`/address-feedback [PR]`** — process a pull request's own review feedback item by item.
- Meta: `/adlc-init`, `/setup-machine`, `/sync`, `/contribute`. Opt-in (installed for this
  Rails web/API project): `/integrate`, `/audit`, `/troubleshoot`.

Each skill's full instructions live at `.claude/skills/<name>/SKILL.md` — read the relevant
one before acting on it.

## Board mechanics

`docs/flow/board.md` is the single source for the board-status vocabulary and the update
sequence every skill uses directly.

## Worktree isolation (guardrail)

Every issue/task gets its own `git worktree`; never edit files in the main checkout. Verify
with `git branch --show-current` before touching anything — if it returns `main`/`master`,
stop and create a worktree first.
