# Duplicate Code Path Escalation

**Code-quality rule — subset-scoped.** Loaded by the code-quality agents (builder, test,
planner, reviewer) through their own definitions, not by a universal set.

If you discover the same behavior implemented in multiple code paths, **STOP and escalate
— flag it for the operator, or dispatch `planner` for a deeper call**. Do not work around,
do not consolidate yourself.

Report: which files/functions implement the same behavior, and how you discovered it. Flag
it as a SOLID violation.

## Applies to

Every agent reading implementation code:

- **builder** — escalates on discovery; never consolidates duplicate paths unilaterally.
- **test** — escalates when tests reveal the same behavior in multiple paths.
- **reviewer** — escalates duplicate paths found during review rather than requesting an
  ad-hoc merge.
- **planner** — the escalation **target** for a genuinely load-bearing call; owns the
  consolidation decision and design.
- **`/harden`** — escalates dual code paths surfaced during subsystem cleanup the same way.
