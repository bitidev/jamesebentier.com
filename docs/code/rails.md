# Rails Best Practices

This checklist covers Ruby on Rails-specific best practices, current through **Rails 8**.

**See also:**
- [Universal Programming Best Practices](universal.md) - language-agnostic principles that apply to all code.
- [Ruby Best Practices](ruby.md) - core-language practices that all Rails code should also follow.

## Detect the Stack Before Applying the Checklist

Rails ships strong defaults, but real apps override them — and applying a default-shaped rule to an
app that chose otherwise is a false finding. **Read the app's actual choices before reviewing**, don't
assume:

- [ ] Rails version confirmed (`Gemfile` / `Gemfile.lock`); Rails-8-only advice (Solid stack, built-in `rate_limit`) applied only when the app is on 8+
- [ ] Job/cache/cable backends read from `config/*.yml` + initializers, not assumed (Solid Queue vs delayed_job vs Sidekiq/Resque; Solid Cache vs Redis/Memcached)
- [ ] Secrets mechanism confirmed — encrypted credentials (`config/credentials.yml.enc`) **or** pure-ENV (`.env` / `dotenv` / platform vars); absence of `credentials.yml.enc` is a valid choice, not a defect
- [ ] Test framework, factory library, and system-test driver read from the `Gemfile` (RSpec vs Minitest; FactoryBot vs Fabrication/Machinist; Selenium vs Cuprite/Playwright) before writing or reviewing tests
- [ ] View layer confirmed (ERB / HAML / Slim; ViewComponent; presenters/decorators) before commenting on templates
- [ ] Non-default config that changes reasoning noted: `belongs_to_required_by_default`, `active_record.default_timezone`, `config.time_zone`, `i18n.available_locales`

## Convention and Architecture

- [ ] Rails conventions followed (naming, directory layout) — fight the framework only with a documented reason
- [ ] Skinny controllers, focused models; no business logic in views or controllers
- [ ] Fat models split before they sprawl: extract POROs / service objects / concerns for cohesive behavior
- [ ] Domain logic lives in `app/models` or `app/services`, not in helpers, jobs, or controllers
- [ ] Service objects have a single public entry point and return a clear result (value or result object), not raw booleans-plus-side-effects
- [ ] Concerns used for genuinely shared behavior, not as a dumping ground to shrink a file
- [ ] Extra app layers are recognized and kept cohesive where present (`app/services`, `app/policies`, `app/presenters`/`app/decorators`, `app/components`, `app/form_models`, `app/uploaders`, `app/jobs`, `app/mailers`)

## Rails 8 Runtime Stack (Solid — and its alternatives)

Rails 8 defaults the queue, cache, and Action Cable backends to the **Solid** libraries, which run on
the primary (or a companion) SQL database — no Redis required. Verify what the app actually uses; the
default is a starting point, not a guarantee.

- [ ] **Solid Queue** (`config.active_job.queue_adapter = :solid_queue`) recognized as the Rails 8 default job backend; its `solid_queue` DB tables/migrations and Puma-plugin or `bin/jobs` supervisor are present
- [ ] **Solid Cache** recognized as the default `Rails.cache` store; **Solid Cable** as the default Action Cable adapter — both DB-backed, so cache/broadcast load hits the database, not Redis
- [ ] Adapter overrides are honored, not "corrected" to Solid: an app on **delayed_job** (`:delayed_job`, `handle_asynchronously`), **Sidekiq**/**GoodJob**/**Resque**, or a **Redis/Memcached** cache made a deliberate choice — review it on its own terms
- [ ] Multi-database wiring for Solid (separate `queue`/`cache`/`cable` databases in `config/database.yml`) is intact if the app uses the split-DB layout
- [ ] Async backend chosen for the deployment model (Solid Queue suits single-DB / modest scale; Sidekiq/Redis still common at high throughput) — don't recommend a swap without the operational reason

## ActiveRecord — Querying and Performance

