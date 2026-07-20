# Error Handling (Runtime)

**Code-quality rule — subset-scoped.** Loaded by the code-quality agents (builder, test,
planner, reviewer) through their own definitions, not by a universal set. (Failing
informatively — how any agent behaves when it hits a failure — is a general agent behavior;
the runtime clause here is the code-quality-specific degrade-visibly rule.)

Production code fails gracefully **and visibly**: on error, detect it, surface enough
context to diagnose it, and continue with degraded functionality only where doing so is
safe and observable.

**Degrade, never hide.** A silent fallback that masks a failure is worse than a crash — it
turns a loud bug into a quiet one. Graceful degradation means the system keeps working in a
reduced, *reported* mode, not that the failure disappears. Never swallow an error into a
default value, an empty result, or a catch block that logs nothing.

## Applies to

- **builder** — implements graceful, visible degradation; no error-swallowing fallbacks.
- **test** — exercises failure paths, not just the happy path; asserts that errors surface.
- **reviewer** — flags swallowed errors, empty catch blocks, and failures masked by
  fallbacks as blocking findings.
- **planner** — designs the failure model: which failures degrade, which must stop, and
  how each is reported.
- **`/harden`** — treats fallback-hidden bugs and dual state as drift to remove during a
  subsystem sweep (dispatching `builder` for the fix).
