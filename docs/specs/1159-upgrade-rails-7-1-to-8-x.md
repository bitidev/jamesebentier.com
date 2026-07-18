<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1159 -->
<!-- Last Updated: 2026-07-18T14:35:00+02:00 -->
<!-- Description Hash: bfa09dc924b2 -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# Upgrade Rails from 7.1 to Rails 8.x

**Issue:** [bitidev/jamesebentier.com#1159](https://github.com/bitidev/jamesebentier.com/issues/1159)
**Parent epic:** [#1147](https://github.com/bitidev/jamesebentier.com/issues/1147) — Upgrade all dependencies to latest versions (umbrella; **do not close #1147 when this lands — this issue only closes itself**)
**Branch:** `personal/jebentier/issue-1159-upgrade-rails-7-1-to-8`
**Board:** `BitiDev Board` (org `bitidev` project #2) — Status: In Progress; Assignee: `jebentier`

## Overview

This is the largest single blast-radius item in the `#1147` dependency-upgrade epic: moving the app's core framework from Rails `~> 7.1.6` to the latest stable Rails 8.x. There is no Dependabot PR to consolidate (Rails majors are too large for Dependabot to open unassisted), so this is a from-scratch manual upgrade. The sibling batches that already landed — `#1157` (Puma/`declare_schema`/`sitemap_generator` majors) and `#1158` (Tailwind v4/DaisyUI/webpack-cli majors, CSS-first config) — are both merged to `main`, so this spec's empirical verification (below) starts from a `main` tip that already reflects both.

Despite the "largest blast-radius" framing, direct empirical verification (a scratch `bundle update rails --conservative` in this worktree, fully reverted before writing this spec — see [Current State](#current-state-verified)) shows the actual required code diff is small: this app's Rails usage is narrow (2 models, 4 controllers, no Active Storage, no Action Mailbox/Text usage, no `enum`s, no `alias_attribute`, RSpec instead of Minitest), so almost none of the Rails 7.2/8.0/8.1 breaking changes apply. `bundle update rails --conservative` jumped straight from `7.1.6` to `8.1.3` (the latest stable 8.x release as of 2026-07-18) in one step with a clean, Rails-gems-only lockfile diff — no other gem needed to move. Two small, concrete, upgrade-required fixes were found (an Active Storage boot-time warning regression, and a RuboCop-Rails cop that now activates and wants one line changed) — both documented as [Findings](#findings) below with the exact fix. A third finding is a process warning, not a code change: `bin/rails app:update`'s "accept all" mode is dangerously destructive for this specific app and must not be run blindly.

## Goal

Land the app on the latest stable Rails 8.x release (`8.1.3`) with the minimum set of code/config changes the upgrade actually requires — keeping this PR's diff focused on the framework jump itself, per the issue's explicit "do not fold in unrelated Dependabot batches" instruction.

## In Scope

- Bump `rails` from `~> 7.1.3, >= 7.1.3.4` (locked `7.1.6`) to `~> 8.1.3` (locked `8.1.3`) in `Gemfile`/`Gemfile.lock`, via `bundle update rails --conservative` (see [Finding: The Rails Jump Itself Is a Clean, Minimal-Diff Bump](#finding-the-rails-jump-itself-is-a-clean-minimal-diff-bump))
- The one required config fix: disable Active Storage's variant processor lookup, since this app has no Active Storage usage at all (see [Finding: Active Storage Boot-Time Warning Regression](#finding-active-storage-boot-time-warning-regression))
- The one required lint fix: adopt `params.expect` in `BlogController#show`, per the newly-activated `Rails/StrongParametersExpect` RuboCop-Rails cop (see [Finding: RuboCop-Rails `Rails/StrongParametersExpect` Cop Activates](#finding-rubocop-rails-rails-strongparametersexpect-cop-activates))
- Re-dumping and committing `db/schema.rb` for Rails 8.1's alphabetical-column-reordering change (cosmetic only; see [Finding: Rails 8.1's Alphabetical `schema.rb` Column Reordering](#finding-rails-81s-alphabetical-schemarb-column-reordering))
- Confirming the full test suite, RuboCop, a local server boot, and all four key pages (home, blog index/detail, projects, resume) are green/`200` under Rails 8.1
- Documenting in the PR description that `bin/rails app:update`'s destructive default behavior was investigated and deliberately **not** run wholesale (see [Finding: `bin/rails app:update` Would Silently Destroy Real Customizations](#finding-bin-rails-appupdate-would-silently-destroy-real-customizations)), plus the upgrade notes / framework-defaults decisions the issue's acceptance criteria calls for

## Out of Scope

Per the issue body, explicitly excluded from this PR:

- Any other epic batch (GitHub Actions majors, Tailwind/DaisyUI/build-toolchain majors, opportunistic gem majors) — all already landed separately as `#1155`/`#1157`/`#1158`, or remain open under `#1147` for future issues
- Migrating the asset pipeline from Sprockets to Propshaft — Rails 8 makes Propshaft the default for *new* apps but Sprockets remains fully supported for existing ones (confirmed directly in Rails 8's official upgrade guide and release notes); this app's `sprockets-rails` + `jsbundling-rails`/`cssbundling-rails` setup was just migrated to Tailwind v4 in `#1158` and is explicitly out of scope for further churn here
- Adopting Solid Queue / Solid Cache / Solid Cable — these are Rails 8's new defaults for *new* apps only; existing apps (this one, on Redis-backed Action Cable and the default async Active Job adapter) keep their existing infrastructure unless a separate issue decides otherwise
- Adopting the Rails 8 built-in authentication generator, native rate limiting, or any other new Rails 8 feature not required to complete the version bump itself — this app has no authentication today and none is being added here
- Bumping `config.load_defaults` from `7.1` to `8.1` — see [Open Question 1](#open-questions); this spec recommends leaving it at `7.1` for this PR (old defaults preserved, minimum-diff bump) rather than adopting all new-version defaults in the same PR, but flags the trade-off explicitly rather than deciding unilaterally
- Running `bin/rails app:update` in its default "accept everything" mode — see the dedicated finding; only the two specific, hand-verified fixes in [In Scope](#in-scope) are required
- Any Ruby version change — Rails 8.1 requires Ruby `>= 3.2.0`; this app is already on `3.3.1` (`.ruby-version`, `Gemfile`'s `ruby "~> 3.3"`), well above the floor, and `#1157`'s sibling spec already covered the Ruby-runtime-gem-majors slice separately
- Closing epic `#1147`

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch `jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against the repo (worktree branched from `main` tip, which already includes `#1154`–`#1158` and `#1160` merged) as of 2026-07-18.

- **`Gemfile`/`Gemfile.lock` currently pin `rails` to `"~> 7.1.3", ">= 7.1.3.4"`, locked at `7.1.6`** — confirmed by direct inspection.
- **Latest stable Rails release, confirmed against RubyGems' own version index (`gem list rails --remote --all`), is `8.1.3`** — the `8.1.x` line (released after `8.0.x`) is itself already GA; the issue's "7.1 → 7.2 → 8.0" phrasing predates `8.1`'s release, but the issue's own acceptance criterion ("latest stable Rails 8.x") is unambiguous, so this spec targets `8.1.3`, not `8.0.x`. Flagged explicitly as [Open Question 2](#open-questions) in case the user wants to stop at `8.0.x` instead.
- **Direct empirical verification performed for this spec** (scratch `bundle update rails --conservative` after bumping the `Gemfile` constraint, verified, then fully reverted via `git checkout --`/`rm` — no trace left in the branch):
  - `Gemfile.lock`'s diff touches **only** the Rails-family gems themselves (`rails`, `action{cable,mailbox,mailer,pack,text,view}`, `active{job,model,record,storage,support}`, `railties`) plus their own direct transitive movement (`action_text-trix` and `useragent` added as new Action Text/Action Pack dependencies; `benchmark`, `cgi`, `docile`, `mutex_m` dropped as no-longer-required transitives) — see [Finding: The Rails Jump Itself Is a Clean, Minimal-Diff Bump](#finding-the-rails-jump-itself-is-a-clean-minimal-diff-bump). No other gem (`declare_schema`, `puma`, `sitemap_generator`, `turbo-rails`, `stimulus-rails`, `jsbundling-rails`, `cssbundling-rails`, `sprockets-rails`, `kamal`, `web-console`, `rspec-rails`, `database_cleaner-active_record`, etc.) needed to move.
  - `bundle exec rails runner "puts Rails.version"` after the bump: boots cleanly, prints `8.1.3`.
  - `bundle exec rake spec` (CI's `test`-job task, which builds JS/CSS assets before running RSpec): **56 examples, 0 failures, 3 pending** — until the two findings below were fixed, this instead showed 5 failures (see [Finding: Active Storage Boot-Time Warning Regression](#finding-active-storage-boot-time-warning-regression)); after both fixes, identical pass/pending counts to the pre-upgrade baseline (`bundle exec rspec` alone: 53 passed / 3 pending pre- and post-upgrade; `rake spec`'s 56 vs. 53 count difference is pre-existing and orthogonal to this upgrade — some specs only execute once frontend assets are built by the `rake spec` task's own JS/CSS build step).
  - `bundle exec rubocop`: **1 new offense** (`Rails/StrongParametersExpect` in `app/controllers/blog_controller.rb`) appeared purely from RuboCop-Rails auto-detecting the bumped Rails version in `Gemfile.lock` (no `TargetRailsVersion` is pinned in `.rubocop.yml`) — not from any gem version bump of `rubocop-rails` itself. Autocorrects cleanly; **0 offenses** after. See [Finding: RuboCop-Rails `Rails/StrongParametersExpect` Cop Activates](#finding-rubocop-rails-rails-strongparametersexpect-cop-activates).
  - `bin/rails server` (development, after fixing the Active Storage warning and building frontend assets via `yarn install && yarn build && yarn build:css`): boots cleanly on Puma `8.0.2` (unchanged from `#1157`), and `/`, `/blog`, `/blog/:slug` (a real post slug), `/projects`, `/resume` all return `200`; a nonexistent `/blog/:slug` correctly still returns `404` (confirms the `params.expect` fix doesn't change not-found behavior, only missing-parameter behavior).
  - `bundle exec rake db:schema:dump`: produces a **column-reorder-only** diff on both tables (see [Finding: Rails 8.1's Alphabetical `schema.rb` Column Reordering](#finding-rails-81s-alphabetical-schemarb-column-reordering)) plus the expected `ActiveRecord::Schema[7.1]` → `[8.1]` version-marker bump and one PostgreSQL extension name fully-qualifying itself (`"plpgsql"` → `"pg_catalog.plpgsql"`, an Active Record 8.x default schema-dump behavior, harmless).
  - `bundle exec rails generate declare_schema:migration --pretend`: reports **"Database and models match -- nothing to change"** — no orphan schema drift from the Rails bump itself beyond the cosmetic reorder above.
  - `bundle exec rails app:update` was run in "accept everything" mode as part of this spec's investigation, its full diff reviewed, then **entirely reverted** — see [Finding: `bin/rails app:update` Would Silently Destroy Real Customizations](#finding-bin-rails-appupdate-would-silently-destroy-real-customizations). This is the most important process finding in this spec.
  - All scratch changes (`Gemfile`, `Gemfile.lock`, `app/controllers/blog_controller.rb`, `config/application.rb`, every file touched by the `app:update` experiment, `spec/examples.txt`, `.yarn/install-state.gz`, `node_modules/`, `bun.lock`, built `public/assets`/`app/assets/builds/*`) were reverted via `git checkout --`/`rm` before this spec was written; the worktree is clean and still on `rails 7.1.6` as of this writing.

### Finding: The Rails Jump Itself Is a Clean, Minimal-Diff Bump

Bumping the `Gemfile` constraint straight to `gem "rails", "~> 8.1.0"` and running `bundle update rails --conservative` resolved to `8.1.3` in a single step — Bundler did not need (and `--conservative` did not force) any intermediate `7.2`/`8.0` lockfile state, because Bundler resolves directly to the newest version satisfying all constraints, not incrementally. The Rails guide's own recommendation to "move slowly, one minor version at a time" is about *catching deprecation warnings as you go*, not a Bundler mechanical requirement — and since this app has zero usage of any of the specific 7.2/8.0/8.1 breaking-change surface area (confirmed below), there were no deprecation warnings to catch in between. The resulting `Gemfile.lock` diff touches exactly: the Rails-family gems' own version lines, `action_text-trix` (new Action Text dependency) and `useragent` (new Action Pack dependency) added, and `benchmark`/`cgi`/`docile`/`mutex_m` dropped as transitives no longer required by the new Rails-family gem versions. No other gem in the `Gemfile` needed a version change — `activerecord-nulldb-adapter (1.2.2)`'s own constraint (`activerecord (>= 6.1, < 8.2)`) is satisfied by `8.1.3` with room to spare before the next major.

Checked against this app's actual code for each of the well-known Rails 7.2/8.0/8.1 breaking changes (per the official upgrade guide and 8.0 release notes):

- **Enum keyword-argument removal (Rails 8.0):** no model in `app/models/` uses `enum` at all — `Project#status` is a plain string column with an `inclusion` validation, not an AR `enum`. Not applicable.
- **`alias_attribute` bypass behavior change (Rails 7.2):** no usage anywhere in `app/`. Not applicable.
- **`to_time` timezone-preservation change (Rails 8.0):** no `.to_time` calls anywhere in `app/`. Not applicable.
- **Ruby 3.4 `csv` stdlib removal:** irrelevant — this app stays on Ruby `3.3.1`, not `3.4`, and don't use CSV anywhere in `app/`.
- **`Regexp.timeout` default of `1s` (Rails 8.0):** this app's regexes (a handful of small, fixed-pattern ones in config/tests) are not user-input-driven or large enough for this to plausibly matter; no incident expected.
- **Rails 8.1's alphabetical `schema.rb` column sort:** applicable — see its own finding below.
- **Sprockets → Propshaft default swap (Rails 8.0):** does not force a migration; Sprockets remains fully supported and is explicitly out of scope for this PR (see [Out of Scope](#out-of-scope)).

### Finding: Active Storage Boot-Time Warning Regression

This app has **no Active Storage usage whatsoever** — no `has_one_attached`/`has_many_attached` in either model, no `active_storage_*` tables in `db/schema.rb`, and the `image_processing` gem is explicitly commented out in the `Gemfile` (`# gem "image_processing", "~> 1.2"`). `config/application.rb` nonetheless `require`s `active_storage/engine` (inherited from the original `rails new` generation), so the engine's initializer still runs.

Rails 8's `ActiveStorage::Engine` `active_storage.configs` initializer (`activestorage-8.1.3/lib/active_storage/engine.rb`) unconditionally tries to resolve a variant-processor transformer at boot (defaulting to `:mini_magick`), and since `image_processing` isn't installed, it rescues the resulting `LoadError` and logs a warning via `ActiveStorage.logger` (which is `Rails.logger` by default):

```
Generating image variants require the image_processing gem. Please add `gem "image_processing", "~> 1.2"` to your Gemfile or set `config.active_storage.variant_processor = :disabled`.
```

This is new behavior versus Rails 7.1 — the equivalent 7.1 initializer did not eagerly attempt this resolution at boot. Two concrete consequences observed directly:

1. **Breaks a real test.** `spec/lib/production_config_hosts_spec.rb` boots a real `RAILS_ENV=production` subprocess via `Open3.capture3` and parses its `stdout` as JSON (deliberately, per the spec file's own comment, to exercise the actual `config.hosts` boot logic rather than re-implementing it). Because `config/environments/production.rb` sets `config.logger = ActiveSupport::Logger.new($stdout)...`, this warning line lands on the same `stdout` stream *before* the JSON payload, and `JSON.parse(stdout)` fails with a parser error on all 5 examples in that file.
2. **Pollutes real production boot logs** with a spurious warning on every single boot, for a feature the app never uses.

**Fix:** add one line to `config/application.rb`, inside the `Application` class body — exactly the fix the warning message itself recommends:

```ruby
config.active_storage.variant_processor = :disabled
```

Verified this eliminates the warning (`bundle exec rails runner "puts ..."` in `RAILS_ENV=production` produces clean JSON-only `stdout` again) and restores all 5 `production_config_hosts_spec.rb` examples to passing, with no other test suite regression (`rake spec`: 56/0/3 both before this app ever saw Rails 8 and after this fix).

### Finding: RuboCop-Rails `Rails/StrongParametersExpect` Cop Activates

`.rubocop.yml` does not pin `TargetRailsVersion`, so `rubocop-rails` auto-detects it from the installed Rails version. Once `Gemfile.lock` moves to `8.1.3`, the `Rails/StrongParametersExpect` cop (which recommends Rails 8's new `ActionController::Parameters#expect` over subscripting `params[...]` directly, since `#expect` raises a well-formed `ActionController::ParameterMissing` — auto-rescued by Rails into a `400`  — instead of silently returning `nil`) newly flags `app/controllers/blog_controller.rb`:

```ruby
# Before
@post = Post.find_by!(slug: params[:slug].downcase)

# After (bundle exec rubocop -A)
@post = Post.find_by!(slug: params.expect(:slug).downcase)
```

This is a one-line, `rubocop -A`-autocorrectable change, not a manual rewrite. It is also a **strict behavior improvement, not just a style change**: previously, a request somehow missing the `:slug` param (not reachable through this app's own routes, which always supply `:slug` as a path segment, but reachable via a raw HTTP request bypassing routing assumptions) would raise `NoMethodError` on `nil.downcase` → an unhandled `500`; with `params.expect(:slug)`, the same case now raises `ActionController::ParameterMissing`, which Rails' default exception handling converts to a `400 Bad Request` — the correct status for a malformed request. Verified via direct requests: a valid slug still returns `200`, and a not-found (but present) slug still correctly returns `404` (via `ActiveRecord::RecordNotFound`, unaffected by this change) — the `expect`/`find_by!` interaction was not confused with each other in testing.

Re-running `bundle exec rubocop` after the autocorrect: **0 offenses, 58 files** — matches the pre-upgrade clean baseline (per `#1157`'s spec, RuboCop's prior lint debt was already fully resolved by `#1155`).

### Finding: Rails 8.1's Alphabetical `schema.rb` Column Reordering

Per the official upgrade guide's own "Upgrading from Rails 8.0 to Rails 8.1" section: *"Active Record now alphabetically sorts table columns in `schema.rb` by default, so dumps are consistent across machines and don't flip-flop with migration order."* Running `bundle exec rake db:schema:dump` post-upgrade reorders both `posts`' and `projects`' columns alphabetically (e.g. `posts`: `created_at, description, file_path, image, keywords, lock_version, published_at, slug, tags, title, updated_at` instead of the original migration-order sequence) and bumps the schema version marker from `ActiveRecord::Schema[7.1]` to `[8.1]`. This is a **pure reformat** — no column added, removed, retyped, or renulled; `declare_schema:migration --pretend` confirms "Database and models match -- nothing to change" both before and after the reorder. One incidental, expected extension-name fully-qualification also appears (`enable_extension "plpgsql"` → `enable_extension "pg_catalog.plpgsql"`), a documented Active Record 8.x schema-dump default, likewise harmless.

Per the community guide consulted for this spec: *"Run `bin/rails db:schema:dump` immediately after upgrading to get the reorder out of the way before any real migrations. Commit this separately so the diff is clean."* This spec recommends the same: the code agent should re-dump and commit `db/schema.rb` as its own logical change within this PR (not bundled silently into an unrelated migration later), so the "no orphan schema drift" acceptance criterion is satisfied by an explicit, reviewable, zero-functional-change commit rather than left to surface unexpectedly on the next real migration.

### Finding: `bin/rails app:update` Would Silently Destroy Real Customizations

This is the most important process finding in this spec, because it is the one most likely to cause real damage if a future implementer runs the official upgrade guide's own recommended command (`bin/rails app:update`) in its default interactive-but-typically-rubber-stamped mode (or, worse, non-interactively with `yes |`, as this spec did *deliberately, to inspect the resulting diff* before reverting it).

Accepting every prompt (`yes | bundle exec rails app:update`) force-overwrote 17 files and would have **silently deleted or altered**, among other things:

- **`config/environments/production.rb`'s entire custom `config.hosts` allowlist** — the exact three-entry allowlist (`jamesebentier.com`, the subdomain regex, the legacy Heroku hostname) plus the `ADDITIONAL_ALLOWED_HOSTS` env-var-extension logic that `spec/lib/production_config_hosts_spec.rb` exists specifically to verify. The regenerated template replaces this with a commented-out generic `example.com` placeholder. Losing this without noticing would be a genuine production host-header-validation regression, not just a style loss.
- **`config.force_ssl = true`** in the same file — the regenerated template comments this out by default.
- **`config/application.rb`'s `Warning.ignore(...)` block** (four `Warning.ignore` calls suppressing specific known-noisy third-party gem warnings — `mail`, `sitemap_generator`, `declare_schema`) and its custom RSpec generator configuration (`g.test_framework :rspec, ...` / `g.integration_tool :rspec, ...`) — both entirely dropped by the regenerated template, which assumes Minitest and has no knowledge of this app's gem-specific warning suppressions.
- **`# frozen_string_literal: true` magic comments** at the top of every regenerated file, and several inline `# rubocop:disable ...` comments (e.g. `Style/Documentation`, `Metrics/BlockLength`) — dropped, which would immediately reintroduce RuboCop offenses this repo has deliberately kept clean since `#1155`.
- Several **new, unrelated files** the generator wants to add: `config/initializers/new_framework_defaults_8_1.rb` (an *optional* incremental-defaults-adoption aid — genuinely useful only if [Open Question 1](#open-questions) resolves toward bumping `config.load_defaults`, otherwise noise); `bin/ci` + `config/ci.rb` (Rails 8.1's new local-CI-runner feature — this repo already has its own GitHub Actions CI in `.github/workflows/`, so this is out-of-scope tooling duplication, not a required upgrade artifact); three `db/migrate/*.active_storage.rb` update migrations for Active Storage tables **this app has never created** (would be dead migration files referencing tables that don't exist — actively harmful to add given the "no orphan schema drift" acceptance criterion); regenerated `public/40x.html`/`50x.html` error pages and default `public/icon.{png,svg}` (cosmetic, not required).

**Recommendation:** do **not** run `bin/rails app:update` in this PR. Apply only the two hand-verified, minimal fixes documented in the two findings above (`config.active_storage.variant_processor = :disabled`, and the `rubocop -A` autocorrect to `blog_controller.rb`), plus the `db/schema.rb` re-dump. If a future implementer does want to run `app:update` (e.g., to review what other optional new defaults exist), they must review every file's diff individually (`d` for diff at each prompt) and decline (`n`) any file where this app has real customization — never batch-accept.

## Requirements

1. **R1 — Rails reaches latest stable 8.x.** `Gemfile`'s `rails` constraint moves from `"~> 7.1.3", ">= 7.1.3.4"` to `"~> 8.1.3"` (pin to the minor+patch floor, consistent with this repo's existing pinning style for `rails`), and `Gemfile.lock` locks `rails` (and its family: `actioncable`, `actionmailbox`, `actionmailer`, `actionpack`, `actiontext`, `actionview`, `activejob`, `activemodel`, `activerecord`, `activestorage`, `activesupport`, `railties`) at `8.1.3` — or whatever is the actual latest stable `8.1.x` patch at implementation time (re-check; do not assume `8.1.3` is still current). No other gem's version should move as a result, per [Finding: The Rails Jump Itself Is a Clean, Minimal-Diff Bump](#finding-the-rails-jump-itself-is-a-clean-minimal-diff-bump) — if the real `bundle update rails --conservative` run at implementation time touches additional gems beyond the ones this spec documents, investigate before proceeding.
2. **R2 — Active Storage boot-time warning fixed.** Add `config.active_storage.variant_processor = :disabled` to `config/application.rb`, per [its finding](#finding-active-storage-boot-time-warning-regression). This is required for `spec/lib/production_config_hosts_spec.rb` to pass and for production boot logs to stay clean.
3. **R3 — RuboCop clean.** `app/controllers/blog_controller.rb`'s `params[:slug]` becomes `params.expect(:slug)` (via `bundle exec rubocop -A`, then manually verified), per [its finding](#finding-rubocop-rails-rails-strongparametersexpect-cop-activates). `bundle exec rubocop` must report 0 offenses across all 58 files afterward.
4. **R4 — `db/schema.rb` re-dumped and committed.** Run `bundle exec rake db:schema:dump`, review the diff matches [the documented column-reorder-only shape](#finding-rails-81s-alphabetical-schemarb-column-reordering) (no actual column/type/nullability changes), and commit it as part of this PR so the "no orphan schema drift" criterion is satisfied by an explicit, reviewable commit rather than deferred to the next real migration.
5. **R5 — No blind `app:update`.** This PR's diff must not include any of the destructive or out-of-scope changes enumerated in [Finding: `bin/rails app:update` Would Silently Destroy Real Customizations](#finding-bin-rails-appupdate-would-silently-destroy-real-customizations) — in particular, `config/environments/production.rb`'s `config.hosts` allowlist and `config.force_ssl = true`, and `config/application.rb`'s `Warning.ignore` block and RSpec generator config, must remain byte-for-byte unchanged except for R2's one added line.
6. **R6 — Test suite green.** `bundle exec rake spec` (the CI `test` job's task) passes with the same pass/pending shape as the pre-upgrade baseline (56 examples, 0 failures, 3 pending) — no new failures, no newly-skipped/pending examples introduced by the upgrade itself.
7. **R7 — Key page render check.** `/` (home), `/blog` (post index), a real `/blog/:slug` (post detail — exercises the R3 `params.expect` change), `/projects`, and `/resume` all render `200` under Rails 8.1 via local `bin/rails server`; a nonexistent `/blog/:slug` still correctly renders `404` (confirming R3 didn't change not-found semantics).
8. **R8 — CI green.** `lint`, `test`, and `ci-gate` all pass on the PR — expected cleanly given R3/R6 above and the already-clean lint baseline inherited from `#1155`.
9. **R9 — Upgrade notes documented in the PR description.** Per the issue's own acceptance criterion, the PR description must call out: the exact Rails version landed on and why (latest stable 8.x, not just 8.0.x — see [Open Question 2](#open-questions)); the two required fixes (R2, R3) and why each was needed; the schema reorder (R4) and that it's cosmetic-only; and the explicit decision **not** to run `bin/rails app:update` wholesale, nor to bump `config.load_defaults` past `7.1` in this PR (see [Open Question 1](#open-questions)).

## Approach (Implementation Guidance)

This section is spec-level guidance for the **code** agent / implementer — not a substitute for their own verification.

1. Confirm working in the issue worktree (`personal/jebentier/issue-1159-upgrade-rails-7-1-to-8`), branched from current `main` (which already includes `#1154`–`#1158` and `#1160`).
2. Re-check the actual latest stable `8.1.x` patch at implementation time (`gem list rails --remote --all` or check RubyGems directly) — this spec verified `8.1.3` as of 2026-07-18; a newer patch may exist by the time this is implemented. Update the `Gemfile` constraint to `gem "rails", "~> <latest-8.1.x>"`.
3. Run `bundle update rails --conservative`. Diff `Gemfile.lock` and confirm the change is confined to the Rails-family gems plus their own direct transitives, matching [Current State](#current-state-verified) — investigate before proceeding if any unrelated gem moves.
4. Apply R2: add `config.active_storage.variant_processor = :disabled` to `config/application.rb` (inside the `Application` class body, near `config.load_defaults`). Verify with `RAILS_ENV=production SECRET_KEY_BASE=<64 chars> bundle exec rails runner "puts Rails.application.config.hosts.map(&:to_s).to_json"` that `stdout` is clean JSON with no preceding warning line.
5. Apply R3: `bundle exec rubocop -A` to autocorrect `blog_controller.rb`, then read the resulting diff to confirm it's exactly the `params[:slug]` → `params.expect(:slug)` change documented above (no unrelated autocorrections). Re-run `bundle exec rubocop` for a clean 0-offense result.
6. Apply R4: `bundle exec rake db:schema:dump`, review the diff is column-reorder-only (compare against [the finding](#finding-rails-81s-alphabetical-schemarb-column-reordering)), then commit `db/schema.rb`.
7. Do **not** run `bin/rails app:update`. If there is a genuine desire to explore Rails 8.1's other optional new defaults/files, do so as a clearly separate, later, opt-in issue — not folded into this PR (see [Finding](#finding-bin-rails-appupdate-would-silently-destroy-real-customizations) and R5).
8. Build frontend assets (`yarn install`, `yarn build`, `yarn build:css`) and run `bundle exec rake spec` for the full CI-equivalent pass (R6). Then `bin/rails server` locally and hit `/`, `/blog`, a real `/blog/:slug`, a nonexistent `/blog/:slug`, `/projects`, `/resume` to confirm R7's status codes.
9. Run `bundle exec rake assets:precompile` and `bundle exec rake db:prepare` locally (mirrors CI's `test` job exactly) as a final sanity pass before opening the PR.
10. Open the PR against `main` from the issue branch, with `Closes #1159` and `Part of #1147` (no close keyword for `#1147`) in the description, plus the R9 upgrade-notes summary. Reference this spec's Open Questions 1 and 2 in the description so the reviewer has the same context on the `config.load_defaults` and "8.0.x vs 8.1.x" decisions this spec made.
11. Once merged, hand off to the orchestrator for GitHub Issues lifecycle operations (closing `#1159`, leaving `#1147` open, board status) — the scribe/code agents do not perform these operations directly.

## Acceptance Criteria

Mapped from the issue body, sharpened with this spec's findings:

- [ ] `Gemfile`/`Gemfile.lock` on latest stable Rails 8.x (`~8.1.3` or newer `8.1.x` patch confirmed at implementation time) — R1
- [ ] App boots (local `bin/rails server` verified); migrations load (`bundle exec rake db:prepare` succeeds; `declare_schema:migration --pretend` reports no drift beyond the documented schema reorder); CI green — R1, R4, R8
- [ ] Test suite green after the two required Rails 8 API/config adjustments (Active Storage variant processor, `params.expect`) — R2, R3, R6
- [ ] Key site pages render: home (`/`), blog (`/blog` and a real `/blog/:slug`), projects (`/projects`), resume (`/resume`) — R7
- [ ] No orphan schema drift from upgrade-related generators or framework changes: `db/schema.rb`'s reorder is re-dumped and committed explicitly (not left pending), and `declare_schema:migration --pretend` reports a clean match — R4
- [ ] Upgrade notes / framework defaults changes called out in the PR description, including the deliberate decisions not to run `bin/rails app:update` wholesale and not to bump `config.load_defaults` in this PR — R9
- [ ] `#1159` uses `Closes #1159`; `#1147` is referenced only as `Part of #1147`, never closed
- [ ] No unrelated Dependabot batch, frontend toolchain change, or opportunistic gem major is bundled into this PR's diff

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns) and the scribe's own delegation rules:

- **Implementation** (bumping the `Gemfile`/`Gemfile.lock`, applying the two config/lint fixes, the schema re-dump, the boot/render verification, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (closing `#1159`, leaving `#1147` open, board status transitions): delegate to the **orchestrator** — this spec does not perform those operations. See [delegating-github-issues-to-orchestrator.md](../../adlc/methods/universal/delegating-github-issues-to-orchestrator.md).
- **The two Open Questions below** (whether to target `8.0.x` instead of `8.1.x`, and whether to bump `config.load_defaults` in this PR or defer it): decisions for the user/orchestrator, not the scribe.

## Open Questions

1. **Should this PR bump `config.load_defaults` from `7.1` to `8.1` (or leave it at `7.1` with old defaults preserved, adopting new defaults incrementally later)?** This spec's [Requirements](#requirements) and [Approach](#approach-implementation-guidance) recommend leaving `config.load_defaults 7.1` unchanged for this PR — the issue's acceptance criteria ask for "required framework defaults / deprecation fixes" (i.e., the ones the version bump actually forces, which this spec found to be none beyond the two documented findings), not a wholesale adoption of every new Rails 8.x default in the same PR. Leaving `load_defaults` at `7.1` keeps this PR's diff minimal and fully explained by the two concrete findings above; it defers the (larger, more speculative) exercise of walking through `new_framework_defaults_8_1.rb`-style incremental default adoption to a future, separately-scoped issue. This is a real trade-off, not a unilateral call this spec makes: if the user wants the framework-defaults adoption bundled into this same PR now (accepting a larger, less mechanically-verified diff), say so before implementation starts.
2. **Should this PR target `8.0.x` (matching the issue body's literal "7.1 → 7.2 → 8.0" phrasing) instead of the newer `8.1.x` line?** This spec recommends `8.1.3` because the issue's acceptance criterion explicitly says "latest stable Rails 8.x," and `8.1` is itself already a stable, released `8.x` minor (not a pre-release) — the "7.1 → 7.2 → 8.0" language in the issue body reads as the general shape of the incremental-upgrade path recommended by Rails' own guide (each minor's deprecations warn about the *next* minor's breaking changes) rather than a hard ceiling at `8.0`. Empirically, this app has zero code paths that trip on any 7.2/8.0/8.1-specific breaking change (per [Finding: The Rails Jump Itself Is a Clean, Minimal-Diff Bump](#finding-the-rails-jump-itself-is-a-clean-minimal-diff-bump)), so there is no deprecation-warning-based argument for stopping short at `8.0.x` in this specific case. Flagging this explicitly rather than assuming it, since it is a direct reading of "8.0 (as applicable)" in the issue body that a reviewer could reasonably disagree with.

## Changelog

### Version 1 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1159
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification created for the Rails 7.1 → 8.x framework upgrade, the largest single blast-radius item in the `#1147` dependency-upgrade epic
- Performed direct empirical verification (scratch `bundle update rails --conservative`, fully reverted before writing this spec) confirming the jump from `7.1.6` straight to `8.1.3` resolves cleanly in one Bundler step, moving only the Rails-family gems and their own direct transitives — no other gem in the `Gemfile` required a version change
- Discovered and documented the one concrete boot-time regression the upgrade introduces: Rails 8's Active Storage engine warns (via `Rails.logger`, landing on `stdout` in production) about a missing `image_processing` gem this app never needed, breaking a real test (`production_config_hosts_spec.rb`) that parses production boot `stdout` as JSON — fixed with a single documented config line
- Discovered and documented the one RuboCop-Rails cop (`Rails/StrongParametersExpect`) that newly activates purely from the Rails-version bump (no `rubocop-rails` gem version change involved), and confirmed its one-line autocorrect (`params.expect`) is a net behavior improvement (`400` instead of an unhandled `500` on a missing param), not just a style change
- Confirmed none of the well-known Rails 7.2/8.0/8.1 breaking changes (`enum` keyword-arg removal, `alias_attribute` bypass change, `to_time` timezone preservation, Ruby 3.4 `csv` removal, Sprockets→Propshaft default swap) apply to this codebase's actual usage
- Documented and verified Rails 8.1's alphabetical `schema.rb` column-reordering default as a cosmetic-only re-dump, confirmed via `declare_schema:migration --pretend` reporting no real drift
- Performed a full "accept everything" `bin/rails app:update` dry run specifically to catalog what it would destroy, then reverted it entirely — found it would silently delete this app's production `config.hosts` allowlist (the exact thing a real, passing test suite verifies), `config.force_ssl = true`, `Warning.ignore` suppressions, RSpec generator config, and `frozen_string_literal`/RuboCop-disable comments, plus add several out-of-scope files (Active Storage migrations for tables that don't exist, Rails 8.1's new local-CI-runner tooling, an optional framework-defaults file) — turned into an explicit "do not run this wholesale" finding and requirement (R5)
- Verified full test suite (`rake spec`: 56/0/3, matching pre-upgrade baseline), RuboCop (0 offenses/58 files), local server boot, and all four key pages (`/`, `/blog`, a real post detail, `/projects`, `/resume`) plus a not-found blog slug, all under Rails `8.1.3`
- Raised two open questions for user/orchestrator judgment rather than deciding unilaterally: whether to bundle a `config.load_defaults` bump into this same PR, and whether `8.1.x` (vs. the issue body's literal "...8.0" phrasing) is the correct target given the "latest stable Rails 8.x" acceptance criterion

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the code agent.

---
