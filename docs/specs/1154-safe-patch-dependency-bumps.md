<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1154 -->
<!-- Last Updated: 2026-07-18T01:10:00+02:00 -->
<!-- Description Hash: 513d7abf3d15 -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# Apply Safe Gem and npm Patch Dependency Bumps

**Issue:** [bitidev/jamesebentier.com#1154](https://github.com/bitidev/jamesebentier.com/issues/1154)
**Parent epic:** [#1147](https://github.com/bitidev/jamesebentier.com/issues/1147) — Upgrade all dependencies to latest versions (umbrella; **do not close #1147 when this lands**)
**Branch:** `personal/jebentier/issue-1154-safe-patch-dependency-bumps`
**Board:** org `bitidev` project #2 — Status: In Progress; Assignee: `jebentier`

## Overview

Three Dependabot patch-level PRs are open against `main`, each bumping a single dependency by one patch version with no transitive major/minor movement on any direct dependency:

| PR | Dependency | Ecosystem | From → To | Nature |
|---|---|---|---|---|
| [#1150](https://github.com/bitidev/jamesebentier.com/pull/1150) | `loofah` | Bundler | 2.25.1 → 2.25.2 | Security patch (HTML sanitizer URI-scheme bypass fixes) |
| [#1151](https://github.com/bitidev/jamesebentier.com/pull/1151) | `parser` | Bundler | 3.3.11.1 → 3.3.12.0 | Routine patch (transitive dev dependency of RuboCop) |
| [#1152](https://github.com/bitidev/jamesebentier.com/pull/1152) | `autoprefixer` | npm/yarn | 10.5.3 → 10.5.4 | Routine patch (pulls `caniuse-lite` 1.0.30001805 → 1.0.30001806 as its only transitive change) |

This spec covers consolidating these three onto one branch/PR so they land together, closing out the lowest-risk slice of the #1147 dependency-upgrade umbrella without pulling in any of the explicitly out-of-scope major/minor work.

## Goal

Land the lowest-risk open Dependabot patch bumps so the tree stays current without multi-major blast radius. This is deliberately a **small, crisp** ADLC exercise (see `docs/strategic-priorities.md` — deliberate size variation across issues), not a vehicle for broader dependency cleanup.

## In Scope

- Bump `loofah` 2.25.1 → 2.25.2 (Bundler / `Gemfile.lock`)
- Bump `parser` 3.3.11.1 → 3.3.12.0 (Bundler / `Gemfile.lock`)
- Bump `autoprefixer` 10.5.3 → 10.5.4 (npm/yarn / `package.json`, `yarn.lock`, `.yarn/install-state.gz`)
- Consolidating the three changes onto the single branch/PR named above
- Closing or superseding PRs #1150, #1151, #1152 once the consolidated PR merges (orchestrator-owned GitHub operation, see [Delegation](#delegation--handoff))
- Smoke-checking that the site still boots and key pages render after the bump

## Out of Scope

Per the issue body, explicitly excluded from this batch (these remain open work under #1147):

- GitHub Actions version bumps (majors)
- Ruby test/dev tooling majors
- Runtime/app gem majors: `puma`, `declare_schema`, `sitemap_generator`
- Frontend CSS/build majors: Tailwind, DaisyUI, `webpack-cli`
- Rails major upgrade
- Fixing pre-existing RuboCop lint debt unrelated to these three dependencies (see [Finding: Pre-Existing Lint Failure](#finding-pre-existing-lint-failure-on-main) — flagged as an open question, not silently absorbed into this PR)

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch `jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against the repo and its GitHub Actions history as of 2026-07-18:

- **Lockfile constraints are compatible with each bump in isolation** — `Gemfile.lock` shows `rails-html-sanitizer (~> 2.25)` as the only constraint on `loofah` (2.25.2 satisfies it) and `rubocop-ast (>= 1.49.0, < 2.0)` families require `parser (>= 3.3.0.2)` / `(>= 3.3.7.2)` (3.3.12.0 satisfies both). No other gem pins either dependency more tightly.
- **Each Dependabot PR's diff is already minimal and isolated** — confirmed via `gh pr diff`:
  - #1150: one line changed in `Gemfile.lock` (`loofah (2.25.1)` → `loofah (2.25.2)`)
  - #1151: one line changed in `Gemfile.lock` (`parser (3.3.11.1)` → `parser (3.3.12.0)`)
  - #1152: `package.json` caret bump, `yarn.lock` version/checksum update for `autoprefixer`, plus the transitive `caniuse-lite` patch bump (1.0.30001805 → 1.0.30001806) it pulls in, and the yarn `install-state.gz` cache artifact. No other package versions move.
- **Each PR's "Test" CI job already passed independently** — `gh pr view --json statusCheckRollup` for all three shows `Test: SUCCESS`.
- **`loofah` 2.25.2 is a security release** (GHSA-5qhf-9phg-95m2, GHSA-8whx-365g-h9vv, GHSA-9wjq-cp2p-hrgf — URI-scheme sanitizer bypasses in `Loofah::HTML5::Scrub.allowed_uri?`), reinforcing this as genuinely low-risk and worth landing promptly.

### Finding: Pre-Existing Lint Failure on Main

**This is the most important finding in this spec and directly affects the "CI is green" acceptance criterion.**

The repo's `lint` CI job (`.github/workflows/ci.yml`) runs `bundle exec rubocop` unscoped — i.e. it fails on **any** RuboCop offense anywhere in the tracked tree, not just offenses introduced by the current diff. (This is different from the `Danger` job, which uses `rubocop.lint({ only_report_new_offenses: true })` and correctly scopes to new offenses only — see `Dangerfile`.)

Running `bundle exec rubocop` against the current `main` tip (commit `5407bd1`) locally reproduces **10 pre-existing offenses (4 auto-correctable)** across files completely unrelated to `loofah`, `parser`, or `autoprefixer`:

- `app/controllers/application_controller.rb:6` — `Naming/PredicateMethod`
- `app/helpers/welcome_helper.rb:3` — `Style/Documentation`
- `app/models/application_record.rb:8` — `Naming/PredicateMethod`
- `bin/bundle:95` — `Style/IfUnlessModifier` (autocorrectable)
- `config/initializers/declare_schema.rb:22` — `Layout/LineLength`
- `config/initializers/declare_schema.rb:28`, `:40` — `Style/OneClassPerFile` (×2)
- `config/sitemap.rb:35` — `Style/IfUnlessModifier` (autocorrectable)
- `spec/factories/post.rb:10` — `Rails/TimeZone` (autocorrectable)
- `spec/rails_helper.rb:27` — `Rails/RootPathnameMethods` (autocorrectable)

Confirmed independently three ways:
1. Local `bundle exec rubocop` on the current worktree (branched from `main` tip) reproduces exactly these 10 offenses.
2. The most recent `push`-triggered CI run on `main` itself (`run 29456846596`, 2026-07-15) is `failure` — the `lint` job is red on `main` today, before any of this issue's changes.
3. All three Dependabot PRs — including #1150, which touches only `Gemfile.lock` — show `Lint: FAILURE` and consequently `ci-gate: FAILURE` and `merge-guard: FAILURE` in their status-check rollups, even though none of them touch Ruby source.

**Separately**, the `Danger` job fails on PRs #1151 and #1152 (but not #1150) with an unrelated Octokit/Faraday exception while fetching PR metadata from the GitHub API. The job log shows `Secret source: Dependabot` for these runs; Dependabot-authored PRs execute under a restricted token/secret context that appears to break Danger's `fetch_details` API call. This is an infra quirk of how GitHub runs Dependabot-triggered workflows, not a code defect — and it does not apply to PRs opened from a normal branch/token context (which is how this issue's consolidated PR will be opened), so it is not expected to recur here. Flagged for completeness, not as a blocker.

**Why this matters for this issue:** the acceptance criteria state "CI is green on the resulting PR." As written today, `ci-gate` cannot go green on *any* PR — including one containing only these three patch bumps — without either (a) also fixing the 10 pre-existing offenses, which would violate "no unrelated major/minor upgrades... in the same PR" (arguably not major/minor version upgrades, but still unrelated code changes to files this issue has no reason to touch), or (b) the CI definition of "green" being scoped down for this PR to the checks the PR realistically controls. See [Open Questions](#open-questions) — this is called out explicitly rather than resolved unilaterally, since choosing between "fix pre-existing lint debt in this PR" and "redefine green for this PR" is a judgment call outside spec-writing.

## Requirements

1. **R1 — Dependency bumps land on `main`.** `loofah` reaches `>= 2.25.2`, `parser` reaches `>= 3.3.12.0`, and `autoprefixer` reaches `>= 10.5.4` in the corresponding lockfiles (`Gemfile.lock`, `yarn.lock`) via one consolidated PR from this issue's branch, or via the equivalent lockfile state if achieved some other way (e.g. individually re-running `bundle update <gem> --conservative` / `yarn up autoprefixer` and confirming the resulting diff matches what's described in [Current State](#current-state-verified)).
2. **R2 — No scope creep.** The consolidated PR's diff touches only: `Gemfile.lock` (loofah, parser lines), `package.json` (autoprefixer line), `yarn.lock` (autoprefixer + its `caniuse-lite` transitive bump), and `.yarn/install-state.gz` (yarn's own cache artifact from running `yarn install`/`yarn up`). No other dependency version should move. No application code changes.
3. **R3 — CI outcome is explicit, not assumed.** Given the [pre-existing lint finding](#finding-pre-existing-lint-failure-on-main), the PR must either (a) show a genuinely green `ci-gate`, which requires resolving the `lint` job's pre-existing offenses as a clearly-labeled, separately-reviewable concern within the same PR (if that's the path the orchestrator/user selects), or (b) the merge decision is made with an explicit, documented acknowledgment that `ci-gate`/`lint` fails for pre-existing, unrelated reasons and that the `test` job (the check that actually exercises the bumped dependencies) is green. Silently merging a red `ci-gate` without this acknowledgment does not satisfy the acceptance criteria as written.
4. **R4 — Manual smoke check performed and recorded.** After the bump, with the app booted locally (or in a preview/staging context if available), confirm each of these renders without a 500/exception:
   - Home (`/`, `welcome#index`)
   - A blog post (`/blog`, then any `/blog/:slug`, `blog#index` / `blog#show`)
   - Projects (`/projects`, then any `/projects/:slug`, `projects#index` / `projects#show`) — present in this app
   - Resume (`/resume`, `welcome#resume`) — present in this app
5. **R5 — Dependabot PRs consolidated.** Once the consolidated PR merges, #1150, #1151, and #1152 are closed as superseded (orchestrator-owned; see [Delegation](#delegation--handoff)). #1147 remains open.

## Approach (Implementation Guidance)

This section is spec-level guidance for the **code** agent / implementer — not a substitute for their own verification.

1. Confirm working in the issue worktree (`personal/jebentier/issue-1154-safe-patch-dependency-bumps`), branched from current `main`.
2. Bundler side: `bundle update loofah parser --conservative` (conservative avoids pulling unrelated transitive bumps beyond what's already verified in [Current State](#current-state-verified)). Diff `Gemfile.lock` and confirm it matches the two single-line version changes described above — no other gem should move.
3. Yarn side: bump the `autoprefixer` caret in `package.json` to `^10.5.4` and run `yarn install` (or `yarn up autoprefixer`). Diff `yarn.lock` and `.yarn/install-state.gz` and confirm the only version changes are `autoprefixer` and its `caniuse-lite` transitive dependency, matching [Current State](#current-state-verified).
4. Run the local test suite and RuboCop to establish before/after parity: `bundle exec rake spec` and `bundle exec rubocop`. RuboCop is expected to still report the same 10 pre-existing offenses (see finding above) — the count should not increase. If it decreases or changes shape unexpectedly, investigate before proceeding.
5. Perform the R4 manual smoke check locally (`bin/rails server` or `bin/dev`, then visit each key page).
6. Open the consolidated PR against `main` from the issue branch. In the PR description, reference all three superseded Dependabot PRs (`Supersedes #1150, #1151, #1152`) and this issue (`Closes #1154`), and explicitly note the pre-existing-lint-CI caveat from this spec so reviewers aren't surprised by a red `lint`/`ci-gate` check if that path is chosen.
7. Once merged, hand off to the orchestrator for GitHub Issues lifecycle operations (closing #1150–#1152 as superseded, closing #1154, leaving #1147 open) — the scribe/code agents do not perform these operations directly.

## Acceptance Criteria

- [ ] `loofah`, `parser`, and `autoprefixer` are bumped to (or beyond) their target patch versions on `main`, via one consolidated PR (or equivalent lockfile state)
- [ ] The consolidated PR's diff is limited to `Gemfile.lock`, `package.json`, `yarn.lock`, and `.yarn/install-state.gz`, with no other dependency's version changed and no application code touched
- [ ] The `test` CI job is green on the consolidated PR
- [ ] The `ci-gate`/`lint` outcome is explicitly resolved per R3 — either genuinely green (pre-existing offenses addressed as a labeled, reviewable part of the change) or knowingly and explicitly waived with the pre-existing-failure rationale documented in the PR — not silently ignored
- [ ] Manual smoke check of home, a blog post, projects, and resume pages is performed and confirmed exception-free after the bump
- [ ] #1150, #1151, #1152 are closed/superseded once the consolidated PR merges; #1147 remains open

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns) and the scribe's own delegation rules:

- **Implementation** (running `bundle update`, `yarn up`, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (closing #1150–#1152 as superseded, transitioning #1154, leaving #1147 open, board status): delegate to the **orchestrator** — this spec does not perform those operations. See [delegating-github-issues-to-orchestrator.md](../../adlc/methods/universal/delegating-github-issues-to-orchestrator.md).
- **The R3/lint-debt judgment call** (fix pre-existing offenses in-PR vs. explicitly waive `ci-gate`): a decision for the orchestrator/user, not the scribe — see [Open Questions](#open-questions).

## Open Questions

1. **How should the pre-existing 10-offense RuboCop/`lint` CI failure on `main` be handled for this PR's "CI green" acceptance criterion?** Options observed, not decided here:
   - (a) Include the fix (4 offenses are auto-correctable via `rubocop -A`; the remaining 6 need manual touch-ups) as a clearly separated, reviewable part of this PR, accepting that it technically touches files outside the three dependencies — arguably still "no unrelated **major/minor upgrades**" since no dependency version is affected, but it is unrelated code.
   - (b) Merge with `ci-gate`/`lint` red and an explicit note that it's pre-existing and unrelated, treating `test` as the operative green signal for this change.
   - (c) Fix the `lint` job definition itself (e.g. scope it to changed files, mirroring `Dangerfile`'s `only_report_new_offenses`) — this is a CI/tooling change, likely out of scope for a "small, crisp" issue and arguably belongs to a separate CI-hygiene issue under or alongside #1147.
   - This spec recommends flagging (b) as the minimal-scope default (matches "no unrelated changes" most literally) but surfacing (a) and (c) to the user/orchestrator before the PR is opened, since the acceptance criteria's literal "CI is green" wording is not achievable today without one of these three interventions.
2. **Does "equivalent lockfile updates" in the acceptance criteria permit landing these three bumps as separate small PRs instead of one consolidated PR**, if that turns out easier operationally? The issue body says "consolidate onto one working branch if needed," implying consolidation is the default but not hard-mandated. This spec assumes one consolidated PR per the issue's primary framing; confirm with the user/orchestrator if a different shape is preferred.
3. **Should the PR description explicitly call out the `loofah` security advisories** (GHSA-5qhf-9phg-95m2, GHSA-8whx-365g-h9vv, GHSA-9wjq-cp2p-hrgf) for reviewer visibility, given it's a security-relevant patch riding along with two routine ones? Recommended yes, not treated as a hard requirement here.

## Changelog

### Version 1 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1154
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification created for consolidating Dependabot PRs #1150 (loofah), #1151 (parser), #1152 (autoprefixer) into one patch-bump PR
- Documented and verified compatibility of each bump against current lockfile constraints
- Identified and documented a pre-existing, unrelated RuboCop `lint` CI failure on `main` (10 offenses) that affects the literal "CI is green" acceptance criterion for any PR, including this one, and raised it as an open question rather than resolving it unilaterally
- Documented an unrelated Danger/Octokit infra failure specific to Dependabot-authored PR workflow runs (not expected to recur on a normally-authored consolidated PR)

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the code agent.

---
