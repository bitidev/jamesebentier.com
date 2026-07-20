# Testing Requirements

**Code-quality rule — subset-scoped.** Loaded by the code-quality agents (builder, test,
planner, reviewer) through their own definitions, not by a universal set. This is the one
code-quality doc every consumer gets unconditionally (always-deployed, not init-selected) —
the completion-gate + no-theatre testing baseline every agent can rely on regardless of
whether `/adlc-init` has run yet.

Before marking work complete: run relevant tests, fix failures before completion, document
how to test the changes.

**No success theatre.** Every test must assert observable behavior (return values, state
changes, side effects on real objects) — not just that a mock was called. Apply the
"delete test": if breaking the implementation wouldn't fail this test, rewrite it.

## Applies to

- **builder** — runs the relevant tests before declaring work complete and fixes failures
  rather than deferring them.
- **test** — owns the "no success theatre" bar; every assertion checks observable
  behavior, including the pyramid-placement check. See `.claude/agents/test.md`.
- **reviewer** — enforces the completion gate and flags theatre. **Reviewer does not run
  tests itself** (static analysis only) — it verifies that tests exist, pass, and assert
  real behavior.
- **planner** — plans account for how the resulting work will be tested and marked
  complete.
- **`/harden`** — treats theatre as drift to remove during a subsystem sweep, dispatching
  `test` for the rewrite.

## See also

- `.claude/agents/test.md` — the full theatre red-flag table, the pyramid-placement check,
  and the "no test-only production seams" inverse rule (production bent to accommodate
  tests) — both folded into the `test` agent itself rather than a separate method doc.
