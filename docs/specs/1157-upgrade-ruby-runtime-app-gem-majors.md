<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1157 -->
<!-- Last Updated: 2026-07-18T02:10:00+02:00 -->
<!-- Description Hash: 63bb8e7468cc -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# Upgrade Ruby Runtime and App Gem Majors

**Issue:** [bitidev/jamesebentier.com#1157](https://github.com/bitidev/jamesebentier.com/issues/1157)
**Parent epic:** [#1147](https://github.com/bitidev/jamesebentier.com/issues/1147) — Upgrade all dependencies to latest versions (umbrella; **do not close #1147 when this lands — this issue only closes itself**)
**Branch:** `personal/jebentier/issue-1157-upgrade-ruby-runtime-gem-majors`
**Board:** `jamesebentier.com Board` (org `bitidev` project #2) — Status: In Progress; Assignee: `jebentier`

## Overview

Three Dependabot PRs are open against `main`, each bumping a production-adjacent Ruby gem by a major version, with real runtime / schema / SEO blast radius:

| PR | Gem | From → To | Direct/Transitive in `Gemfile` | Nature |
|---|---|---|---|---|
| [#1064](https://github.com/bitidev/jamesebentier.com/pull/1064) | `puma` | 6.6.1 → 8.0.2 | Direct (`gem "puma", ">= 5.0"`) | Runtime web server (skips 7.x — two majors in one Dependabot bump) |
| [#1135](https://github.com/bitidev/jamesebentier.com/pull/1135) | `declare_schema` | 2.3.2 → 4.1.0 | Direct (`gem "declare_schema"`) | Schema DSL (skips 3.x — two majors in one Dependabot bump); also patched directly in `config/initializers/declare_schema.rb` |
| [#1129](https://github.com/bitidev/jamesebentier.com/pull/1129) | `sitemap_generator` | 6.3.0 → 7.1.0 | Direct (`gem "sitemap_generator"`) | SEO sitemap generation |

This is a deliberate **medium** capacity exercise per `docs/strategic-priorities.md` — larger than `#1154`'s patch batch and comparable in gem count to `#1156`'s test/dev batch, but qualitatively different because these three gems sit in the production runtime/schema/SEO path rather than test/dev tooling. The issue's own "split gate" instruction requires this spec to explicitly assess whether `declare_schema` 2→4 alone is too large for one PR before proceeding — see [Split Gate Assessment](#split-gate-assessment-declare_schema-2--4).

This spec covers consolidating the three bumps onto the issue's branch/PR, the one concrete schema migration the `declare_schema` major bump requires, the Puma-major boot/bind verification, and the sitemap smoke-test plan — closing out the "runtime/app gem major" slice of the `#1147` umbrella without pulling in any of the explicitly out-of-scope Rails/frontend work.

## Goal

Upgrade `puma`, `declare_schema`, and `sitemap_generator` to their current major versions so the production web server, schema-declaration layer, and SEO sitemap generator stay on supported, maintained releases — while keeping this PR's blast radius confined to these three gems and their immediately-required migration/config follow-through, per the issue's explicit exclusion of Rails and frontend CSS majors.

## In Scope

- Bump `puma` 6.6.1 → 8.0.2 (`Gemfile.lock`; unpinned in `Gemfile`, `>= 5.0`)
- Bump `declare_schema` 2.3.2 → 4.1.0 (`Gemfile.lock`; unpinned in `Gemfile`)
- Bump `sitemap_generator` 6.3.0 → 7.1.0 (`Gemfile.lock`; unpinned in `Gemfile`)
- The one required schema migration the `declare_schema` bump surfaces — adding `null: false` to `created_at`/`updated_at` on `posts` and `projects` (see [Finding: `declare_schema` 3.0.0 Tightens `timestamps` to `null: false`](#finding-declare_schema-30-tightens-timestamps-to-null-false)) — generated via `rails generate declare_schema:migration`, applied, and `db/schema.rb` regenerated
- Verifying `config/initializers/declare_schema.rb`'s two monkey-patches (`DeclareSchemaColumnPatch`, `DeclareSchemaMigratorPatch`, and the `_add_index_for_field` override) still apply cleanly against declare_schema 4.1.0's internals (see [Finding: Declare_schema Initializer Patches](#finding-declare_schema-initializer-patches-still-apply))
- Confirming Puma 8's changed default bind-host behavior (see [Finding: Puma 8 Default Bind-Host Change](#finding-puma-8-default-bind-host-change)) does not break boot in this app's deployment context
- Confirming `sitemap_generator` 7.x's breaking API removals/changes don't affect `config/sitemap.rb` (see [Finding: `sitemap_generator` 7.x Breaking Changes vs. This App's Usage](#finding-sitemap_generator-7x-breaking-changes-vs-this-apps-usage))
- Consolidating all three onto the single branch/PR named above
- Closing or superseding PRs #1064, #1135, #1129 once the consolidated PR merges (orchestrator-owned GitHub operation, see [Delegation](#delegation--handoff))
- Running the full local test suite, RuboCop, a local server boot, and a sitemap-generation smoke test to confirm no regressions

## Out of Scope

Per the issue body, explicitly excluded from this batch (remain open work under `#1147`):

- Ruby test/dev tooling majors (`rspec-rails`, `shoulda-matchers`, `simplecov`, `rdoc`, `octokit`) — already landed separately as `#1156`
- Safe patch-only gem/npm bumps — already landed separately as `#1154`
- GitHub Actions workflow dependency majors — already landed separately as `#1155`
- Frontend CSS/build majors (Tailwind, DaisyUI, `webpack-cli`, etc.)
- Rails major upgrade (`rails` stays pinned `~> 7.1.3, >= 7.1.3.4`; nothing in this batch requires moving it — declare_schema 4.x's floor is `rails >= 7.0`, already satisfied)
- Any new feature work on `Post`/`Project` schema beyond the one migration the gem's DSL default-change requires
- The Heroku→Linode/Kamal infrastructure migration referenced in `docs/superpowers/specs/2026-07-18-heroku-to-linode-kamal-split-design.md` — unrelated, separate workstream; this spec only confirms Puma 8's bind-host change is safe under the **current** Heroku deployment (see [Puma finding](#finding-puma-8-default-bind-host-change))

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch `jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against the repo (worktree branched from `main` tip, which already includes `#1154`, `#1155`, and `#1156` merged) and GitHub as of 2026-07-18. **RuboCop's previously-documented 10 pre-existing offenses (flagged as an open question in `#1154`'s and `#1156`'s specs) were fixed by `#1155`** — a fresh `bundle exec rubocop` on this branch reports **0 offenses across 54 files**. This batch inherits a clean lint baseline; no lint-debt open question needs to carry forward into this spec.

- **`Gemfile.lock` shows all three gems still at their pre-upgrade ("From") version**: `puma (6.6.1)`, `declare_schema (2.3.2)`, `sitemap_generator (6.3.0)` — confirmed by direct inspection of `Gemfile.lock`.
- **Each Dependabot PR's diff is minimal and lockfile-only**, confirmed via `gh pr diff`: #1064 touches only the `puma` version line; #1135 touches the `declare_schema` version line (`rails (>= 6.0)` → `rails (>= 7.0)` floor) plus unrelated transitive noise (`erb` 6.0.4→6.0.5) that has since drifted further on `main`; #1129 touches only the `sitemap_generator` version line. No application code is touched by any of the three raw Dependabot diffs.
- **Each Dependabot PR's own CI already passed independently** — `gh pr view --json statusCheckRollup` for all three shows `Test: SUCCESS` (and for #1135/#1129, opened after `#1155` landed, also `Lint: SUCCESS`, `ci-gate: SUCCESS`, `merge-guard: SUCCESS`). This is a strong signal but not sufficient on its own: the CI `test` job runs `bundle exec rake db:prepare` (loads `db/schema.rb` directly) and `rake spec`, which does **not** exercise the `declare_schema:migration` generator — so a green Dependabot CI run does not, by itself, prove there is no pending schema drift. That check required the direct verification below.
- **Direct empirical verification performed for this spec** (scratch `bundle update puma declare_schema sitemap_generator --conservative` in this worktree, verified, then fully reverted — no trace left in the branch):
  - `Gemfile.lock` after the update touches only the three gems' version lines (`puma`, `declare_schema`, `sitemap_generator`) plus one cosmetic `PLATFORMS` line (`arm64-darwin` → `arm64-darwin-24`, a local Bundler platform-resolution artifact from this machine, not expected to reappear when the code agent runs the real update from a stable base) and a `stringio` gemspec-resolution warning that is a pre-existing local-machine artifact unrelated to any of the three gems.
  - `bundle exec rake spec` (equivalent to CI's `test` job): **34 examples, 0 failures, 3 pending** — identical to the pre-upgrade baseline.
  - `bundle exec rubocop`: **54 files inspected, no offenses detected** — identical to the pre-upgrade baseline.
  - `rails generate declare_schema:migration --pretend`: reports a **real, required migration** — see the dedicated finding below. This is the one genuine schema-consequential change in this batch.
  - `bin/rails server` (development, Puma 8.0.2): boots cleanly, binds `http://127.0.0.1:PORT` **and** `http://[::1]:PORT`, and serves `/`, `/blog`, `/projects`, `/resume` all `200 OK`.
  - `bundle exec rake sitemap:create`: succeeds, generates `public/sitemap.xml.gz` (14 links / 1 sitemap).
  - All scratch changes (`Gemfile.lock`, the regenerated `public/sitemap.xml.gz`, `spec/examples.txt`) were reverted via `git checkout --` before this spec was written; the worktree is clean and still on `puma 6.6.1` / `declare_schema 2.3.2` / `sitemap_generator 6.3.0` as of this writing.

### Finding: `declare_schema` 3.0.0 Tightens `timestamps` to `null: false`

**This is the most important finding in this spec and is the concrete basis for the "no orphan schema drift" acceptance criterion and the split-gate assessment below.**

`declare_schema`'s CHANGELOG (`[3.0.0]`, bundled inside the 2.3.2→4.1.0 jump) states: *"The `timestamps` DSL method to create `created_at` and `updated_at` columns now defaults to `null: false` for `datetime` columns."* This app's `config/initializers/declare_schema.rb` sets `DeclareSchema.default_schema { timestamps; optimistic_lock }` — applied to **both** models (`Post`, `Project`) via the global default schema block, not per-model. Today's `db/schema.rb` has both tables' `created_at`/`updated_at` columns nullable (no `null: false`).

Running `rails generate declare_schema:migration --pretend` after the bump reproduces exactly this, on both tables:

```ruby
change_column :posts, :created_at, :datetime, null: false
change_column :posts, :updated_at, :datetime, null: false
change_column :projects, :created_at, :datetime, null: false
change_column :projects, :updated_at, :datetime, null: false
```

This is a real, intentional schema change the gem's new major version requires to keep "models and database match" — not a false positive. It is low-risk to apply: every row in both tables is created via `ActiveRecord` (`db/seeds.rb` uses `find_or_initialize_by(...).update!(...)` exclusively; no raw-SQL inserts anywhere in the codebase), so `created_at`/`updated_at` are already always populated by Rails' automatic timestamping — a `NOT NULL` migration should not fail against existing data in any environment. The code agent must generate this migration (`rails generate declare_schema:migration`, not `--pretend`), run `rails db:migrate`, and commit the resulting migration file plus the regenerated `db/schema.rb`, so that `rails generate declare_schema:migration --pretend` reports "Database and models match -- nothing to change" again post-upgrade. Leaving this pending would be exactly the "orphan schema drift" the acceptance criteria warns against.

### Finding: `declare_schema` Initializer Patches Still Apply

`config/initializers/declare_schema.rb` carries two `ActiveSupport::Concern` monkey-patches (`DeclareSchemaColumnPatch#deserialize_default_value`, prepended onto `DeclareSchema::Model::Column`; `DeclareSchemaMigratorPatch#table_options_for_model`, prepended onto the migrator) plus a direct module-reopen override of `DeclareSchema::Model::ClassMethods#_add_index_for_field` (the file's own comment says these exist because the gem is "majorily built for MySQL... but we're using PostgreSQL"). All three continued to load and function correctly against 4.1.0 in the scratch verification — the full test suite passed and the `--pretend` migration check produced only the expected `timestamps`-related diff, with no PostgreSQL-adapter-related errors. One pre-existing `warning`-gem diagnostic (`method redefined; discarding old _add_index_for_field`, from the direct module-reopen) appears **identically** at both 2.3.2 and 4.1.0 — confirmed by reproducing it at the current pinned version before touching anything — so it is not a new regression from this upgrade; no action needed beyond documenting it so the reviewer isn't surprised by an unfamiliar warning line that is, in fact, unrelated to this PR.

### Finding: Puma 8 Default Bind-Host Change

Puma 8.0.0's changelog lists a breaking change: *"Default production bind address changed from `0.0.0.0` to `::` (IPv6) when a non-loopback IPv6 interface is available; falls back to `0.0.0.0` if IPv6 is unavailable."* Confirmed directly in the installed gem's DSL source (`puma/dsl.rb`): `port` (called in `config/puma.rb` as `port ENV.fetch("PORT", 3000)`, with no explicit `host`) delegates to `default_host`, which implements exactly this IPv6-preferring fallback.

In the scratch boot test, Puma 8.0.2 bound **both** `http://127.0.0.1:PORT` and `http://[::1]:PORT` in this machine's dual-stack environment, and `/`, `/blog`, `/projects`, `/resume` all served `200 OK` — the new default did not break local boot. This app deploys to Heroku today (`terraform/heroku.tf`, `buildpacks = ["heroku/ruby"]`); Heroku's routing layer proxies to the dyno's assigned `$PORT` over the dyno's local network stack, and Heroku dynos are documented to support IPv6-or-IPv4 dual-stack loopback/local binding without requiring an explicit host — so this change is not expected to break the Heroku deployment path, but it has not been verified against the actual Heroku runtime (only local `bin/rails server`). The `Dockerfile`'s own `EXPOSE 3000` / `CMD ["./bin/rails", "server"]` path (used for the separate, out-of-scope Linode/Kamal migration work) is likewise unverified against this change. This spec does not require pinning an explicit `bind`/`host` in `config/puma.rb` — the acceptance criterion is "app boots under the new Puma major," which is satisfied locally — but flags the Heroku-runtime-specific verification gap as [Open Question](#open-questions) Q1 rather than assuming it away.

### Finding: `sitemap_generator` 7.x Breaking Changes vs. This App's Usage

`sitemap_generator`'s CHANGES.md lists several breaking changes across 7.0.0–7.1.0. Checked each against `config/sitemap.rb`:

- `FileAdapter#plain` removed, `FileAdapter#gzip` made private (7.1.0) — neither is called anywhere in this codebase; internal-only.
- Default search-engine ping list is now empty; `rake sitemap:refresh`/`ping_search_engines` no longer pings unless engines are explicitly configured (7.0.1) — this app's `config/sitemap.rb` never configures `search_engines`, and no rake task or CI step in this repo calls `sitemap:refresh` (the scratch smoke test used `sitemap:create`, which never pinged search engines even pre-upgrade). No behavior change for this app either way.
- `LinkSet#create` only runs `finalize!` automatically when a block is given (7.0.1) — `config/sitemap.rb` calls `SitemapGenerator::Sitemap.create do ... end` with a block, so `finalize!` still runs automatically; unaffected.
- Drops Ruby 2.5 / Rails 5.2 support (7.0.1) — this app runs Ruby 3.3.1 / Rails 7.1.6; already well above both floors.
- The scratch `bundle exec rake sitemap:create` smoke test confirmed generation still succeeds end-to-end (14 links / 1 sitemap / `public/sitemap.xml.gz`), matching the pre-upgrade output shape.

No config or code changes required for this gem beyond the version bump itself.

## Split Gate Assessment (`declare_schema` 2 → 4)

The issue's split-gate instruction requires this spec to explicitly document whether `declare_schema` 2→4 alone would exceed one-sitting review, and if so, to plan a follow-up-issue split rather than force an oversized PR.

**Assessment: does NOT exceed one-sitting review — recommend keeping all three gems in this single consolidated PR, no split needed.** Basis:

- The `declare_schema` major jump's only concrete application-level consequence in this codebase is the single [`timestamps`/`null: false` finding](#finding-declare_schema-30-tightens-timestamps-to-null-false) above — a 4-line migration (`change_column ... null: false` × 2 columns × 2 tables) plus the regenerated `db/schema.rb`. This is because the app's `declare_schema` usage is small and uniform: exactly two models (`Post`, `Project`), both using the same global `default_schema` block, no per-model schema divergence, no HABTM/foreign-key usage that would trigger the 4.0.0 "generalized belongs_to foreign keys" change (this app has no `belongs_to` associations at all — confirmed via `app/models/*.rb`), and no `serialize:` field usage that would trigger the 4.0.2 Rails-7.2-`serialize`-keyword fix (also confirmed absent).
- The gem's own initializer monkey-patches ([separate finding](#finding-declare_schema-initializer-patches-still-apply)) continue to work unmodified — no patch rewrite needed.
- Full test suite, RuboCop, and a `--pretend` migration dry-run were all exercised directly against the real 4.1.0 gem in this spec's verification pass, and the total diff shape (lockfile + one small migration + regenerated `schema.rb`) is well within what `#1154`/`#1156` established as reviewable-in-one-sitting for this repo.
- Bundling `puma` and `sitemap_generator` alongside `declare_schema` does not add review complexity of its own — both are lockfile-only bumps with zero required code changes (per their own findings above), so they add breadth (three gem names, three sets of release notes to skim) but not depth (no additional migrations, no additional config changes) to the review.

If, during implementation, the code agent discovers additional per-model `declare_schema` divergence not visible from this spec's read of `app/models/` (e.g., a model added between this spec and implementation), re-run the split-gate assessment before proceeding rather than silently absorbing a larger migration into this PR.

## Requirements

1. **R1 — Dependency bumps land on `main`.** `puma` reaches `8.0.2`, `declare_schema` reaches `4.1.0`, and `sitemap_generator` reaches `7.1.0` in `Gemfile.lock`, via one consolidated PR from this issue's branch.
2. **R2 — The required `declare_schema` migration lands with the bump, not after it.** Per the [`timestamps`/`null: false` finding](#finding-declare_schema-30-tightens-timestamps-to-null-false), generate the migration (`rails generate declare_schema:migration`), apply it (`rails db:migrate`), and commit both the new migration file and the regenerated `db/schema.rb` in the same PR. After this, `rails generate declare_schema:migration --pretend` must report "Database and models match -- nothing to change" — this is the literal, verifiable form of the "no orphan schema drift" acceptance criterion.
3. **R3 — No scope creep.** The consolidated PR's diff touches only: `Gemfile.lock` (the three gems' version lines and their directly-caused transitive movement), one new file under `db/migrate/`, `db/schema.rb` (version bump + the four `null: false` column changes), and `public/sitemap.xml.gz` if sitemap output content changes as a byproduct of running the generator during verification (regenerate and commit only if its content actually changed; do not commit a no-op regeneration). No Rails version change, no frontend/npm files touched, no unrelated model/controller changes.
4. **R4 — Puma-major boot verification.** Confirm the app boots cleanly under Puma 8.0.2 via local `bin/rails server` (or equivalent) and serves at least the home page with a `200` response, per the [Puma finding](#finding-puma-8-default-bind-host-change). Document in the PR that the IPv6-default-bind change was checked and did not break local boot, and explicitly flag (per [Open Question](#open-questions) Q1) that Heroku-runtime-specific verification is a follow-up rather than a blocking gate for this PR, unless the user directs otherwise.
5. **R5 — Sitemap smoke test.** Run `bundle exec rake sitemap:create` (or `sitemap:refresh:no_ping`, to avoid any external ping side-effect) after the bump and confirm it completes without error and produces a sitemap file, per the [`sitemap_generator` finding](#finding-sitemap_generator-7x-breaking-changes-vs-this-apps-usage).
6. **R6 — Key page render check.** Confirm `/` (home), a blog post listing/detail (`/blog`), `/projects`, and `/resume` all render without a 500/exception after the bump, under the new Puma major — this is both the issue's own acceptance criterion and a natural extension of R4's boot check.
7. **R7 — CI green.** Given the lint-debt baseline is now clean (per [Current State](#current-state-verified)), the consolidated PR is expected to pass `lint`, `test`, and `ci-gate` without any pre-existing-failure caveat needed (unlike `#1154`/`#1156`). If CI is unexpectedly red for a reason unrelated to these three gems, investigate before merging rather than assuming a repeat of the prior lint-debt situation.
8. **R8 — Dependabot PRs consolidated.** Once the consolidated PR merges, #1064, #1135, and #1129 are closed as superseded (orchestrator-owned; see [Delegation](#delegation--handoff)). #1147 remains open; #1157 closes itself.

## Approach (Implementation Guidance)

This section is spec-level guidance for the **code** agent / implementer — not a substitute for their own verification.

1. Confirm working in the issue worktree (`personal/jebentier/issue-1157-upgrade-ruby-runtime-gem-majors`), branched from current `main` (which already includes `#1154`/`#1155`/`#1156`).
2. Run the bumps against current `main`, not by merging the (now-stale) Dependabot branches: `bundle update puma declare_schema sitemap_generator --conservative`. Diff `Gemfile.lock` and confirm only these three gems (plus their directly-caused transitive lines) move — compare against [Current State](#current-state-verified).
3. Generate the required schema migration (R2): `bundle exec rails generate declare_schema:migration` (interactive — supply a descriptive name, e.g. `tighten_timestamps_not_null`), review the generated up/down migration matches the four `change_column ... null: false` statements documented in the [finding](#finding-declare_schema-30-tightens-timestamps-to-null-false), then `bundle exec rails db:migrate` and confirm `db/schema.rb` regenerates with the version bump and the four columns now `null: false`. Re-run `rails generate declare_schema:migration --pretend` and confirm it reports no remaining changes.
4. Run `bundle exec rake spec` and `bundle exec rubocop` for before/after parity. Both are expected to pass cleanly (34 examples / 0 failures; 0 RuboCop offenses) per [Current State](#current-state-verified) — investigate before proceeding if either regresses.
5. Perform the R4/R6 boot-and-render check: `bin/rails server` (or `bin/dev`), then visit `/`, `/blog`, `/projects`, `/resume` and confirm no 500s. Note the bind addresses Puma reports at boot in the PR description (per the [Puma finding](#finding-puma-8-default-bind-host-change)).
6. Perform the R5 sitemap smoke test: `bundle exec rake sitemap:refresh:no_ping` (avoids pinging real search engines from a dev/CI environment) and confirm it completes and writes a sitemap file. Only commit `public/sitemap.xml.gz` if its content actually differs from what's already tracked.
7. Open the consolidated PR against `main` from the issue branch. In the PR description: reference all three superseded Dependabot PRs (`Supersedes #1064, #1135, #1129`) and this issue (`Closes #1157`); explicitly document the R2 migration and why it's required (link to this spec's [finding](#finding-declare_schema-30-tightens-timestamps-to-null-false)); note the Puma bind-host change and that it was verified locally but not yet against the live Heroku runtime (per Open Question Q1); note the split-gate assessment's conclusion (no split needed) so the reviewer has that context up front.
8. Once merged, hand off to the orchestrator for GitHub Issues lifecycle operations (closing #1064, #1135, #1129 as superseded, closing #1157, leaving #1147 open) — the scribe/code agents do not perform these operations directly.

## Acceptance Criteria

Mapped from the issue body, sharpened with this spec's findings:

- [ ] `puma` reaches `8.0.2`, `declare_schema` reaches `4.1.0`, `sitemap_generator` reaches `7.1.0` in `Gemfile.lock` — via one consolidated PR
- [ ] The app boots under Puma 8.0.2 (local server boot verified; bind-host behavior documented in the PR)
- [ ] `rails generate declare_schema:migration --pretend` reports "Database and models match -- nothing to change" post-upgrade — the required `null: false` migration (R2) is generated, applied, and committed, not left pending
- [ ] `bundle exec rake sitemap:create` (or `sitemap:refresh:no_ping`) completes without error and produces a sitemap file post-upgrade
- [ ] `/`, `/blog`, `/projects`, `/resume` all render without a 500/exception post-upgrade
- [ ] No Rails major or frontend CSS/build major present in this PR's diff
- [ ] `lint`, `test`, and `ci-gate` are all green on the consolidated PR (no pre-existing-failure caveat expected, per the now-clean lint baseline)
- [ ] The split-gate assessment (no split needed) is documented in the PR description
- [ ] #1064, #1135, #1129 are closed/superseded once the consolidated PR merges; #1147 remains open; #1157 closes itself

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns) and the scribe's own delegation rules:

- **Implementation** (running `bundle update`, generating/applying the `declare_schema` migration, the boot/sitemap smoke tests, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (closing #1064/#1135/#1129 as superseded, transitioning #1157, leaving #1147 open, board status): delegate to the **orchestrator** — this spec does not perform those operations. See [delegating-github-issues-to-orchestrator.md](../../adlc/methods/universal/delegating-github-issues-to-orchestrator.md).
- **The Q1 Heroku-runtime-verification judgment call**: a decision for the orchestrator/user, not the scribe — see [Open Questions](#open-questions).

## Open Questions

1. **Is local `bin/rails server` boot verification sufficient for R4's "app boots under the new Puma major" criterion, or does this PR need to be verified against the actual Heroku runtime (e.g., via a review-app / staging deploy) before merging?** Per the [Puma finding](#finding-puma-8-default-bind-host-change), the IPv6-default-bind change was checked locally and did not break boot, but Heroku's dyno networking has not been directly exercised with Puma 8. This spec recommends treating local verification as sufficient for R4 (Heroku's dyno-local proxying is documented to tolerate dual-stack binds, and `config/puma.rb` sets no host that would conflict), with a live-deploy smoke check performed as a normal part of the next production deploy rather than as a blocking pre-merge gate — but does not decide this unilaterally; confirm with the user/orchestrator if a stricter pre-merge Heroku verification is wanted given this is a production runtime change.
2. **Does the split-gate assessment's "no split needed" conclusion hold if the code agent's actual `bundle update` run surfaces a different (larger) migration than this spec's scratch verification found** (e.g., due to further gem-internal changes between now and implementation, or a `Gemfile.lock` resolution difference)? This spec's recommendation to keep one consolidated PR is conditional on the migration staying the size documented in the [finding](#finding-declare_schema-30-tightens-timestamps-to-null-false) (4 columns, 2 tables, one `null: false` change). If the code agent's own `--pretend` run at implementation time shows something substantially larger, re-run the split-gate assessment and escalate rather than silently forcing it into this PR.
3. **Should `public/sitemap.xml.gz` be committed as part of this PR at all**, given it's a generated build artifact that happens to be tracked in git today (confirmed via `git check-ignore` — it is *not* gitignored)? This spec recommends only committing it if the R5 smoke test produces content that differs from what's currently tracked (i.e., don't create a no-op diff), consistent with R3's "no scope creep." Flagged since this is a slightly unusual repo convention (tracking a generated artifact) worth the reviewer's awareness rather than silent handling.

## Changelog

### Version 1 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1157
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification created for consolidating Dependabot PRs #1064 (puma), #1135 (declare_schema), #1129 (sitemap_generator) into one production-runtime/schema/SEO major-bump PR
- Performed direct empirical verification (scratch `bundle update`, fully reverted before writing this spec) of all three gems against this app's actual models, config, and test suite — not just Dependabot's own CI history
- Discovered and documented the one concrete schema consequence of the `declare_schema` 2→4 jump: the 3.0.0 `timestamps` DSL default change to `null: false`, requiring a real (small, low-risk) migration on `posts`/`projects` `created_at`/`updated_at` — turned into R2, the literal form of the issue's "no orphan schema drift" criterion
- Confirmed the `declare_schema` initializer's two PostgreSQL-compatibility monkey-patches continue to work unmodified against 4.1.0, and that a `_add_index_for_field` redefinition warning is pre-existing at 2.3.2 (not a new regression)
- Confirmed Puma 8's IPv6-preferring default bind-host change does not break local boot, and identified the Heroku-live-runtime verification gap as an open question rather than assuming it away
- Confirmed `sitemap_generator` 7.x's breaking API changes (removed/private `FileAdapter` methods, empty default search-engine list, conditional `finalize!`) do not affect this app's `config/sitemap.rb` usage
- Performed the required split-gate assessment for `declare_schema` 2→4 per the issue's explicit instruction, concluding no split into a follow-up issue is needed given the small, uniform, two-model schema surface in this app — documented the concrete basis for that conclusion so it can be re-checked if implementation reveals something larger
- Noted that the lint-debt open question carried by `#1154`'s and `#1156`'s specs is now resolved (fixed by `#1155`) and does not need to carry forward into this spec's CI-green requirement

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the code agent.

---