- [ ] N+1 queries avoided with `includes` / `preload` / `eager_load`; verified with the **bullet** gem (wired into dev/test — see [Observability](#observability--logging-errors-apm)) or query-log inspection
- [ ] `select`/`pluck` used to fetch only needed columns for large reads
- [ ] Batch processing uses `find_each` / `in_batches`, never `.all.each` over large tables
- [ ] Aggregates done in SQL (`count`, `sum`, `group`) rather than loading records into Ruby
- [ ] `exists?` used for presence checks instead of `present?`/`any?` that load records
- [ ] Scopes used for reusable query fragments; they return relations (chainable), not arrays
- [ ] Indexes exist for foreign keys and columns used in `where`/`order`/uniqueness
- [ ] `counter_cache` or denormalization considered for hot count queries
- [ ] Large result sets paginated (**Pagy** — lightweight, `include Pagy::Backend` in the controller / `Pagy::Frontend` in the view — or **Kaminari**); never render an unbounded collection

## ActiveRecord — Models and Data Integrity

- [ ] Associations declared with appropriate options (`dependent:`, `inverse_of`, `foreign_key`)
- [ ] Validations present for application-level rules, **and** backed by DB constraints (NOT NULL, unique indexes, FKs) — validations alone race
- [ ] Uniqueness enforced by a unique index, not only `validates :uniqueness`
- [ ] Enums defined explicitly; underlying values stable and intentional
- [ ] Callbacks used sparingly; complex side effects moved to service objects (callbacks are hard to test and order-dependent)
- [ ] No business logic triggered implicitly on `save` that callers can't see
- [ ] Money/decimals stored as `decimal` (not float); time stored in UTC unless the app deliberately sets `default_timezone`/`time_zone` otherwise (verify, don't assume)
- [ ] `belongs_to` requiredness understood: `belongs_to_required_by_default` makes associations required unless `optional: true` — check the app's setting before flagging a "missing presence validation"

## Migrations

- [ ] Migrations are reversible (`change`, or explicit `up`/`down`); irreversible steps declared
- [ ] Schema changes and data backfills separated (data changes in tasks/jobs, not schema migrations)
- [ ] Large-table changes are safe: indexes added `algorithm: :concurrently` (with `disable_ddl_transaction!`), columns added without long locks
- [ ] No `NOT NULL` added to a populated column without a default/backfill plan
- [ ] `schema.rb` / `structure.sql` committed and consistent with migrations
- [ ] Migrations do not reference application model classes (use raw SQL / `execute` or inline minimal models)

## Controllers and Routing

- [ ] Strong parameters used; mass assignment scoped with `permit` (never `permit!` on user input)
- [ ] RESTful routes preferred; custom actions justified
- [ ] Correct HTTP status codes returned (`201`, `422`, `404`, etc.), not bare `200`
- [ ] `before_action` used for shared setup/authorization, kept readable (no deep filter chains)
- [ ] No heavy work in the request cycle that belongs in a background job
- [ ] Format-aware responses (`respond_to` / `format.turbo_stream` / `format.json`) return the right content type per request

## Authorization

Authorization is enforced per action, never inferred from routing or navigation. Whatever the mechanism,
**one system owns the decision** — the biggest real-world failure is dual authorization that drifts.

- [ ] Every state-changing (and every sensitive read) action is explicitly authorized; unauthenticated/under-privileged access is denied by default, not by omission
- [ ] **Pundit**: a policy exists per resource; `ApplicationPolicy` denies by default (base methods return `false`); controllers call `authorize` and use `policy_scope` for index/collection reads; `verify_authorized` / `verify_policy_scoped` `after_action` guards catch forgotten checks
- [ ] **CanCanCan**: abilities defined in one `Ability` class; `authorize!` / `load_and_authorize_resource` used consistently
- [ ] **No dual authorization**: an app on Pundit (or CanCanCan) does not also scatter ad-hoc `is_admin?` / `current_user.admin?` / `authenticate_admin!` checks that duplicate or contradict the policy layer — role logic belongs in the policy/ability, called the same way everywhere
- [ ] Role/permission source (e.g. **rolify**, an enum, a join table) is single and authoritative; policies read from it rather than re-deriving roles inline
- [ ] Tests assert both allowed and denied paths (policy specs and/or request specs returning `403`/redirect)

## Security (Rails-Specific)

Beyond the [universal security practices](universal.md#security-awareness):

- [ ] Mass-assignment controlled via strong parameters everywhere user input reaches a model
- [ ] SQL injection avoided: parameterized queries / hash conditions; no string interpolation into `where`/`order` (use `sanitize_sql`/allowlist for dynamic `order`)
- [ ] Output escaping left to the template engine by default (ERB, HAML, Slim all auto-escape); `html_safe`/`raw`/`!=` (HAML) only on sanitized content
- [ ] User-supplied HTML run through `sanitize` with an allowlist
- [ ] CSRF protection enabled (`protect_from_forgery` / default) for state-changing requests; API-only controllers use token/null-session strategy deliberately
- [ ] Open redirects prevented (`redirect_to` validated, `allow_other_host` not enabled blindly)
- [ ] File uploads validated (content type, size) — see [File Uploads](#file-uploads--attachments)
- [ ] **Abuse-sensitive endpoints rate-limited** — Rails 8's built-in `rate_limit to:, within:` in the controller (backed by `Rails.cache`) for logins, signups, password resets, and expensive actions; pre-8 apps use `rack-attack`
- [ ] `bundler-audit` (and/or Dependabot) run in CI to catch vulnerable gem versions

### Secrets and Credentials

Rails supports **encrypted credentials** and **plain ENV**; many apps use one, some use both. Neither is
wrong — but the mechanics differ, and a check that assumes one will false-flag the other.

- [ ] Encrypted credentials edited via `rails credentials:edit` (or `--environment production`); values read through `Rails.application.credentials.dig(...)`, never hard-coded
- [ ] `config/master.key` (and any `config/credentials/*.key`) is **git-ignored and never committed**; the key is provided in production via `RAILS_MASTER_KEY` or a secrets manager
- [ ] `secret_key_base` comes from credentials or ENV, never a literal in source
- [ ] **Pure-ENV apps are valid**: an app with no `credentials.yml.enc` that reads secrets from ENV (`.env`/`dotenv`, platform config) is not missing credentials — confirm secrets are still kept out of the repo and out of logs
- [ ] `.env` / real secret files are git-ignored; only a committed `.env.sample`/`.env.example` template documents the required keys
- [ ] ENV-vs-credentials trade-off applied deliberately (credentials: versioned-with-code, one key to manage; ENV: 12-factor, platform-native rotation) — don't mandate a migration between them without reason

## Hotwire — Turbo & Stimulus

Hotwire (Turbo + Stimulus) is the Rails default front end. Where the app uses it, review for these;
where it uses a JS framework (React/Vue via jsbundling) or is API-only, this section may not apply.

- [ ] Controller actions render `turbo_stream` responses (`format.turbo_stream`, `.turbo_stream.erb`/`.haml` templates, or `turbo_stream.replace/append/...` helpers) for partial-page updates instead of full reloads
- [ ] Turbo Frames (`turbo_frame_tag`) scope navigation/updates to a region; `data-turbo-frame` / `target: "_top"` used where a link must break out
- [ ] Turbo Drive gotchas handled: `data-turbo-method`/`data-turbo-confirm` for non-GET links, `data-turbo-permanent` for elements that must survive navigation, and third-party JS re-initialized on `turbo:load` (not `DOMContentLoaded`)
- [ ] **Stimulus** controllers live under `app/javascript/controllers`, one behavior per controller, wired with `data-controller`/`data-*-target`/`data-action`; DOM logic lives here, not inline `<script>`
- [ ] Asset pipeline choice is coherent: **importmap** (no build) vs **jsbundling** (esbuild/Bun/Webpack) vs Sprockets — pins/entrypoints match the chosen approach; don't mix advice across them
- [ ] Turbo Streams broadcast from models/jobs (`broadcasts_to`, `Turbo::StreamsChannel`) go over Action Cable — mind the cable adapter (Solid Cable / Redis) and authorization of the stream

## View Layer

The default is ERB, but HAML and Slim are common, and component/presenter layers are widespread. Review
against the engine and layers the app actually uses.

- [ ] Templates kept logic-light; presentation logic lives in helpers, **presenters/decorators** (e.g. Draper, or plain POROs), or **ViewComponent** classes — not inline in the template
- [ ] **ViewComponent** used for reusable, testable UI units where present: one component per file under `app/components`, backing Ruby class + template, unit-tested in isolation (`render_inline`)
- [ ] Template engine consistency respected (ERB / **HAML** / **Slim**); auto-escaping relied on, raw output (`raw`, `html_safe`, HAML `!=`) only for sanitized content; HAML linted with **haml_lint** where HAML is used
- [ ] Forms built with the app's chosen builder (`form_with`, **simple_form**, or a form-model layer) consistently, not a mix of hand-rolled and helper-based forms
- [ ] Partials kept small and cohesive; shared markup extracted to partials/components rather than copy-pasted
- [ ] API serialization done with an explicit serializer (jbuilder / AMS / Alba / `serializable_hash`), not ad-hoc hashes leaking fields
- [ ] `content_tag`/tag helpers used over raw HTML strings in helpers

## Caching

- [ ] Expensive views/fragments cached with appropriate keys (`cache` + Russian-doll caching where it fits)
- [ ] Cache keys include a version/`updated_at` so stale content expires correctly
- [ ] Cache store matches the app (Solid Cache on Rails 8 by default; Redis/Memcached where configured) — cache volume sized against the backing store (DB-backed caches add DB load)
- [ ] Low-level caching (`Rails.cache.fetch`) used with bounded keys and sensible expiry; no unbounded cache growth

## Background Jobs and Async

- [ ] Long-running / external-I/O work moved to background jobs via **Active Job**, on whatever adapter the app runs (Solid Queue on Rails 8 by default; delayed_job, Sidekiq, GoodJob, Resque otherwise)
- [ ] Jobs are idempotent and safe to retry (no duplicate side effects on re-run)
- [ ] Jobs enqueue IDs and re-load records, not serialized model instances
- [ ] Failure/retry behavior configured intentionally (backoff, dead-set, alerting), using the adapter's mechanism
- [ ] Jobs do not depend on records that may be deleted before they run (guard for missing records)
- [ ] `handle_asynchronously` (delayed_job) or adapter-specific async DSLs kept explicit and greppable; the async boundary is visible at the call site

## Internationalization (i18n)

- [ ] User-facing strings go through `t()` / `I18n.t` (and `l()` for dates/times), not hard-coded in views, models, or flashes
- [ ] Locale files (`config/locales/*.yml`) are the single source of copy; keys namespaced sensibly; lazy lookup (`t('.title')`) used in views
- [ ] `I18n.available_locales` is an explicit allowlist; user/param-driven locale is validated against it before `I18n.locale=` (never set locale from raw input)
- [ ] Locale negotiation is deliberate (param > user preference > `Accept-Language` > default); `default_locale` and `fallbacks` configured
- [ ] Missing-translation handling intentional (raise in test/CI, or `i18n-tasks` to detect missing/unused keys) rather than silently shipping `translation missing`

## File Uploads & Attachments

The app uses **Active Storage** or **CarrierWave** (or Shrine) — confirm which; the mechanics and where
validation lives differ.

- [ ] Upload mechanism identified: **Active Storage** (`has_one_attached`/`has_many_attached`, `config/storage.yml` services) or **CarrierWave** (`mount_uploader`, `*Uploader` classes under `app/uploaders`)
- [ ] Content type **and** size validated (Active Storage validations / `active_storage_validations` gem, or CarrierWave `content_type_allowlist`/`size_range`) — never trust the client-supplied filename or MIME type alone
- [ ] Images/derivatives generated as **variants** (Active Storage `variant`) / CarrierWave `version`s, processed off the request path where heavy
- [ ] **Direct uploads** used for large files where appropriate (Active Storage direct upload, or presigned S3) to keep bytes off the app server
- [ ] Storage service configured per environment (local disk in dev/test, S3/GCS/Azure in prod); credentials via credentials/ENV, not committed
- [ ] Uploads stored outside the web root and served through the app / signed URLs, not from a public writable path

## Observability — Logging, Errors, APM

- [ ] Structured/production logging configured (**lograge** or **rails_semantic_logger**) so logs are queryable, not multi-line noise
- [ ] **Secrets and PII never logged** — no tokens, passwords, session IDs, or personal data in logs; `config.filter_parameters` covers sensitive params (passwords, tokens, card data)
- [ ] Error tracking wired up (**Sentry**, **Rollbar**, Honeybadger, or Bugsnag) with environment/release context; exceptions reported, not just rescued-and-swallowed
- [ ] APM/performance monitoring where the app has it (**Scout**, **New Relic**, Datadog, Skylight) — used to find N+1s and slow endpoints rather than guessing
- [ ] Log level appropriate per environment; request IDs / correlation tags present for tracing across jobs and requests

## Testing (Rails-Specific)

Beyond the [universal testing practices](universal.md#testing) and [Ruby testing](ruby.md#testing-ruby-specific).
**Match the app's chosen stack** — write tests in the framework, factory library, and driver the app
already uses; don't introduce a second one.

- [ ] Test framework matches the project: **RSpec** (`spec/`) or **Minitest** (`test/`) — one, used consistently
- [ ] Model logic, validations, and scopes covered by model specs/tests
- [ ] Request/integration specs cover controller behavior end-to-end (status, side effects, authorization — including denied paths)
- [ ] System/feature tests cover critical user flows, using the app's driver: **Selenium**, **Cuprite** (headless Chrome via CDP), or **Playwright** — not assumed to be Selenium; JS-dependent flows use a JS-capable driver
- [ ] Test data built with the app's factory library — **FactoryBot** (`build`/`create`), **Fabrication** (`Fabricate`), or **Machinist** — building minimal valid objects; no over-broad shared fixtures with hidden coupling
- [ ] **shoulda-matchers** (or equivalent) used for concise validation/association assertions where the app uses them
- [ ] External services stubbed at the boundary (**WebMock**/**VCR**), not by mocking the unit under test
- [ ] Turbo Stream / component behavior tested where used (request specs assert `turbo_stream` responses; `render_inline` for ViewComponents)
- [ ] Tests assert observable behavior and persisted state, not that a callback/method was called

## Linting & Static Analysis

Pick **one** Ruby formatter/linter family per project and run it in CI — don't mix RuboCop and standardrb
configs. Layer the Rails-aware plugins on top.

- [ ] A Ruby style tool configured and passing in CI: **RuboCop** with the Rails plugin ecosystem (**rubocop-rails**, **rubocop-rspec**, **rubocop-performance**, **rubocop-capybara**) **or** **standardrb** (opinionated, zero-config) — not both
- [ ] **haml_lint** run where HAML is used; ERB linted (`erb_lint`) where relevant
- [ ] **bundler-audit** (and Brakeman for static security analysis) in CI to catch vulnerable gems and Rails security smells
- [ ] **bullet** wired into development and test (`config/environments/development.rb` + `test.rb`: `Bullet.enable`, `Bullet.bullet_logger`/`raise` in test) so N+1s surface automatically, not only on manual inspection
</content>
</invoke>
