---
name: adlc-init
description: Analyzes a project's codebase and provisions everything the ADLC skill flow needs — docs/code and docs/architecture knowledge artifacts, the skill/agent/Cursor surface (core, meta, and detected opt-in), the GitHub Project board, consumer CI, and the install manifest. Run once per new project, or `adlc-init verify` to check existing artifacts for drift.
---

# /adlc-init

Analyzes a codebase and generates the project-specific knowledge the agents in `.claude/agents/` (`builder`, `test`, `planner`, `reviewer`) need, then provisions everything else the skill flow depends on: the board, consumer CI, and the Claude Code + Cursor runner surface. Runs entirely in the main session — it never dispatches an agent; where a step needs something written (e.g. a generated CI YAML file), the main session writes it directly.

Every artifact below is **preserve-edits** by default: created if absent, left untouched if already present, unless a step says otherwise. Every `adlc/...` path below resolves against the framework source recorded in `.claude/adlc.manifest.json` (a local checkout path, or a `git` fetch of the recorded URL if the local path isn't available) — not the project being initialized.

## 1. Determine the Mode

Two paths: an **initial run** (extract project knowledge from scratch and provision scaffolding) or **`adlc-init verify`** (validate existing artifacts against the current codebase — step 13). Default to a full initial run unless the operator asks for something narrower or explicitly requests `verify`. If `verify` is requested but no artifacts exist yet, say so and point at the initial run instead.

## 2. Analyze the Codebase

Extract project-specific knowledge for AI-agent guidance, not user-facing documentation. Cover: the architecture pattern and component/service boundaries with dependency rules; the technology stack with versions and rationale; naming, file-organization, and git-workflow conventions; recurring patterns (error handling, API integration, validation, logging, config, testing, auth, performance) with DO/DON'T examples; anti-patterns with correct alternatives; integration points (external APIs, DB/ORM, messaging, auth, retry/timeout/circuit-breaker); and an API/service catalog. Draw every example from this project's actual code — real file paths and rationale, never generic advice or placeholder content. Where artifacts already exist, merge intelligently (preserve what's still valid, update what's stale) rather than overwriting wholesale.

## 3. Generate Code Guidance (`docs/code/`)

Write:
- `docs/code/adlc-init.md` — comprehensive project knowledge (architecture, stack, conventions, patterns, anti-patterns, integrations, troubleshooting, decision rationale).
- `docs/code/patterns.md` — recurring patterns with DO/DON'T examples.
- `docs/code/conventions.md` — team conventions and standards; must include a **Language Standards** section naming the selected guide(s) from the framework source's `adlc/templates/language-best-practices/` — always `universal.md` plus the matching stack file(s) (e.g. `ruby.md` + `rails.md` for Rails), per that directory's `universal.md#how-agents-select-the-right-file` table — and copy them into `docs/code/`, since there's no live framework symlink to read them from anymore.
- `docs/code/anti-patterns.md` — anti-patterns with correct alternatives.
- `docs/code/troubleshooting-playbook.md` — symptoms → causes → fixes → prevention.

## 4. Generate Architecture Boundary Records (`docs/architecture/`)

Create `docs/architecture/` and `docs/architecture/sub-systems/` if missing. Copy `adlc/templates/architecture-overview.md` → `docs/architecture/overview.md` if it doesn't already exist (never overwrite) — the authoritative subsystem list, file catalog, and dependency graph. Seed the file catalog from `git ls-files <source-roots>` — the project's actual source roots, not a hand-listed guess — so it stays complete and one-to-one with tracked source files; hand-listing is lossy past a trivial codebase. Derive one `docs/architecture/sub-systems/<slug>.md` per subsystem from `adlc/templates/subsystem.md`. Design decisions live per-subsystem under each doc's Key Design Notes — there is no separate ADR file. (Per-issue specs, `docs/specs/<N>-<description>.md`, are a separate artifact this skill doesn't generate.)

## 5. Scaffold Strategic & Internal Priorities

Copy `adlc/templates/strategic-priorities.md` → `docs/strategic-priorities.md` if missing (never overwrite) — ships pre-populated with a trust-building default posture (small, self-contained issues while confidence builds), not an empty skeleton; `/triage` treats it as a required input every cycle. Copy `adlc/templates/internal-priorities.md` → `docs/internal/priorities.md` if missing (never overwrite) — P0/P1/P2 execution-order weighting with `{placeholder}` slots the operator fills in; unlike the strategic doc, a missing weighting doc only degrades sequencing to live-cadence heuristics, not a hard gate.

## 6. Deploy the Skill + Agent Surface

Ensure `.claude/skills/` holds every core and meta skill, and `.claude/agents/` holds all four agents (`builder`, `test`, `planner`, `reviewer`) — copied verbatim (self-contained, project-root-relative references; no symlink, no path rewriting) from the framework source's `adlc/.claude/skills/` and `adlc/.claude/agents/`. `setup.sh` performs this copy at first bootstrap; this step re-verifies it's complete — useful when `/adlc-init` runs standalone, or a skill/agent was added to the framework since bootstrap.

## 7. Web/API Detection → Opt-in Skills

Detect whether the project has a real web/API/build surface, and deploy the matching opt-in skill(s) from the framework source into `.claude/skills/` (recording each in the manifest — step 12):

