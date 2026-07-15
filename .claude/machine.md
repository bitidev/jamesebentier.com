# ADLC Machine Layer — Model Selection Table

This file is the authoritative source of truth for model assignments across all
ADLC agents. The orchestrator reads this table and passes `model:` at dispatch
time — agent definition files do not need to specify `model:`.

## On effort levels

Ideally, effort levels would also be specified here and passed at dispatch time
by the orchestrator, the same way model is. Claude Code does not currently
support an `effort` parameter on Agent tool calls — effort can only be set via
agent definition frontmatter. Until that changes, effort is specified in each
agent's `.md` file. That is a tooling limitation, not a design choice. When
Claude Code adds dispatch-time effort support, effort moves here and out of the
agent files entirely.

## Model Selection Table

| Agent            | Model   | Rationale                                                                     |
|------------------|---------|-------------------------------------------------------------------------------|
| architect        | opus    | Architectural decisions require deepest reasoning; wrong plans are costly     |
| auditor          | sonnet  | WCAG remediation is precise but well-scoped                                   |
| code             | sonnet  | Implementation demands correctness and breadth                                |
| hardener         | opus    | Subsystem hardening requires identifying subtle drift; pattern-matching at depth |
| integrator       | sonnet  | API client generation is structured; spec-fidelity over raw horsepower        |
| merger           | sonnet  | PR feedback coordination is mostly coordination/dispatch logic                |
| orchestrator     | opus    | Workflow coordination requires judgment across ambiguous states                |
| product          | sonnet  | Issue triage and board management are well-structured tasks                   |
| release          | sonnet  | Release cutting is a structured, deterministic pipeline — precision over depth|
| reviewer         | sonnet  | Code review must catch subtle bugs and regressions                            |
| scribe           | sonnet  | Spec writing requires depth and precision; opus not needed for documentation  |
| setup            | sonnet  | Environment diagnosis is methodical                                           |
| test             | sonnet  | Test authorship requires understanding the full behavior surface              |

## On Cursor

This table is applied by the orchestrator at dispatch time **on Claude Code**:
the orchestrator reads it and passes `model:` to the dispatch tool's `model`
parameter (`adlc/methods/universal/directive-pattern.md`). On Cursor, this
file is present, readable, and even acted on by the orchestrator — the same
`orchestrator.md` runs there too, so it reads the table and emits `model:` in
its directive — but Cursor's sub-agent dispatch has no caller-passed model
override, so the emitted `model:` dead-ends at the dispatch step. Cursor
sub-agents inherit the session model instead (whichever model is selected in
the Cursor session). This is a benign degradation, not a failure: sub-agents
still spawn and run on a valid model — only per-agent model differentiation is
lost. Per-agent model tuning is a Claude Code capability; nothing breaks on
Cursor.

## Change Protocol

1. Update the table above.
2. Do NOT add `model:` to agent definition files — the orchestrator provides it
   at dispatch. Agent files carry `effort:` only (tooling limitation noted above).
