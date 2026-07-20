# Security Practices (Runtime)

**Code-quality rule — subset-scoped.** Loaded by the code-quality agents (builder, test,
planner, reviewer) through their own definitions, not by a universal set. Secret hygiene —
never log/expose secrets, API keys, or tokens; never commit credentials — applies to every
agent that commits or handles output, code-quality subset or not; the validation/privilege
clauses below are the code-quality-specific runtime rules.

Production code that accepts external input or touches privileged operations:

- **Validate user inputs.** Treat all external input as untrusted; validate, and reject or
  sanitize at the boundary before it reaches logic or storage.
- **Follow least-privilege.** Grant each component, credential, and code path the minimum
  access it needs — no ambient authority, no broad-scope tokens where a narrow one works.

## Applies to

- **builder** — implements input validation at boundaries and scopes privileges tightly.
- **test** — exercises validation (rejects bad input, accepts good) and privilege limits.
- **reviewer** — flags unvalidated input reaching logic/storage and over-broad privileges.
- **planner** — designs the trust boundaries and the privilege model the code enforces.
- **`/harden`** — hardens boundaries and tightens over-granted access during cleanup
  (dispatching `builder` for the fix).
