# Model & Effort Notes

The mechanical source of truth is each agent's own frontmatter (`model:`, `effort:`) — the
runner reads it directly at dispatch time, so no relay is needed to pass it along. This note
records and rationalizes the choices across the skill sequence so a maintainer tuning models has
one place to reason about them. Skills themselves are not dispatched — they run inline in the
main session, at whatever model the operator selected for their session, unless noted otherwise
below.

| Skill / Agent | Model | Effort | Why |
|---|---|---|---|
| `planner` (agent) | opus | high | design errors are the most expensive to unwind |
| `builder` (agent) | sonnet | high | implementation breadth + correctness |
| `test` (agent) | sonnet | high | full behavior surface; theatre detection |
| `reviewer` (agent) | sonnet | xhigh | catch subtle regressions on a static pass |
| `/work` · `/triage` · `/release` · `/harden` · `/address-feedback` (session) | operator | — | coordination; runs at the operator's session model |
| `integrate` / `audit` / `troubleshoot` (session) | operator | — | structured, well-scoped domain work; still runs inline, but may dispatch `builder` for the actual code change |

## How this supersedes `machine.md`

- `machine.md`'s reason to exist was that the **orchestrator** read a central table and passed
  `model:` to the dispatch tool at invocation time (effort was frontmatter-only even then, due to
  a tooling limit on passing effort at dispatch). With the orchestrator retired, there is no
  relay — so **each agent carries both `model:` and `effort:` in its own frontmatter**, and the
  runner honors both directly. This removes the central-table indirection entirely.
- This file is therefore a **documentation/tuning surface**, not a mechanical dependency: it
  explains the per-skill sequence choices and rationale (the genuinely useful half of
  `machine.md`), while the values that actually drive dispatch live in the agent files
  themselves. `machine.md` is deleted — its model-table responsibility retires; its Cursor
  degradation note (below) relocates to `docs/architecture/runner-capability-contract.md`.

## On Cursor

Claude Code honors an agent's frontmatter `model:`/`effort:` at dispatch. Cursor's sub-agent
dispatch has no caller-passed model override, so on Cursor a dispatched agent inherits the
session's model instead of its own frontmatter value — a benign degradation (the agent still
runs, just without per-agent model differentiation), not a failure. This is a runner-capability
difference, not a skill or agent difference.

## Change protocol

1. Update the agent's own frontmatter (`model:`/`effort:`) — that is the source of truth the
   runner acts on.
2. Update the table above to match, so the rationale stays honest.
3. Do not reintroduce a central table that agents read at runtime — frontmatter is the only
   mechanical source now.
