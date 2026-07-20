---
name: harden
description: Quality-hardening sweep of one subsystem — fallbacks that hide bugs, dual state, race conditions, test theatre, and dead code — fixed in a worktree and delivered as a PR. Use when the operator asks to harden, clean up, or do a quality pass on a subsystem.
---

# /harden <subsystem>

One subsystem per invocation. `docs/architecture/overview.md` is the catalog of every
subsystem and the source files it owns; a subsystem's own deep-dive doc, if one exists, is
`docs/architecture/sub-systems/<subsystem-slug>.md` (create it on first run if absent).

Never commit to main — do the sweep in its own worktree/branch, same as every other skill.

## 1. Scope

Resolve `<subsystem>` against `docs/architecture/overview.md`; fail fast if it isn't catalogued
there, or if the catalog and the files on disk disagree — an orphan file is itself a bug, not
something to sweep past. Check `docs/flow/board.md` for other in-progress work touching the same
files before starting. Read the subsystem's source and its deep-dive doc, then work in a
worktree: `git worktree add ../<repo>-harden-<subsystem-slug> -b harden/<subsystem-slug> origin/main`.

## 2. Sweep

Walk the subsystem in order of severity:

- **Fallbacks that hide bugs** — swallowed `catch` blocks, `?? fallback` / `|| ''` / `|| []` on
  values that should never be empty, defaults that create a phantom entity instead of throwing.
- **Dual state** — the same fact tracked in two places; consolidate to the authoritative layer
  below, don't add syncing code.
- **Race conditions** — unguarded shared state, check-then-act gaps, fire-and-forget async with
  no error handling.
- **Test theatre** — dispatch `.claude/agents/test.md` in audit mode to classify every test
  covering the subsystem (`test` owns theatre detection — the single source for theatre red
  flags everywhere they're checked). Theatre = the test would still pass if the implementation
  were deleted or broken.
- **Dead code** — unreachable branches, unused exports/imports, stale flags, TODOs with no
  linked issue.

Cross-check findings against the shared error-handling, security, and testing rules in
`.claude/code-quality/` — this sweep is how those rules get enforced inside a subsystem.

## 3. Fix

Behavior-preserving unless the behavior itself was the bug — call those out explicitly.

- **Small, behavior-preserving fixes:** make them inline, in this session.
- **Theatre-test rewrites:** dispatch `.claude/agents/test.md` — use the real object under test,
  mock only external boundaries (network, filesystem, IPC), and assert on observable outcomes
  (return value, state change, emitted event), never just a mock call count.
- **Substantial or large fixes** beyond a small inline patch: dispatch `.claude/agents/builder.md`.

Something cross-subsystem or too large for this PR becomes its own `/harden` invocation — file
an issue rather than ballooning the diff.

## 4. Verify

Run the project's fmt/lint/test commands, as declared in `docs/code/conventions.md`. All must be
clean before moving on.

## 5. PR

Title `harden(<subsystem>): <summary>`; body lists each finding and its fix. Update the
subsystem's deep-dive doc if reality had drifted from what it describes. Present the PR to the
operator — they merge it, never auto-merge.

## Failure handling

A failing test is a signal, not an inconvenience — never edit a test just to make it pass. Fix
the code, or dispatch `.claude/agents/test.md` to classify it as theatre and rewrite it against
real behavior. If verification fails or a fix doesn't hold, report what broke and stop.
