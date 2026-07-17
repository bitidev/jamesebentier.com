# Spec: Bump GitHub Actions Workflow Dependencies + Unblock Pre-Existing RuboCop Lint Failures

- **Issue**: [#1155](https://github.com/bitidev/jamesebentier.com/issues/1155)
- **PR**: [#1165](https://github.com/bitidev/jamesebentier.com/pull/1165)
- **Parent epic**: #1147 (dependency upgrade umbrella) — this PR must **not** close #1147
- **Status**: Draft — pending re-approval of this revision before code proceeds
- **Author**: scribe agent
- **Version**: 2.0

## Overview

Four Dependabot PRs are currently open against `.github/workflows/`, each bumping a single GitHub Action used in this repo's CI/CD pipeline:

| Dependabot PR | Action | From | To |
|---|---|---|---|
| [#1096](https://github.com/bitidev/jamesebentier.com/pull/1096) | `actions/checkout` | `v4` | `v7` |
| [#1144](https://github.com/bitidev/jamesebentier.com/pull/1144) | `actions/setup-node` | `v4.4.0` | `v7.0.0` |
| [#1149](https://github.com/bitidev/jamesebentier.com/pull/1149) | `actions/github-script` | `v7` | `v9` |
| [#1020](https://github.com/bitidev/jamesebentier.com/pull/1020) | `dependabot/fetch-metadata` | `v2.5.0` | `v3.1.0` |

This spec consolidates all four bumps into a single PR rather than merging them individually, so that CI is validated once against the full set of new action versions and the four superseded Dependabot PRs can be closed together. This is pure CI/CD infrastructure maintenance — no application code, Gemfile, or package.json dependencies change.

### Scope expansion (v2.0)

The GHA bumps above are implemented on PR [#1165](https://github.com/bitidev/jamesebentier.com/pull/1165) and match this spec's original (v1.0) requirements. However, the PR's `lint` job — and therefore its `ci-gate` and `merge-guard` status checks — is currently **red**, because the `lint` job (RuboCop) fails on **pre-existing offenses already present on `main`**, not on anything introduced by the GHA bumps. CI run: [29620475230](https://github.com/bitidev/jamesebentier.com/actions/runs/29620475230), lint job: [88014375904](https://github.com/bitidev/jamesebentier.com/actions/runs/29620475230/job/88014375904) — `54 files inspected, 10 offenses detected, 4 autocorrectable`.

Given three options for handling this (leave PR red and open a separate follow-up issue; revert to draft until a separate Lint-fix PR merges first; or fix the Lint debt in this same PR) — the user has explicitly chosen **option C**: expand the scope of #1155 so PR #1165 also clears these RuboCop offenses, unblocking `ci-gate`/`merge-guard` directly on this PR rather than deferring to a follow-up. This is scope creep relative to the original "GHA bumps only" framing, but it is the pragmatic choice: the debt blocks *this* PR's own gate regardless of which PR fixes it, and bundling avoids a second review/merge cycle. The original GHA bump scope (Overview above, Requirements/Implementation Details below) is unchanged and remains fully in force — the "RuboCop / Lint Unblock" section below is purely additive.

Locally reproduced against this worktree's current `HEAD` (`bundle exec rubocop`) — offense count and locations match the CI run exactly, confirming this is stable, pre-existing debt on `main` and not flaky/environment-specific.

## Current State (Inventory)

All matching `uses:` lines in `.github/workflows/` as of this spec:

| File | Line | Job | Current pin |
|---|---|---|---|
| `.github/workflows/ci.yml` | 19 | `danger` | `actions/checkout@v4` |
| `.github/workflows/ci.yml` | 35 | `lint` | `actions/checkout@v4` |
| `.github/workflows/ci.yml` | 54 | `test` | `actions/checkout@v4` |
| `.github/workflows/ci.yml` | 59 | `test` | `actions/setup-node@v4.4.0` |
| `.github/workflows/resume.yml` | 11 | `build` | `actions/checkout@v4` |
| `.github/workflows/merge-guard.yml` | 24 | `merge-guard` | `actions/github-script@v7` |
| `.github/workflows/automerge.yml` | 15 | `dependabot` | `dependabot/fetch-metadata@v2.5.0` |

No other workflow, composite action, or reusable-workflow file in the repo references these four actions (confirmed via repo-wide search of `.github/`).

## Requirements

1. Bump every occurrence of `actions/checkout` from `v4` to `v7` (3 occurrences in `ci.yml`, 1 in `resume.yml`).
2. Bump the single `actions/setup-node` occurrence in `ci.yml` from `v4.4.0` to `v7.0.0`.
3. Bump the single `actions/github-script` occurrence in `merge-guard.yml` from `v7` to `v9`.
4. Bump the single `dependabot/fetch-metadata` occurrence in `automerge.yml` from `v2.5.0` to `v3.1.0`.
5. Pin each action to the exact version referenced by its corresponding Dependabot PR (major.minor.patch tag, matching this repo's existing convention of pinning `setup-node`/`fetch-metadata` to full semver and `checkout`/`github-script` to major-only tags — preserve each action's existing pin granularity unless the Dependabot PR pins differently).
6. Do not modify any other `uses:` line, any application dependency manifest (`Gemfile`, `Gemfile.lock`, `package.json`, `yarn.lock`), or any workflow trigger/permission/job logic beyond what is strictly required by the version bumps (see Implementation Details for the one required behavioral adjustment, if any is found necessary during implementation).
7. Close out the four listed Dependabot PRs (#1096, #1144, #1149, #1020) as superseded once this PR merges — Dependabot will detect the version bump and auto-close/skip re-opening them; no manual dismissal command is required in this PR, but the PR description should reference all four for traceability.
8. This PR must reference/relate to #1155 only. It must **not** include a `Closes #1147` (or similar auto-close syntax) in the PR description, since #1147 is a multi-issue epic that stays open until all its children land.

## Implementation Details

### Files to change

- `.github/workflows/ci.yml` — 4 pin updates (3× `checkout`, 1× `setup-node`)
- `.github/workflows/resume.yml` — 1 pin update (`checkout`)
- `.github/workflows/merge-guard.yml` — 1 pin update (`github-script`)
- `.github/workflows/automerge.yml` — 1 pin update (`fetch-metadata`)

### Version-specific compatibility notes for the code agent

These are the breaking/behavioral changes identified between the current and target versions of each action. The code agent should verify each item against this repo's actual usage before/after editing, since GitHub Actions release notes can change before the PR lands.

**`actions/checkout` v4 → v7**
- v5 moved the action runtime to Node 24 (requires Actions Runner ≥ v2.327.1 — GitHub-hosted `ubuntu-latest` runners already satisfy this; no action needed for hosted runners).
- v6 changed `persist-credentials` to store credentials in `$RUNNER_TEMP` instead of `.git/config` — transparent to normal `git fetch`/`git push` usage; no workflow input changes required here.
- v7's headline change is that it now refuses to check out fork PR code by default when triggered by `pull_request_target` or `workflow_run`, unless `allow-unsafe-pr-checkout: true` is set. **Verify this does not apply to this repo**: none of the four `checkout` call sites run under `pull_request_target` or `workflow_run` triggers (`ci.yml` runs on `push`/`pull_request`; `resume.yml` runs on `push`). No new input is required.
- v7 also migrates the action to ESM internally — no consumer-facing input/output change.
- **Action**: straight version-string bump on all 4 occurrences; no other edits expected.

**`actions/setup-node` v4.4.0 → v7.0.0**
- v5 enabled automatic dependency-manager caching by default when `packageManager` is set in `package.json`, and moved the runtime to Node 24.
- v6 removed the deprecated `always-auth` input and narrowed automatic caching defaults to npm-only projects.
- v7 migrated the action to ESM; no input/output changes.
- The repo's single call site already sets `cache: yarn` explicitly, and does not use `always-auth`, so none of the default-caching or removed-input changes affect current behavior. Confirm `yarn.lock`-based caching still resolves correctly during CI verification (see Testing).
- **Action**: straight version-string bump; no other edits expected.

**`actions/github-script` v7 → v9**
- v8 moved the action runtime to Node 24.
- v9 upgraded the bundled `@actions/github` to v9 (ESM-only), which breaks scripts that `require('@actions/github')` directly or that redeclare `getOctokit` with `const`/`let`.
- The repo's single call site (`merge-guard.yml`) only uses the injected `github`, `context`, and `core` objects (`github.rest.repos.createCommitStatus`, `github.rest.pulls.list`, `github.rest.issues.getLabel/createLabel/addLabels/removeLabel`, `context.payload.workflow_run`, `core.info`) — it does not `require('@actions/github')` and does not redeclare `getOctokit`. No script changes are required.
- **Action**: straight version-string bump; no other edits expected. If the code agent finds any `require('@actions/github')` pattern anywhere in the script during implementation, it must be replaced with the injected `getOctokit` per the v9 migration guide before the bump is considered complete.

**`dependabot/fetch-metadata` v2.5.0 → v3.1.0**
- v3.0.0's breaking change is a runtime bump to Node 24 (again, transparent on GitHub-hosted runners).
- v3.1.0 is a backward-compatible bugfix release on top of v3.0.0 (improves `update-type` parsing for certain ecosystems); it does not change output keys.
- The repo's single call site (`automerge.yml`) reads `steps.metadata.outputs.update-type`, which is unchanged in v3.x.
- **Action**: straight version-string bump; no other edits expected.

### Non-goals for implementation

- Do not add `allow-unsafe-pr-checkout` to any workflow — none of the checkout call sites need it, and adding it unconditionally would be a security regression (see Security Considerations).
- Do not touch `ruby/setup-ruby@v1`, `MeilCli/danger-action@v6`, or `elgohr/Publish-Docker-Github-Action@v5` — they are out of scope for this issue.
- Do not touch `.github/dependabot.yml` grouping/config.

## RuboCop / Lint Unblock (added in v2.0)

**Goal**: get `bundle exec rubocop` to 0 offenses so the PR's `lint` job — and therefore `ci-gate` and `merge-guard` — go green, with the smallest, least-fragile diff per offense. No behavior change to application logic is required or permitted beyond what's listed here.

### Offense-by-offense fix strategy

| # | Location | Cop | Fix strategy | Correctable? |
|---|---|---|---|---|
| 1 | `app/controllers/application_controller.rb:6` | `Naming/PredicateMethod` | Code fix: rename `noindex` → `noindex?` | No |
| 2 | `app/helpers/welcome_helper.rb:3` | `Style/Documentation` | Code fix: add doc comment | No |
| 3 | `app/models/application_record.rb:8` | `Naming/PredicateMethod` | Code fix: rename `noindex` → `noindex?` | No |
| 4 | `bin/bundle:95` | `Style/IfUnlessModifier` | Inline `rubocop:disable`, matching file's existing convention | Yes (autocorrect not used — see rationale) |
| 5 | `config/initializers/declare_schema.rb:22` | `Layout/LineLength` | Code fix: wrap the string | No |
| 6 | `config/initializers/declare_schema.rb:28` | `Style/OneClassPerFile` | Inline `rubocop:disable`, matching file's existing convention | No |
| 7 | `config/initializers/declare_schema.rb:40` | `Style/OneClassPerFile` | Inline `rubocop:disable`, matching file's existing convention | No |
| 8 | `config/sitemap.rb:35` | `Style/IfUnlessModifier` | Code fix: modifier `if`, bundled with the `noindex?` rename call-site update | Yes |
| 9 | `spec/factories/post.rb:10` | `Rails/TimeZone` | Code fix: `Time.now` → `Time.current` | Yes |
| 10 | `spec/rails_helper.rb:27` | `Rails/RootPathnameMethods` | Code fix: `Dir[Rails.root.join(...)]` → `Rails.root.glob(...)` | Yes |

Repo-wide search (`rg -l noindex`) confirms the **complete** blast radius of the `noindex` rename: exactly 2 definitions (`application_controller.rb`, `application_record.rb`), 2 call sites (`config/sitemap.rb:35` and `:47`), and 5 documentation references (`docs/architecture/overview.md`, `docs/architecture/sub-systems/rails-runtime.md`, `docs/architecture/sub-systems/content-domain.md`, `docs/code/patterns.md`, `docs/code/adlc-init.md`). No views, JS, or specs reference it. This is a fully contained, low-risk rename — not a public gem API.

### 1 & 3. `Naming/PredicateMethod` — `noindex` → `noindex?`

**Preferred fix**: rename the boolean-returning class method on both `ApplicationController` and `ApplicationRecord` from `noindex` to `noindex?`.

**Rationale**: `noindex` returns a boolean and is used exclusively in boolean/conditional contexts (`if model.noindex`, `controller.noindex`) — it is textbook predicate-method shape, and RuboCop is correctly flagging the missing `?`. A `rubocop:disable` here would suppress a legitimate, low-cost style violation rather than fix it. The rename is small and fully enumerable (see blast-radius search above), so there is no hidden fan-out risk.

**Required companion edits** (all in the same commit as the rename, so nothing is left referencing the old name):
- `config/sitemap.rb:35` — `model.noindex` → `model.noindex?` (bundled with the `Style/IfUnlessModifier` fix for the same line, offense #8 below).
- `config/sitemap.rb:47` — `controller.noindex` → `controller.noindex?` (already in modifier form; only the method name changes here).
- Documentation accuracy follow-up (non-blocking for CI, but should land in the same PR to avoid drift): update the 5 doc references listed above (`docs/architecture/overview.md`, `docs/architecture/sub-systems/rails-runtime.md`, `docs/architecture/sub-systems/content-domain.md`, `docs/code/patterns.md`, `docs/code/adlc-init.md`) to say `noindex?`/`self.noindex?` instead of `noindex`/`self.noindex`. This does not change any subsystem boundary, export set, or dependency — it's a method-name-accuracy edit, not an architecture change, so no `docs/architecture/` structural update (new subsystem, moved responsibility, new edge) is triggered.

### 2. `Style/Documentation` — `WelcomeHelper`

**Preferred fix**: add a one-line top-level doc comment above `module WelcomeHelper` in `app/helpers/welcome_helper.rb`, e.g. describing its role as the view helper module for the welcome/landing page. Trivial, no rationale needed for an alternative — this is the cheapest possible fix and improves the codebase.

### 4. `Style/IfUnlessModifier` on `bin/bundle:95` — inline disable, not a rewrite

**Preferred fix**: add a trailing `# rubocop:disable Style/IfUnlessModifier` comment on the offending `if` line (line 95), matching this exact file's own pre-existing convention of trailing per-line/per-method `rubocop:disable` comments (see line 24: `# rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity`; line 86: `# rubocop:disable Metrics/MethodLength`; line 99: `# rubocop:disable Layout/LineLength`). `bin/bundle` is a Bundler-generated binstub; the existing inline disables prove this repo's convention is to hand-annotate this specific generated file rather than exclude it wholesale, so a new inline disable is the most consistent, minimal-footprint choice.

**Rejected alternatives**:
- **Autocorrect to modifier form** (`return if require_error.nil? && Gem::Requirement.new(...)...`): rejected because the resulting line would very likely trip `Layout/LineLength` (the guard clause plus method call chain is long), trading one correctable offense for a new one on a file we want to touch as little as possible.
- **`.rubocop.yml` `Exclude: bin/**/*` for this cop**: rejected as broader than necessary — there is exactly one offense in `bin/`, and a per-line disable is more precise and self-documents at the point of the (accepted) violation, consistent with how the file already handles its other cop exceptions. (Note: `.rubocop.yml` already excludes `bin/**/*` for `Rails/Present` — that precedent is for a different cop and doesn't extend automatically to this one.)
- **Rewriting the generated binstub logic**: rejected per explicit instruction — `bin/bundle` is Bundler-managed boilerplate; a "clever" rewrite risks diverging from the upstream binstub template and being silently clobbered or made inconsistent on a future `bundle binstubs`/Bundler upgrade.

### 5. `Layout/LineLength` on `config/initializers/declare_schema.rb:22`

**Preferred fix**: wrap the interpolated log string across two lines using Ruby's implicit adjacent-string-literal concatenation, e.g.:

```ruby
Rails.logger.info "Unable to deserialize default value for column #{column.name} of type " \
                   "#{type.inspect} with default value #{default_value.inspect}: #{e.message}"
```

Pure reformat, zero behavior change, no rationale needed for an alternative — trivial to fix correctly.

### 6 & 7. `Style/OneClassPerFile` on `config/initializers/declare_schema.rb:28` and `:40`

**Preferred fix**: extend the existing trailing `rubocop:disable` comments on the same two module declarations to also cover `Style/OneClassPerFile`:
- Line 28: `module DeclareSchemaMigratorPatch # rubocop:disable Style/Documentation` → `# rubocop:disable Style/Documentation,Style/OneClassPerFile`
- Line 40: `module DeclareSchema` → append `# rubocop:disable Style/OneClassPerFile`

**Rationale**: this file's own header comment states its three top-level modules (`DeclareSchemaColumnPatch`, `DeclareSchemaMigratorPatch`, `DeclareSchema`) are intentional, cohesive monkey-patches against a single third-party gem ("patches made directly to the DeclareSchema gem... these patches should be contributed back to the gem"), grouped together on purpose so the patch surface is reviewable in one place. Splitting them into 3 separate initializer files would satisfy the cop but is exactly the kind of unrelated structural refactor this revision is meant to avoid: Rails initializers load in filename order, and the `require 'generators/declare_schema/migration/migrator'` + `prepend` wiring at the bottom of the file would need re-verification across new file boundaries for no functional benefit. Extending the file's own existing disable-comment convention (already used for `Style/Documentation` on these same lines) is the lowest-risk, most consistent fix.

### 8. `Style/IfUnlessModifier` on `config/sitemap.rb:35`

**Preferred fix**: convert the block `if`/`next`/`end` to modifier form, combined with the `noindex?` rename (offense #1/#3 companion edit):

```ruby
next if model.noindex? || !Rails.application.routes.url_helpers.respond_to?(:"#{model.name.underscore.pluralize}_path")
```

This mirrors the already-correct modifier-form call site 12 lines below it (`next if controller.noindex? || ...`), so the file becomes internally consistent as well as lint-clean.

### 9. `Rails/TimeZone` on `spec/factories/post.rb:10`

**Preferred fix**: `published_at { Time.now }` → `published_at { Time.current }`. Standard Rails-preferred timezone-aware replacement; this is a test factory default only, so there is no production behavior to regress — accept the RuboCop autocorrect.

### 10. `Rails/RootPathnameMethods` on `spec/rails_helper.rb:27`

**Preferred fix**: `Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }` → `Rails.root.glob("spec/support/**/*.rb").each { |f| require f }`. `Rails.root` is already a `Pathname`; `Pathname#glob` is the idiomatic, RuboCop-recommended replacement and returns `Pathname`s, which `require` accepts natively. Accept the RuboCop autocorrect.

### Non-goals for the Lint Unblock section

- Do not split `config/initializers/declare_schema.rb` into multiple files — see rationale under offenses #6/#7.
- Do not hand-rewrite `bin/bundle`'s generated control flow — see rationale under offense #4.
- Do not run a blanket `rubocop -A`/`--autocorrect-all` across the repo — apply the fixes above deliberately, file by file, since two of the four "correctable" offenses (bin/bundle, sitemap.rb) need the specific handling described above rather than RuboCop's default autocorrection.
- Do not touch any RuboCop cop configuration in `.rubocop.yml` beyond what's explicitly specified above (none of the 10 offenses require a `.rubocop.yml` change under the preferred strategy — all are inline code/comment fixes).
- Do not use this PR to fix any RuboCop offense not in the 10-item list above, even if `rubocop -a` or a future `rubocop` run surfaces something adjacent — new/unlisted offenses are out of scope for this revision (open a separate issue if found).

## Testing / Verification

Because the GHA-bump half of this spec is pure CI/CD infrastructure, most "testing" there means proving the workflows still execute correctly with the new pins. The Lint Unblock half adds a concrete local/CI RuboCop check.

1. **Static check (GHA pins)**: after editing, re-run the repo-wide search for the four action names to confirm every occurrence was updated and no stray old pin remains:
   - `rg 'uses:\s*"?(actions/checkout|actions/setup-node|actions/github-script|dependabot/fetch-metadata)@' .github/`
2. **RuboCop clean run (new in v2.0)**: after applying the 10 fixes in the Lint Unblock section, run `bundle exec rubocop` locally and confirm it reports `0 offenses` (down from `54 files inspected, 10 offenses detected`). Re-run the exact CI invocation used by the `lint` job (check `.github/workflows/ci.yml` for the precise command/flags) to match CI behavior exactly.
3. **CI workflow (`ci.yml`)**: push the branch and open the PR against `main`. Confirm all jobs go green:
   - `danger` job completes (Danger comment posts or job succeeds).
   - `lint` job completes — RuboCop now passes with 0 offenses (this is the specific regression this revision fixes; previously red due to pre-existing debt, unrelated to the GHA bumps).
   - `test` job completes: Node setup succeeds, `yarn install --frozen-lockfile` succeeds (validates `setup-node` + yarn caching still works), asset precompile and `rake spec` succeed — including `spec/factories/post.rb` and `spec/rails_helper.rb` after their Lint fixes, and any spec exercising `ApplicationController.noindex?`/`ApplicationRecord.noindex?` or `config/sitemap.rb` after the rename.
   - `ci-gate` job reports success (aggregates `lint` + `test`).
4. **Merge Guard (`merge-guard.yml`)**: since this workflow triggers on `workflow_run` for `CI`, confirm it fires after the PR's CI run completes and correctly posts the `merge-guard` commit status (success) — this exercises the bumped `github-script@v9` end-to-end without needing a separate manual trigger, and is the final gate this revision needs green.
5. **Resume workflow (`resume.yml`)**: this only runs on push to `main`/`master`, so it cannot be exercised directly on the PR branch. Verify by inspection that the sole `checkout` pin was bumped correctly (v4 → v7); no functional regression is expected per the compatibility notes above. Optionally, note in the PR description that this workflow will be implicitly verified on the next merge to `main`.
6. **Automerge workflow (`automerge.yml`)**: this only runs for `pull_request_target` events from `dependabot[bot]`, so it cannot be exercised by this (human-authored) PR directly. Verify by inspection that `steps.metadata.outputs.update-type` is still the correct output key for v3.1.0 (confirmed above), and that the pin was bumped correctly. This will be implicitly verified the next time a Dependabot PR opens after this change merges.
7. **Sitemap generation manual sanity check**: since `config/sitemap.rb` had both a rename (`noindex` → `noindex?`) and a modifier-`if` rewrite, run the sitemap generation task (`rake sitemap:refresh` or equivalent per `sitemap_generator` gem usage in this repo) locally/in CI if already exercised by the test suite, to confirm no `NoMethodError` and that `noindex?`-true models/controllers are still correctly excluded.
8. **Overall gate**: the PR is not ready to merge until `ci-gate` and `merge-guard` both report green on the PR's own commits.

## Security Considerations

- `actions/checkout@v7`'s new default (refusing fork PR checkout under `pull_request_target`/`workflow_run` unless `allow-unsafe-pr-checkout: true`) is a **security hardening** change upstream. This repo does not use `checkout` under either trigger today, so the bump introduces no behavior change — but it also means we must resist any future temptation to add `checkout` to `automerge.yml` (which does run under `pull_request_target`) without explicitly reviewing the "pwn request" risk described in the upstream advisory (https://gh.io/securely-using-pull_request_target). No code change is required now; this is a forward-looking guardrail for reviewers.
- All four actions move to a Node 24 action runtime. GitHub-hosted runners (`ubuntu-latest`) already support this; no runner-version pin exists in this repo that would need updating.
- Pinning to upstream major-version tags (`@v7`, `@v9`, etc.) rather than to a commit SHA is consistent with this repo's existing convention (all current pins use tags, not SHAs) and with what the Dependabot config already produces. This spec does not change that convention; SHA-pinning is out of scope.
- No new secrets, permissions, or `GITHUB_TOKEN` scopes are introduced by any of the four bumps. `merge-guard.yml`'s existing `permissions` block (`contents: read`, `statuses: write`, `pull-requests: write`, `issues: write`) and `automerge.yml`'s (`contents: write`, `pull-requests: write`) remain unchanged and sufficient.

## Acceptance Criteria

### GHA bump criteria (unchanged from v1.0)

- [ ] `actions/checkout` is `v7` in all 4 call sites (`ci.yml` ×3, `resume.yml` ×1).
- [ ] `actions/setup-node` is `v7.0.0` in `ci.yml`.
- [ ] `actions/github-script` is `v9` in `merge-guard.yml`.
- [ ] `dependabot/fetch-metadata` is `v3.1.0` in `automerge.yml`.
- [ ] No other `uses:` pin, workflow trigger, permission, or job step is modified beyond the four bumps (and any minimal compatibility fix identified during implementation per the compatibility notes above).
- [ ] No `Gemfile`, `Gemfile.lock`, `package.json`, or `yarn.lock` changes are included in this PR.
- [ ] Dependabot metadata parsing (`fetch-metadata` output `update-type`) and `github-script` consumers behave as before — verified by inspection per Testing/Verification, since neither `automerge.yml` nor `resume.yml` can be triggered directly by this PR.
- [ ] The PR description references Dependabot PRs #1096, #1144, #1149, and #1020 as superseded, and does **not** contain `Closes #1147`.
- [ ] Dependabot PRs #1096, #1144, #1149, #1020 are closed/superseded once this PR merges (Dependabot auto-closes on next scan since the versions in the base branch now match or exceed what those PRs proposed).

### RuboCop / Lint Unblock criteria (added in v2.0)

- [ ] `bundle exec rubocop` reports `0 offenses` (down from `54 files inspected, 10 offenses detected`).
- [ ] All 10 offenses listed in the RuboCop / Lint Unblock section are resolved using their specified preferred fix strategy — no offense is left unresolved and no new offense is introduced.
- [ ] `ApplicationController.noindex?` and `ApplicationRecord.noindex?` are the only public names for this predicate (old `noindex` name fully removed); both call sites in `config/sitemap.rb` (lines 35 and 47) use the `?` form.
- [ ] The 5 documentation references to `noindex` (`docs/architecture/overview.md`, `docs/architecture/sub-systems/rails-runtime.md`, `docs/architecture/sub-systems/content-domain.md`, `docs/code/patterns.md`, `docs/code/adlc-init.md`) are updated to `noindex?` for consistency.
- [ ] `bin/bundle` and `config/initializers/declare_schema.rb` carry only the specified inline `rubocop:disable` comment additions — no structural rewrite of either file.
- [ ] No RuboCop offense outside the 10-item list is introduced or "fixed" as a drive-by change.

### Overall gate criteria (updated in v2.0 — combines both halves)

- [ ] The PR's own `lint` job reports green (RuboCop 0 offenses).
- [ ] The PR's own `ci-gate` job (aggregating `danger`/`lint`/`test`) reports green.
- [ ] The PR's own `merge-guard` status check reports green, confirming `github-script@v9` behaves correctly and the overall gate is unblocked.
- [ ] This PR must **not** close epic #1147 (parent epic stays open until all its children land — unchanged from v1.0).

## Out of Scope

- Any Gem/npm application dependency upgrade (Rails, gems, JS packages) — tracked separately under epic #1147.
- The Rails major-version upgrade.
- Frontend CSS/build tooling major upgrades (e.g., Tailwind/webpack majors).
- Adding SHA-pinning for any GitHub Action (would be a separate hardening proposal).
- Adding `allow-unsafe-pr-checkout` or otherwise changing `checkout` trigger behavior.
- Modifying `.github/dependabot.yml` scheduling, grouping, or labels.
- Any RuboCop offense not in the 10-item list in the Lint Unblock section (added in v2.0).
- Splitting `config/initializers/declare_schema.rb` into multiple files, or any other unrelated refactor of files touched for Lint fixes (added in v2.0).
- Any Gemfile/npm dependency major-version bump beyond what's strictly needed to make RuboCop pass (none of the 10 offenses require a gem/cop-version bump — added in v2.0).
- Upgrading `ruby/setup-ruby`, `MeilCli/danger-action`, or `elgohr/Publish-Docker-Github-Action` (not in the Dependabot PR set named in this issue).
- Closing parent epic #1147 (must remain open; only its child issue #1155 is closed by this work).

## Implementation Handoff

The GHA-bump half remains a mechanical, low-risk version-pin change confined to `.github/workflows/`. The Lint Unblock half (v2.0) touches `app/controllers/`, `app/helpers/`, `app/models/`, `bin/`, `config/initializers/`, `config/sitemap.rb`, and `spec/` — all fixes are enumerated concretely in the Lint Unblock section with exact preferred code/comment per offense, so no additional design decisions are needed from the code agent.

- **Recommended handoff**: the **code** agent, with this spec as the sole reference for both halves.
- **Doc-sync note for the code agent**: after the `noindex` → `noindex?` rename, update the 5 documentation references listed in the RuboCop / Lint Unblock section (offense #1/#3) in the same commit/PR, so `docs/architecture/` and `docs/code/` stay accurate. This is a plain find-and-replace of the method name in prose/code-citations — it does not require scribe re-involvement or an architecture-doc structural change (no subsystem, export set, or dependency-graph change is introduced by this rename).
- **No test-code or integrator involvement is expected.** No new tests are required — the fixes are style/lint corrections to existing code, not new behavior; existing specs must continue to pass (see Testing / Verification item 3).
- **No subsystem catalog update is required** beyond the doc-sync note above — the rename doesn't move responsibilities between subsystems or add/remove an export from either `ApplicationController` or `ApplicationRecord`'s existing Public Contract, it only corrects the name's spelling.
- Do **not** implement any of this from this specification revision alone without the user's explicit re-approval — this document is a **specification revise only**, per the instructions under which it was produced.

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 2.0 | 2026-07-18 | **Scope expansion (option C).** Added the "RuboCop / Lint Unblock" section: documented all 10 pre-existing RuboCop offenses from CI run [29620475230](https://github.com/bitidev/jamesebentier.com/actions/runs/29620475230) (lint job [88014375904](https://github.com/bitidev/jamesebentier.com/actions/runs/29620475230/job/88014375904)) and specified a preferred fix strategy + rationale for each, so PR #1165 also clears `Lint`/`ci-gate`/`merge-guard` in addition to the original GHA bumps. Updated Testing/Verification, Acceptance Criteria (split into GHA / Lint Unblock / Overall-gate subsections), Out of Scope, and Implementation Handoff to reflect the expanded scope. Original v1.0 GHA-bump Overview/Inventory/Requirements/Implementation Details/Security Considerations sections are unchanged. Title and header updated to reflect PR #1165 and the expanded scope; epic #1147 must-not-close constraint carried forward unchanged. |
| 1.0 | 2026-07-18 | Initial specification (GHA workflow dependency bumps only). |