| Signal | Detected via | Deploys |
|---|---|---|
| Web/UI | `package.json` with a frontend framework (react/vue/svelte/angular/next); `.html`/`.jsx`/`.tsx`/`.vue`/`.svelte` sources; a component library | `audit` |
| API/service | An OpenAPI/Swagger/GraphQL schema; an HTTP server framework (express/fastify/rails/django/fastapi/spring); an API-client dir | `integrate` |
| Real build/runtime env | Any of the above, or a non-trivial toolchain (`Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, `Dockerfile`) | `troubleshoot` |

Report what matched — a docs/prompt-only project (like ADLC itself) matches none, and deploys no opt-in skills.

## 8. Provision `docs/flow/` + the GitHub Project Board

Ensure `docs/flow/models.md` exists (copy from `adlc/templates/flow/models.md` if missing) — this replaces the retired machine.md model-table deploy step; model/effort now live in each agent's own frontmatter, so this file is rationale-only.

Create or validate the GitHub Project board: check the `project` OAuth scope (`gh auth status`; if missing, `gh auth refresh -h github.com -s project`), create the project if none exists, configure the Status field, and confirm the timestamp fields are visible. `docs/flow/board.md` is the single source for the exact status vocabulary and the GraphQL update sequence — follow it rather than re-deriving either here. Report the project URL, then fill the `{OWNER}`/`{NUMBER}` placeholders in `docs/flow/board.md` from the board just created or validated.

## 9. Install `CLAUDE.md` + Regenerate the Cursor Adapter

Install the self-contained, skills-routing `CLAUDE.md` at the project root — sourced from `adlc/templates/session-rules.md`, no `@import` (there's no live framework symlink for one to resolve). Create if missing; if present, reconcile the ADLC-owned block and preserve project-specific content. (The exact routing content is a later stage's concern — this step only gets it in place.)

Regenerate the Cursor adapter: refresh `.cursor/rules/adlc-rules.mdc` from `adlc/templates/cursor-rules.mdc` (preserve operator edits), and write one `.cursor/commands/<skill-name>.md` per deployed skill (core + meta + any opt-in) — each a thin pointer to that skill's own `.claude/skills/<name>/SKILL.md`, so the `SKILL.md` stays the single source.

## 10. Consumer CI + Merge Guard

Detect an existing `pull_request`-triggered CI workflow; add a `ci-gate` aggregator job if it lacks one. If none exists, create `.github/workflows/ci.yml` running the project's lint/typecheck/test commands as parallel jobs behind a `ci-gate` aggregator. Create `.github/workflows/merge-guard.yml` (a `workflow_run`-triggered workflow posting a `merge-guard` commit status and managing a `ci-failing` label) for soft enforcement on every plan. Configure branch protection on `main` requiring `ci-gate` via `gh api` where the plan allows (public repo or Pro+); otherwise file a follow-up issue documenting what to configure after a plan upgrade, and report soft-enforcement status.

## 11. RTK Readiness Check

Read-only — this surfaces state and remediation; it does not install RTK or touch the hook (that's `setup.sh`'s and `/setup-machine`'s job). Check, in order: `rtk --version` (binary present?), `rtk gain` (confirms the token-killer variant, not the unrelated same-named "Rust Type Kit" package), and `grep -q "rtk hook claude" ~/.claude/settings.json` (hook wired?). Fold whichever fail into the summary output (step 14) with a pointer to `/setup-machine` — non-blocking.

## 12. Record the Manifest

Ensure `.claude/adlc.manifest.json` reflects the current deploy: where the framework came from (local checkout path and/or a git URL), the installed version, the install timestamp, and which skills were deployed (core/meta/opt-in). Create it if a hand-set-up project skipped `setup.sh`; otherwise update the skills list with anything this run added (e.g. a newly-detected opt-in skill) and bump the recorded version if the framework source has moved on. This is what the `sync` and `contribute` skills read to refresh a consumer or push edits back upstream.

## 13. Verify Mode (`adlc-init verify`)

Re-check generated artifacts against the current codebase instead of regenerating from scratch: validate `docs/code/*` claims (architecture, stack, patterns, conventions) still hold; check `docs/architecture/overview.md`'s file catalog for orphans (tracked source files missing from the catalog) and stale entries (catalogued files missing on disk); confirm every subsystem in `overview.md` has a `sub-systems/<slug>.md`; and confirm the board's Status field options exactly match the canonical vocabulary in `docs/flow/board.md` (no extra, renamed, or missing option). Categorize findings by severity (Critical/Major/Minor) and write `docs/VERIFICATION-init.md`.

## 14. Report

Summarize: the architecture pattern and counts (patterns/conventions/anti-patterns/integration points); which opt-in skills deployed and why; the board URL (created or verified); `CLAUDE.md` / Cursor-adapter / priorities-doc status (created, updated, or already-configured); CI-gate and branch-protection status; subsystem-architecture status; RTK readiness. Close by pointing the operator at `/setup-machine` next — this skill prepared the repo; the onboarding sequence is `/adlc-init` → `/setup-machine` → start work.

## Failure handling

Report exactly what blocked a step and what the operator needs to do — insufficient `gh` scope (needs an interactive `gh auth refresh` the operator must run), a plan that can't support hard branch protection, an ambiguous or undetectable stack, a manifest with no resolvable framework source. Don't improvise: don't invent board coordinates, don't skip a failing provisioning step silently, and don't guess at a stack match that didn't clearly hit.
