# Spec: Bump GitHub Actions Workflow Dependencies

- **Issue**: [#1155](https://github.com/bitidev/jamesebentier.com/issues/1155)
- **Parent epic**: #1147 (dependency upgrade umbrella) — this PR must **not** close #1147
- **Status**: Draft
- **Author**: scribe agent
- **Version**: 1.0

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-07-18 | Initial specification |

## Overview

Four Dependabot PRs are currently open against `.github/workflows/`, each bumping a single GitHub Action used in this repo's CI/CD pipeline:

| Dependabot PR | Action | From | To |
|---|---|---|---|
| [#1096](https://github.com/bitidev/jamesebentier.com/pull/1096) | `actions/checkout` | `v4` | `v7` |
| [#1144](https://github.com/bitidev/jamesebentier.com/pull/1144) | `actions/setup-node` | `v4.4.0` | `v7.0.0` |
| [#1149](https://github.com/bitidev/jamesebentier.com/pull/1149) | `actions/github-script` | `v7` | `v9` |
| [#1020](https://github.com/bitidev/jamesebentier.com/pull/1020) | `dependabot/fetch-metadata` | `v2.5.0` | `v3.1.0` |

This spec consolidates all four bumps into a single PR rather than merging them individually, so that CI is validated once against the full set of new action versions and the four superseded Dependabot PRs can be closed together. This is pure CI/CD infrastructure maintenance — no application code, Gemfile, or package.json dependencies change.

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

## Testing / Verification

Because this is CI/CD infrastructure, "testing" means proving the workflows still execute correctly with the new pins — there is no application test suite change.

1. **Static check**: after editing, re-run the repo-wide search for the four action names to confirm every occurrence was updated and no stray old pin remains:
   - `rg 'uses:\s*"?(actions/checkout|actions/setup-node|actions/github-script|dependabot/fetch-metadata)@' .github/`
2. **CI workflow (`ci.yml`)**: push the branch and open the PR against `main`. Confirm all three jobs affected by the `checkout`/`setup-node` bumps go green:
   - `danger` job completes (Danger comment posts or job succeeds).
   - `lint` job completes (RuboCop passes as before).
   - `test` job completes: Node setup succeeds, `yarn install --frozen-lockfile` succeeds (validates `setup-node` + yarn caching still works), asset precompile and `rake spec` succeed.
   - `ci-gate` job reports success (aggregates `lint` + `test`).
3. **Merge Guard (`merge-guard.yml`)**: since this workflow triggers on `workflow_run` for `CI`, confirm it fires after the PR's CI run completes and correctly posts the `merge-guard` commit status (success/failure) — this exercises the bumped `github-script@v9` end-to-end without needing a separate manual trigger.
4. **Resume workflow (`resume.yml`)**: this only runs on push to `main`/`master`, so it cannot be exercised directly on the PR branch. Verify by inspection that the sole `checkout` pin was bumped correctly (v4 → v7); no functional regression is expected per the compatibility notes above. Optionally, note in the PR description that this workflow will be implicitly verified on the next merge to `main`.
5. **Automerge workflow (`automerge.yml`)**: this only runs for `pull_request_target` events from `dependabot[bot]`, so it cannot be exercised by this (human-authored) PR directly. Verify by inspection that `steps.metadata.outputs.update-type` is still the correct output key for v3.1.0 (confirmed above), and that the pin was bumped correctly. This will be implicitly verified the next time a Dependabot PR opens after this change merges.
6. **Overall gate**: the PR is not ready to merge until `ci-gate` and `merge-guard` both report green on the PR's own commits.

## Security Considerations

- `actions/checkout@v7`'s new default (refusing fork PR checkout under `pull_request_target`/`workflow_run` unless `allow-unsafe-pr-checkout: true`) is a **security hardening** change upstream. This repo does not use `checkout` under either trigger today, so the bump introduces no behavior change — but it also means we must resist any future temptation to add `checkout` to `automerge.yml` (which does run under `pull_request_target`) without explicitly reviewing the "pwn request" risk described in the upstream advisory (https://gh.io/securely-using-pull_request_target). No code change is required now; this is a forward-looking guardrail for reviewers.
- All four actions move to a Node 24 action runtime. GitHub-hosted runners (`ubuntu-latest`) already support this; no runner-version pin exists in this repo that would need updating.
- Pinning to upstream major-version tags (`@v7`, `@v9`, etc.) rather than to a commit SHA is consistent with this repo's existing convention (all current pins use tags, not SHAs) and with what the Dependabot config already produces. This spec does not change that convention; SHA-pinning is out of scope.
- No new secrets, permissions, or `GITHUB_TOKEN` scopes are introduced by any of the four bumps. `merge-guard.yml`'s existing `permissions` block (`contents: read`, `statuses: write`, `pull-requests: write`, `issues: write`) and `automerge.yml`'s (`contents: write`, `pull-requests: write`) remain unchanged and sufficient.

## Acceptance Criteria

- [ ] `actions/checkout` is `v7` in all 4 call sites (`ci.yml` ×3, `resume.yml` ×1).
- [ ] `actions/setup-node` is `v7.0.0` in `ci.yml`.
- [ ] `actions/github-script` is `v9` in `merge-guard.yml`.
- [ ] `dependabot/fetch-metadata` is `v3.1.0` in `automerge.yml`.
- [ ] No other `uses:` pin, workflow trigger, permission, or job step is modified beyond the four bumps (and any minimal compatibility fix identified during implementation per the compatibility notes above).
- [ ] No `Gemfile`, `Gemfile.lock`, `package.json`, or `yarn.lock` changes are included in this PR.
- [ ] The PR's own `ci-gate` job (aggregating `danger`/`lint`/`test`) reports green.
- [ ] The PR's own `merge-guard` status check reports green, confirming `github-script@v9` behaves correctly.
- [ ] Dependabot metadata parsing (`fetch-metadata` output `update-type`) and `github-script` consumers behave as before — verified by inspection per Testing/Verification, since neither `automerge.yml` nor `resume.yml` can be triggered directly by this PR.
- [ ] The PR description references Dependabot PRs #1096, #1144, #1149, and #1020 as superseded, and does **not** contain `Closes #1147`.
- [ ] Dependabot PRs #1096, #1144, #1149, #1020 are closed/superseded once this PR merges (Dependabot auto-closes on next scan since the versions in the base branch now match or exceed what those PRs proposed).

## Out of Scope

- Any Gem/npm application dependency upgrade (Rails, gems, JS packages) — tracked separately under epic #1147.
- The Rails major-version upgrade.
- Frontend CSS/build tooling major upgrades (e.g., Tailwind/webpack majors).
- Adding SHA-pinning for any GitHub Action (would be a separate hardening proposal).
- Adding `allow-unsafe-pr-checkout` or otherwise changing `checkout` trigger behavior.
- Modifying `.github/dependabot.yml` scheduling, grouping, or labels.
- Upgrading `ruby/setup-ruby`, `MeilCli/danger-action`, or `elgohr/Publish-Docker-Github-Action` (not in the Dependabot PR set named in this issue).
- Closing parent epic #1147 (must remain open; only its child issue #1155 is closed by this work).

## Implementation Handoff

This is a mechanical, low-risk version-pin change confined to `.github/workflows/`. Recommended handoff to the **code** agent with this spec as the sole reference. No architecture, test-code, or integrator involvement is expected — there is no `src/` application code touched, so no subsystem catalog update is required (per `docs/architecture/overview.md` scope, which governs `app/`/`lib/`, not `.github/`).
