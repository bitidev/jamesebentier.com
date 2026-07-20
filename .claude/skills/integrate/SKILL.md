---
name: integrate
description: Generate or update a spec-compliant API client from an OpenAPI/Swagger/GraphQL/WSDL/Postman (or documented) specification, with strict spec fidelity and no hallucinated endpoints. Use when the operator asks to add, regenerate, or update an API client from a specification, or when /work identifies an issue as API-client work.
---

# /integrate [issue-or-spec]

You (the main session) analyze the specification and scope the client, then dispatch the
**builder** agent (`.claude/agents/builder.md`) to write the code — builder owns all committed
production code, so this skill hands it the spec-fidelity rules below rather than generating code
itself. Board mechanics: `docs/flow/board.md`. Stack detection: `docs/code/conventions.md`.

Hard rule: **the specification is absolute truth.** Never generate a method, parameter, type, or
behavior the spec doesn't document — refuse and document the gap instead of guessing.

## 1. Claim

Standalone issue ("add the X API client"): claim and open a worktree exactly as
`.claude/skills/work/SKILL.md` Step 1 does (assign, board status **In Progress**, worktree).
Already inside a `/work` invocation (issue claimed, worktree open): skip this and continue there.

## 2. Analyze the specification

- Identify the spec format (OpenAPI, Swagger, GraphQL, WSDL, Markdown/wiki docs, Postman
  collection) and extract its metadata: base URL, versioning, auth mechanism, headers, rate
  limits, content types.
- Catalog every documented endpoint: HTTP method, parameters (required vs. optional), request/
  response schemas, documented error codes.
- Detect the target stack from `docs/code/conventions.md` (Technology Stack): language, HTTP
  client, typed-model/validation library. Fall back to whatever stack the spec or the operator
  states if that doc doesn't cover it.
- Flag gaps instead of guessing: missing information, ambiguous behavior, or a requested method/
  parameter that isn't in the spec all become an open question, not an assumption.

## 3. Dispatch builder with the spec-fidelity rules

Dispatch builder with: the spec (or its location), the endpoint catalog, the detected stack, and
these non-negotiable rules:

- One method per documented endpoint, named and typed per the spec; required parameters stay
  required and optional stay optional, exactly as specified.
- Typed request/response models, in the project's own typed-model/validation library, that reject
  fields the spec doesn't document.
- Enums as closed sets with a safe-parse path that rejects out-of-spec values rather than coercing
  them.
- Response handling strictly by documented status code: success parses into the typed model,
  documented errors raise the specific typed error, and an undocumented status raises an explicit
  **"not documented in the specification" error — never a silent success.**
- Authentication implemented exactly as the spec documents — no invented flows or headers.
- Client-layer scope only: no business logic, no application-level error handling beyond API
  errors, no caching/retry/circuit-breaker, no UI.
- Anything requested that isn't in the spec: refuse it, leave a comment citing the spec section
  and the gap, and note the spec-compliant alternative — never implement a guess.

Then dispatch **test** (`.claude/agents/test.md`) for spec-compliance tests: every endpoint has a
method and no method exists without one, missing-required/unexpected parameters are rejected, and
the documented success/error/undocumented-status handling behaves as specified. Builder never
writes tests — that's true here too, even for generated client code.

## 4. Verify spec compliance

Confirm every documented endpoint has a corresponding method and vice versa (no orphans),
required/optional and types match the spec exactly, authentication is fully implemented, and
every documented error code is handled. This is in addition to builder's own standing fmt/lint/
test verification, not a replacement for it.

## 5. PR, or hand back

Standalone: push, `gh pr create` (`[#N] <summary>`, `Closes #N`), board status **In Review**, one
`code-review` pass, present the PR URL and stop — wait for the operator to merge or say so.
Mid-`/work`: hand control back to `/work`'s own PR step instead of opening a second PR.

## Failure handling

Spec gaps, ambiguity, or a request that conflicts with the spec: stop and report the mismatch
(name the offending method/parameter and what the spec actually allows) rather than guessing.
Environment failures (missing tool, auth, install errors): hand off to `troubleshoot`
(`.claude/skills/troubleshoot/SKILL.md`), then resume where you left off.
