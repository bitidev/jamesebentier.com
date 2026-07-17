<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1156 -->
<!-- Last Updated: 2026-07-18T01:20:00+02:00 -->
<!-- Description Hash: 3d92f0d9ed8e -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# Upgrade Ruby Test and Development Tooling Gems

**Issue:** [bitidev/jamesebentier.com#1156](https://github.com/bitidev/jamesebentier.com/issues/1156)
**Parent epic:** [#1147](https://github.com/bitidev/jamesebentier.com/issues/1147) — Upgrade all dependencies to latest versions (umbrella; **do not close #1147 when this lands**)
**Branch:** `personal/jebentier/issue-1156-upgrade-ruby-test-dev-tooling`
**Board:** `jamesebentier.com Board` — Status: In Progress; Assignee: `jebentier`

## Overview

Five Dependabot PRs are open against `main`, each bumping a Ruby test/dev-tooling gem by a major version:

| PR | Gem | From → To | Direct/Transitive in `Gemfile` |
|---|---|---|---|
| [#384](https://github.com/bitidev/jamesebentier.com/pull/384) | `rspec-rails` | 6.1.4 → 7.1.1 | Direct (`group :test`) |
| [#805](https://github.com/bitidev/jamesebentier.com/pull/805) | `shoulda-matchers` | 6.5.0 → 7.0.1 | Direct (`group :test`) |
| [#1146](https://github.com/bitidev/jamesebentier.com/pull/1146) | `simplecov` | 0.22.0 → 1.0.1 | Direct (`group :test`, `require: false`) |
| [#1115](https://github.com/bitidev/jamesebentier.com/pull/1115) | `rdoc` | 7.2.0 → 8.0.0 | Transitive (via `irb`, itself transitive via `railties`) |
| [#517](https://github.com/bitidev/jamesebentier.com/pull/517) | `octokit` | 9.2.0 → 10.0.0 | Transitive (via `danger`, `octokit (>= 4.0)`) |

This is a deliberate **medium**-size capacity exercise per `docs/strategic-priorities.md` (multi-gem majors, confined to the test/dev boundary) — larger and more API-sensitive than the small `#1154` patch-bump batch, but still bounded to one dependency class (Ruby test/dev tooling) with no production runtime or frontend majors in scope.

This spec covers consolidating the five bumps onto the issue's branch/PR, the config/API migration checks each major version requires, and the verification plan — closing out the "test/dev tooling" slice of the `#1147` umbrella without pulling in any of the explicitly out-of-scope runtime/Rails work.

## Goal

Upgrade the Ruby test/dev stack majors (`rspec-rails`, `shoulda-matchers`, `simplecov`, `rdoc`, `octokit`) so the test suite and its supporting tooling stay on supported, maintained versions — while keeping this PR's blast radius confined to test/dev tooling, per the issue's explicit exclusion of production runtime and Rails majors.

## In Scope

- Bump `rspec-rails` 6.1.4 → 7.1.1 (`Gemfile.lock`; unpinned in `Gemfile`)
- Bump `shoulda-matchers` 6.5.0 → 7.0.1 (`Gemfile.lock`; unpinned in `Gemfile`)
- Bump `simplecov` 0.22.0 → 1.0.1 (`Gemfile.lock`; unpinned in `Gemfile`) — including the transitive removal of `docile`, `simplecov-html`, and `simplecov_json_formatter` as separate locked gems (merged into `simplecov` 1.x itself, confirmed in [Current State](#current-state-verified))
- Bump `rdoc` 7.2.0 → 8.0.0 (`Gemfile.lock` only — not a direct `Gemfile` dependency)
- Bump `octokit` 9.2.0 → 10.0.0 (`Gemfile.lock` only — not a direct `Gemfile` dependency; see [Current State](#current-state-verified) for why this one is effectively already satisfied)
- Any config/initializer updates the new major versions require (see [Requirements](#requirements) R3–R5) — and documenting them in the PR per the issue's acceptance criteria
- Consolidating all five onto the single branch/PR named above
- Closing or superseding PRs #384, #805, #1146, #1115, #517 once the consolidated PR merges (orchestrator-owned GitHub operation, see [Delegation](#delegation--handoff))
- Running the full local test suite and RuboCop to confirm no regressions from the bump itself

## Out of Scope

Per the issue body, explicitly excluded from this batch (remain open work under `#1147`):

- Safe patch-only gem/npm bumps (separate batch — see `#1154`, already speced/landed as its own issue)
- Production runtime gem majors: `puma`, `declare_schema`, `sitemap_generator`
- Frontend CSS/build majors (Tailwind, DaisyUI, `webpack-cli`, etc.)
- Rails major upgrade (`rails` stays pinned `~> 7.1.3, >= 7.1.3.4`; nothing in this batch requires moving it — see [Current State](#current-state-verified))
- Fixing the pre-existing RuboCop lint debt on `main`, unrelated to these five gems (see [Finding: Pre-Existing Lint Failure](#finding-pre-existing-lint-failure-on-main-still-present) — carried over from `#1154`, flagged again as an open question rather than silently absorbed into this PR)

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch `jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against the repo (worktree branched from `main` tip `5407bd1`) and GitHub as of 2026-07-18:

- **`Gemfile.lock` shows four of the five gems still at their pre-upgrade ("From") version**: `rspec-rails (6.1.4)`, `shoulda-matchers (6.5.0)`, `simplecov (0.22.0)`, `rdoc (7.2.0)` — confirmed by direct inspection of `Gemfile.lock`.
- **`octokit` is already at `10.0.0` in `Gemfile.lock` today, despite PR #517 (open, unmerged) being the one that nominally bumps it.** `octokit` is not a direct `Gemfile` dependency — it is pulled in transitively by `danger (9.6.0)`, whose own dependency is the unconstrained `octokit (>= 4.0)`. Git history (`git log -S"octokit (10.0.0)" -- Gemfile.lock`) shows the lockfile's `octokit` entry moved from `9.2.0` to `10.0.0` in commit `642444e` ("Bump danger from 9.5.1 to 9.5.2 (#612)") — an unrelated `danger` patch bump whose dependency resolution happened to pull the newest `octokit` satisfying `>= 4.0`. **`gh pr diff 517` confirms its entire diff is the single `Gemfile.lock` line `octokit (9.2.0)` → `octokit (10.0.0)`, which is already the current state on this branch.** This bump requires no `bundle update` work — PR #517 is functionally a no-op against the current lockfile and can be closed as superseded without any code change.
- **Each Dependabot PR's diff is minimal and lockfile-only**, confirmed via `gh pr diff`:
  - #384 (`rspec-rails`): touches only `rspec-rails`, `rspec-core` (3.13.2 → 3.13.3, a transitive patch), and `rdoc` (6.11.0 → 6.12.0 in *that* PR's base — since superseded by #1115's later rdoc bump; the version this repo's current `main` is actually on is `7.2.0`, not what #384's diff shows, because #384 has gone stale against newer `main` commits). No app code touched.
  - #805 (`shoulda-matchers`): touches only the `shoulda-matchers (6.5.0)` → `(7.0.1)` line and its `activesupport` constraint (`>= 5.2.0` → `>= 7.1`). No app code touched.
  - #1146 (`simplecov`): touches `simplecov (0.22.0)` → `(1.0.1)` and removes `docile`, `simplecov-html`, `simplecov_json_formatter` as separate lockfile entries (merged into the main gem in 1.x). No app code touched.
  - #1115 (`rdoc`): touches `rdoc (7.2.0)` → `(8.0.0)`, adds a new transitive gem `rbs (4.0.3)` (rdoc 8's new dependency for RBS-signature support), and removes `psych`/`stringio` as separate top-level lockfile entries (no longer needed once `rdoc` drops its `psych` dependency in 8.x). No app code touched. The new `rbs` transitive addition is flagged in [Open Questions](#open-questions) for reviewer awareness, since it's a net-new gem in the dependency tree even though it ships only as a doc-tooling transitive dependency.
  - #517 (`octokit`): see above — already satisfied on current `main`/this branch.
  - **Stale-PR caveat:** because Dependabot PRs #384, #805, #1146, #1115 were opened against earlier points on `main` and `main` has moved on since (per #1154's precedent and #517's evidence above), their diffs shown by `gh pr diff` reflect an older base and will not apply cleanly. This PR does **not** merge those branches directly — it re-runs `bundle update <gem> --conservative` for each gem against the current `main` tip (see [Approach](#approach-implementation-guidance)) and confirms the resulting lockfile state matches each gem's target version.
- **Ruby version compatibility**: `.ruby-version` pins `3.3.1`; `simplecov` 1.0.1 raises its minimum to Ruby `>= 3.2` (dropped 3.1/JRuby 9.4 support) — already satisfied. No other gem in this batch raises a Ruby floor above what's already in use.
- **Rails version compatibility**: `Gemfile` pins `rails "~> 7.1.3", ">= 7.1.3.4"` (locked at `7.1.6`). `rspec-rails` 7.x supports Rails 7.0/7.1/7.2 with **no required changes** for those versions (per rspec-rails' own upgrade notes). `shoulda-matchers` 7.x **drops support for Rails 6.1 and older, and Rails 7.0** — raising its `activesupport` constraint to `>= 7.1`, which this repo's Rails 7.1.6 already satisfies. Neither gem's major bump requires a Rails version change here.

### Finding: `SimpleCov` is a declared dependency but is never actually invoked

**This is the most important finding in this spec and directly affects the "coverage / simplecov config still works" acceptance criterion.**

Searched the full worktree (`spec/`, `Rakefile`, `.rspec`, and repo root) for `SimpleCov`/`simplecov` usage: the string appears only in `Gemfile`, `Gemfile.lock`, and an unrelated blog post markdown file. **There is no `SimpleCov.start` call anywhere** (not in `spec/spec_helper.rb`, not in `spec/rails_helper.rb`), **no `.simplecov` config file**, and no `coverage/` entry in `.gitignore`. `simplecov` is declared in the `Gemfile`'s `group :test` (`gem "simplecov", require: false`) but is dead weight today — the gem loads, but nothing in the suite ever calls `SimpleCov.start`, so no coverage report is generated by a normal `bundle exec rake spec` run.

Consequences for this issue's acceptance criteria, as written ("Coverage / simplecov config still works — no silent coverage regression from the 1.x jump"):

- There is no active SimpleCov configuration today, so there is nothing in the *legacy* config API (`add_filter`, `add_group`, `track_files`, `enable_coverage_for_eval` — all deprecated in 1.x in favor of `skip`, `group`, `cover`, `enable_coverage :eval`) that this bump could break, because none of those legacy calls exist in this codebase.
- The literal risk of "silent coverage regression" is moot in the sense that there is no coverage signal today to regress *from*. But it also means the criterion, if read as "confirm coverage still works," cannot be satisfied by *inspection alone* — there's no config to inspect. It can only be satisfied by either (a) confirming the gem still loads/resolves cleanly at 1.0.1 with zero config (the literal current state), or (b) this PR being the point where a minimal `SimpleCov.start` is actually wired up, using the 1.x-idiomatic API, so the criterion has something concrete to verify against going forward.
- This spec does **not** unilaterally decide between (a) and (b) — see [Open Questions](#open-questions) Q1. It documents the finding so the code agent and reviewer aren't surprised by an "acceptance criterion" that has no corresponding current behavior to preserve.

### Finding: Pre-Existing Lint Failure on `main` (still present)

Carried over from `#1154`'s spec — re-verified independently for this issue since it affects the same "CI green" acceptance criterion. Running `bundle exec rubocop` against the current worktree (branched from `main` tip `5407bd1`) reproduces the same **10 pre-existing offenses (4 auto-correctable)**, in files unrelated to any of this issue's five gems:

- `app/controllers/application_controller.rb:6` — `Naming/PredicateMethod`
- `app/helpers/welcome_helper.rb:3` — `Style/Documentation`
- `app/models/application_record.rb:8` — `Naming/PredicateMethod`
- `bin/bundle:95` — `Style/IfUnlessModifier` (autocorrectable)
- `config/initializers/declare_schema.rb:22` — `Layout/LineLength`
- `config/initializers/declare_schema.rb:28`, `:40` — `Style/OneClassPerFile` (×2)
- `config/sitemap.rb:35` — `Style/IfUnlessModifier` (autocorrectable)
- `spec/factories/post.rb:10` — `Rails/TimeZone` (autocorrectable)
- `spec/rails_helper.rb:27` — `Rails/RootPathnameMethods` (autocorrectable)

The repo's `lint` CI job (`.github/workflows/ci.yml`) still runs `bundle exec rubocop` unscoped, so it still fails on any offense anywhere in the tree — not just offenses this PR introduces. This is the same underlying issue `#1154` documented; it has not been resolved by any commit since. **This PR should not silently absorb a fix for these 10 unrelated offenses** (that would violate "no unrelated changes" as much as it would for `#1154`), so the same handling question applies here — see [Open Questions](#open-questions) Q2.

## Requirements

1. **R1 — Dependency bumps land on `main`.** `rspec-rails` reaches `7.1.1`, `shoulda-matchers` reaches `7.0.1`, `simplecov` reaches `1.0.1`, and `rdoc` reaches `8.0.0` in `Gemfile.lock`, via one consolidated PR from this issue's branch. `octokit` remains at (or above) `10.0.0` — already satisfied on current `main`, confirmed by re-running `bundle lock` and diffing against [Current State](#current-state-verified) rather than assumed unchanged.
2. **R2 — No scope creep.** The consolidated PR's diff touches only `Gemfile.lock` (the five gems' version lines and their necessarily-changed transitive dependencies — e.g. `rspec-core`'s patch bump, `rbs`'s addition, `docile`/`simplecov-html`/`simplecov_json_formatter`/`psych`/`stringio`'s removal, all as directly caused by the four real version bumps) plus whatever config files R3–R5 require. No production runtime gem (`puma`, `declare_schema`, `sitemap_generator`) or `rails` itself changes version. No frontend/npm files touched.
3. **R3 — `rspec-rails` 7.x migration check.** Confirm the suite boots and runs cleanly under `rspec-rails` 7.1.1 with the existing `spec/rails_helper.rb` and `spec/spec_helper.rb` unchanged (per [Current State](#current-state-verified), no config changes are required for Rails 7.1). If any deprecation warnings or failures surface that are specific to `rspec-rails` 7, document and resolve them in this PR and call them out explicitly in the PR description (per the issue's "documented in the PR" acceptance criterion) — do not silently patch without noting it.
4. **R4 — `shoulda-matchers` 7.x migration check.** Confirm `spec/support/shoulda_matchers.rb`'s existing `Shoulda::Matchers.configure` block (`with.test_framework :rspec`, `with.library :rails`) is still valid under 7.0.1 — the configuration API itself is unchanged in 7.x; only the supported-Rails floor moved (see [Current State](#current-state-verified)). Run the full suite and confirm shoulda matcher usages (validation/association matchers, etc.) still pass with no matcher-behavior changes needed.
5. **R5 — `simplecov` 1.x migration decision.** Per the [`SimpleCov` finding](#finding-simplecov-is-a-declared-dependency-but-is-never-actually-invoked), resolve Open Question Q1 (with the user/orchestrator, not unilaterally) before implementation, then either: (a) confirm and document that no config exists to migrate and the gem simply resolves at 1.0.1 with zero behavior change, or (b) add a minimal `SimpleCov.start` (in `spec/spec_helper.rb`, before `RSpec.configure`, using the 1.x `cover`/`skip`/`group` idioms — not the deprecated `add_filter`/`add_group`/`track_files` — per the migration table in [Current State](#current-state-verified)) and confirm a coverage report is generated by `bundle exec rake spec`. Whichever path is chosen must be documented in the PR per the issue's acceptance criteria.
6. **R6 — `rdoc` / `octokit` transitive bumps land cleanly.** Since neither is a direct `Gemfile` dependency, confirm via `bundle update rdoc octokit --conservative` (or equivalent) that the resulting `Gemfile.lock` diff matches [Current State](#current-state-verified) — i.e., only `rdoc`'s and its dependents' lines move (with the `rbs` addition and `psych`/`stringio` removal), and `octokit` is confirmed unchanged (already at 10.0.0). No RDoc CLI invocation exists in this repo's Rake tasks, so no RDoc-specific breaking-change (Prism parser default, removed CLI flags) applies here.
7. **R7 — CI outcome is explicit, not assumed.** Given the [pre-existing lint finding](#finding-pre-existing-lint-failure-on-main-still-present), the PR must either (a) show a genuinely green `ci-gate` (pre-existing offenses resolved as a clearly-labeled, separately-reviewable part of this PR, if that's the path selected), or (b) the merge decision is made with an explicit, documented acknowledgment that `ci-gate`/`lint` fails for pre-existing, unrelated reasons and that `test` (the job that actually exercises the five bumped gems) is green. Silently merging a red `ci-gate` without this acknowledgment does not satisfy the acceptance criteria as written.
8. **R8 — Dependabot PRs consolidated.** Once the consolidated PR merges, #384, #805, #1146, #1115, and #517 are closed as superseded (orchestrator-owned; see [Delegation](#delegation--handoff)). #1147 remains open.

## Approach (Implementation Guidance)

This section is spec-level guidance for the **code** agent / implementer — not a substitute for their own verification.

1. Confirm working in the issue worktree (`personal/jebentier/issue-1156-upgrade-ruby-test-dev-tooling`), branched from current `main`.
2. Resolve [Open Questions](#open-questions) Q1 (SimpleCov config scope) and Q2 (lint-debt handling) with the user/orchestrator before proceeding past step 3 — both materially change what "done" looks like for this PR.
3. Run the bumps against current `main`, not by merging the stale Dependabot branches (see the stale-PR caveat in [Current State](#current-state-verified)):
   - `bundle update rspec-rails shoulda-matchers simplecov rdoc octokit --conservative` (conservative avoids pulling unrelated transitive majors beyond what's already verified above).
   - Diff `Gemfile.lock` and confirm: `rspec-rails` → `7.1.1`, `shoulda-matchers` → `7.0.1`, `simplecov` → `1.0.1` (with `docile`/`simplecov-html`/`simplecov_json_formatter` removed as separate entries), `rdoc` → `8.0.0` (with `rbs` added, `psych`/`stringio` removed if nothing else depends on them), `octokit` unchanged at `10.0.0`. No other gem — especially `puma`, `declare_schema`, `sitemap_generator`, `rails` — should move.
4. Apply the R3–R5 migration checks: run the suite, watch for `rspec-rails`/`shoulda-matchers` deprecation warnings, and implement the R5 SimpleCov decision from step 2.
5. Run `bundle exec rake spec` and `bundle exec rubocop` for before/after parity. RuboCop is expected to still report the same 10 pre-existing offenses (see [lint finding](#finding-pre-existing-lint-failure-on-main-still-present)) — the count should not increase from this PR's own changes. If it decreases or changes shape unexpectedly, investigate before proceeding.
6. Open the consolidated PR against `main` from the issue branch. In the PR description: reference all five superseded Dependabot PRs (`Supersedes #384, #805, #1146, #1115, #517`) and this issue (`Closes #1156`); explicitly document the R5 SimpleCov decision and any R3/R4 migration notes; explicitly note the pre-existing-lint-CI caveat from R7 so reviewers aren't surprised by a red `lint`/`ci-gate` check if that path is chosen.
7. Once merged, hand off to the orchestrator for GitHub Issues lifecycle operations (closing #384, #805, #1146, #1115, #517 as superseded, closing #1156, leaving #1147 open) — the scribe/code agents do not perform these operations directly.

## Acceptance Criteria

Mapped from the issue body, sharpened with this spec's findings:

- [ ] `rspec-rails` reaches `7.1.1`, `shoulda-matchers` reaches `7.0.1`, `simplecov` reaches `1.0.1`, `rdoc` reaches `8.0.0` in `Gemfile.lock`; `octokit` confirmed at (or above) `10.0.0` — via one consolidated PR
- [ ] The consolidated PR's diff is limited to `Gemfile.lock` and whatever config file(s) the R5 SimpleCov decision requires — no production runtime gem (`puma`, `declare_schema`, `sitemap_generator`) or `rails` version changes, no frontend/npm files touched
- [ ] Full local test suite (`bundle exec rake spec`) is green after the bump
- [ ] The `test` CI job is green on the consolidated PR
- [ ] The `ci-gate`/`lint` outcome is explicitly resolved per R7 — either genuinely green or knowingly and explicitly waived with the pre-existing-failure rationale documented in the PR — not silently ignored
- [ ] The R5 SimpleCov decision (config-still-works-as-is vs. minimal `SimpleCov.start` added) is made, implemented, and documented in the PR
- [ ] Any `rspec-rails`/`shoulda-matchers` API or config updates surfaced by R3/R4 are included and documented in the PR (or explicitly noted as "none required" if the suite passes unchanged)
- [ ] No production runtime gem majors (`puma`, `declare_schema`, `sitemap_generator`, `rails`) present in this PR's diff
- [ ] #384, #805, #1146, #1115, #517 are closed/superseded once the consolidated PR merges; #1147 remains open

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns) and the scribe's own delegation rules:

- **Implementation** (running `bundle update`, resolving the R5 SimpleCov config decision, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (closing #384/#805/#1146/#1115/#517 as superseded, transitioning #1156, leaving #1147 open, board status): delegate to the **orchestrator** — this spec does not perform those operations. See [delegating-github-issues-to-orchestrator.md](../../adlc/methods/universal/delegating-github-issues-to-orchestrator.md).
- **The Q1/SimpleCov-scope and Q2/lint-debt judgment calls**: decisions for the orchestrator/user, not the scribe — see [Open Questions](#open-questions).

## Open Questions

1. **Does this PR need to add a minimal, working `SimpleCov.start` (Q1)?** Per the [SimpleCov finding](#finding-simplecov-is-a-declared-dependency-but-is-never-actually-invoked), the gem is declared but never invoked today — there's no existing coverage config to "keep working." Options:
   - (a) Treat the acceptance criterion literally-narrowly: confirm `simplecov` 1.0.1 resolves and loads cleanly with zero config (the current, inert state), and document that there was no active config to migrate. Minimal-diff, matches "no unrelated changes" most literally.
   - (b) Treat the acceptance criterion as intent-revealing (a test/dev-tooling issue implicitly assuming coverage is/should be tracked) and use this PR to wire up a minimal `SimpleCov.start` with the 1.x API (`cover`, `skip`, `group` — not the deprecated `add_filter`/`add_group`/`track_files`), giving the criterion something concrete to verify going forward.
   - This spec defaults to recommending (a) for this PR (narrowest scope, consistent with `#1154`'s "no unrelated changes" precedent) and suggests (b) as a candidate for a **separate**, explicitly-scoped follow-up issue if coverage tracking is actually wanted — but does not decide this unilaterally; confirm with the user/orchestrator before the code agent starts.
2. **How should the pre-existing 10-offense RuboCop/`lint` CI failure on `main` be handled for this PR's "CI green" criterion (Q2)?** Same three options `#1154` raised, still unresolved on `main`:
   - (a) Fix the 10 offenses (4 auto-correctable, 6 manual) as a clearly-separated, reviewable part of this PR.
   - (b) Merge with `ci-gate`/`lint` red and an explicit note that it's pre-existing and unrelated, treating `test` as the operative green signal.
   - (c) Fix the `lint` job definition itself (scope it to changed files, mirroring `Dangerfile`'s `only_report_new_offenses`) — a CI/tooling change, likely belongs to its own issue rather than either `#1154` or this one.
   - This spec again recommends (b) as the minimal-scope default, consistent with `#1154`'s recommendation, but surfaces (a) and (c) for the user/orchestrator to choose from explicitly. If the user resolved this already for `#1154`, apply the same resolution here for consistency rather than re-litigating it.
3. **Is the new transitive `rbs (4.0.3)` gem (pulled in by `rdoc` 8.0.0) acceptable as a net-new dependency-tree addition**, even though it's purely a doc-tooling transitive and not a direct or production dependency? Recommended: yes, no action needed, but flagged so the reviewer isn't surprised by a new gem name appearing in the `Gemfile.lock` diff that isn't one of the five named gems.
4. **Does "consolidate onto one working branch if needed" permit landing these five bumps as separate PRs instead of one**, if that turns out easier operationally (e.g., if the R5 SimpleCov decision turns out to need more back-and-forth than the other four)? This spec assumes one consolidated PR per the issue's primary framing and per this branch already being provisioned as a single worktree; confirm with the user/orchestrator if a different shape is preferred.

## Changelog

### Version 1 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1156
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification created for consolidating Dependabot PRs #384 (rspec-rails), #805 (shoulda-matchers), #1146 (simplecov), #1115 (rdoc), #517 (octokit) into one Ruby test/dev-tooling major-bump PR
- Verified current `Gemfile.lock` state against each PR's diff; discovered `octokit` is already at its target version `10.0.0` on `main` (pulled in transitively by an unrelated `danger` bump), making PR #517 a no-op to close as superseded rather than a bump to perform
- Documented that `simplecov` is a declared but never-invoked dependency (no `SimpleCov.start` anywhere in the codebase), which changes what "coverage config still works" can mean for this PR's acceptance criteria, and raised the config-scope decision as an open question rather than resolving it unilaterally
- Documented required migration checks for `rspec-rails` 7.x (no changes needed for Rails 7.1) and `shoulda-matchers` 7.x (drops Rails 6.1/7.0 support; this repo's Rails 7.1.6 already satisfies the new floor)
- Re-confirmed the same pre-existing, unrelated RuboCop `lint` CI failure on `main` first documented in `#1154`'s spec, still present and unresolved, and carried forward the same open question about how to handle it for this PR's "CI green" criterion

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the code agent.

---
