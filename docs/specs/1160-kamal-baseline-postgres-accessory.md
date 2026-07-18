<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1160 -->
<!-- Last Updated: 2026-07-18T10:54:00+02:00 -->
<!-- Description Hash: f11df67ddb5d -->
<!-- Spec Version: 2 -->
<!-- END METADATA -->

# Kamal Baseline + Postgres Accessory for Linode

**Issue:** [bitidev/jamesebentier.com#1160](https://github.com/bitidev/jamesebentier.com/issues/1160)
**Parent epic:** [#1148 — Migrate from Heroku to Linode + Kamal](https://github.com/bitidev/jamesebentier.com/issues/1148) (umbrella; **do not close #1148 when this lands**)
**Branch:** `personal/jebentier/issue-1160-kamal-baseline-postgres-accessory`
**Board:** org `bitidev` project — Status: In Progress; Assignee: `jebentier`
**Design:** [`docs/superpowers/specs/2026-07-18-heroku-to-linode-kamal-split-design.md`](../superpowers/specs/2026-07-18-heroku-to-linode-kamal-split-design.md) — child 1 of 4 ("Ready first")

## Overview

The app currently runs on Heroku (Ruby buildpack, `schematogo` Postgres add-on, `heroku_addon`/`heroku_app` Terraform resources — see `terraform/heroku.tf`). Per the epic split, this issue delivers the **first** Ready slice: a Kamal deploy configuration that runs this Rails app as a Docker container on a single, human-provisioned Linode host, with Postgres running alongside it as a Kamal accessory container. It intentionally stops short of public DNS, CI automation, and Heroku teardown — those are separate, already-filed sibling issues (see [Out of Scope](#out-of-scope)).

This is infrastructure/deploy-configuration work: `config/deploy.yml`, `.kamal/`, `Dockerfile` touch-ups, a couple of small app-config changes, and a runbook. It does not add product features.

## Goal

From a clean clone of `main`, with secrets filled in and a Linode host the human operator has already created, a single operator can run `kamal setup` (first deploy) and get a working, fresh-database Rails app answering HTTP(S) on that host — with Kamal as the documented, intended deploy path from this point forward. Public DNS cutover, CI automation, and Heroku retirement are explicitly deferred to their own issues.

## In Scope

- `config/deploy.yml` (Kamal 2.x) targeting exactly one Linode host, with host/user supplied via environment rather than hardcoded
- A `postgres` Kamal **accessory** (`accessories.postgres` in `config/deploy.yml`) running on the same host, with a persisted data volume
- `.kamal/secrets` (committed) that references environment variables only — never literal secret values — for `RAILS_MASTER_KEY`, the Postgres password, and the registry credential
- Docker registry choice and configuration needed for `kamal setup`/`kamal deploy` to push/pull the app image (see [R5](#r5--registry-choice-is-explicit-and-ci-compatible))
- Minimal app-side wiring so a **fresh** database is created and migrated (and, matching current Heroku `release` behavior, seeded) automatically when the app container boots — no restore, no data import
- A narrow, environment-driven relaxation of `config.hosts` (Rails host-authorization allowlist) so the app answers when reached by the Linode's bare IP or a placeholder hostname, ahead of the DNS cutover in #1161
- A short first-deploy runbook (new doc, path specified in [Requirements](#requirements)) walking the human operator through: filling `.kamal/secrets`/env values, `kamal setup`, and verifying the app answers on the host
- Any `Dockerfile` / `bin/docker-entrypoint` adjustments needed to make the above work under Kamal (Kamal builds and runs the existing `Dockerfile`; it does not require a separate one)

## Out of Scope

Per the design doc and issue body — these are separate, already-identified issues and **must not** be pulled into this PR:

- Creating the Linode instance or bootstrapping SSH access — human-owned, outside ADLC (issue assumes the host and an SSH-reachable user already exist)
- Any database **restore** or Heroku→Linode data migration — this issue is fresh-DB-only by design
- Route53/CloudFront Terraform changes and the public DNS cutover — [#1161](https://github.com/bitidev/jamesebentier.com/issues/1161)
- A CI job that runs Kamal after a green `main` build — [#1162](https://github.com/bitidev/jamesebentier.com/issues/1162)
- Removing Heroku from Terraform (`terraform/heroku.tf`) or decommissioning the Heroku app — [#1163](https://github.com/bitidev/jamesebentier.com/issues/1163)
- Any work on siblings #1161, #1162, or #1163 themselves
- Adding a Redis/Action Cable accessory — see [Current State: Redis / Action Cable](#redis--action-cable-is-unused-scaffolding)

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch `jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against the repo (`main` @ `9df77ee`) as of 2026-07-18:

### Database / boot sequence

- `config/database.yml` production block already reads a full connection URL: `url: <%= ENV['SCHEMATOGO_URL'].presence || ENV['DATABASE_URL'].presence %>` (`config/database.yml:85`). `SCHEMATOGO_URL` is a Heroku-`schematogo`-add-on-specific variable and becomes vestigial once Postgres is a Kamal accessory — it can stay as a harmless fallback (no operator will set it outside Heroku) rather than being removed, to keep this PR's diff minimal; flagged in [Open Questions](#open-questions).
- `bin/docker-entrypoint` already runs `./bin/rails db:prepare` before starting `rails server` (creates the DB and loads schema/migrates it if it doesn't exist yet) — this is the "migrate on boot" behavior the epic asks for, and it already works for a from-scratch database.
- `bin/docker-entrypoint` does **not** run `db:seed`. On Heroku, `bin/release` (wired via `Procfile`'s `release: bin/release`) runs `bundle exec rails db:migrate db:seed` as a separate release-phase step Kamal has no equivalent of. `db/seeds.rb` is not test fixture data — it seeds real production content (the two portfolio `Project` records and every post under `public/blog/*.md`). Without seeding, a fresh Kamal deploy would boot successfully but serve an empty blog/projects section, which would silently fail the epic's "the app answers on the host" spirit (it *responds*, but without its actual content). See [R2](#r2--fresh-db-boot-includes-seed-parity-with-heroku-release).
- `db/seeds.rb` seed operations are idempotent (`find_or_initialize_by(...).update!`), so re-running seed on every boot/redeploy is safe.

### Dockerfile / image

- `Dockerfile` is already close to Kamal-ready: multi-stage build, precompiles assets and Bootsnap at build time (no `RAILS_MASTER_KEY` needed for `assets:precompile` — uses `SECRET_KEY_BASE_DUMMY=1`), runs as non-root `rails` user, `EXPOSE 3000`, default `CMD ["./bin/rails", "server"]`. This matches Kamal's default expectations (an app listening on port 3000; Kamal builds and runs this same `Dockerfile` — no separate Kamal-specific image is needed).
- `Gemfile` has no `kamal` gem yet. It needs to be added (development-only, `require: false`, matching the existing `pry`/`rubocop` pattern) so `bin/kamal`/`bundle exec kamal` is available without touching the production runtime image (Kamal itself doesn't need to ship inside the deployed container).

### Health check / host authorization

- `config/routes.rb:14` already exposes Rails' default health check at `GET /up` (`rails/health#show`, 200 if the app boots without exception) — this is exactly what Kamal's built-in proxy health check probes by default, so no new health-check code is needed.
- `config/environments/production.rb:93-97` sets `config.hosts` to a **fixed allowlist**: `jamesebentier.com`, a subdomain regex, and the current Heroku hostname. Rails' `ActionDispatch::HostAuthorization` middleware returns HTTP 403 for any request whose `Host` header isn't on this list — **including requests to the Linode's bare IP address**, which is exactly how the epic's "Done when" criterion ("the app answers on the host … public domain optional at this step") will be verified before DNS cutover. This must be addressed here, in #1160, because the DNS-cutover issue (#1161) is explicitly scoped to Route53/CloudFront Terraform, not to this Rails-level allowlist, and this issue's own acceptance criteria depend on IP-based access working. See [R6](#r6--config-hosts-allows-ip-based-verification-pre-dns-cutover).

### Redis / Action Cable is unused scaffolding

- `redis` is in the `Gemfile`, and `config/cable.yml` configures a Redis-backed Action Cable adapter for production, but `app/channels/` contains only the default `ApplicationCable::Connection`/`Channel` scaffolding — no app code defines a channel, subscribes to one, or calls `broadcast_*`/`turbo_stream` broadcasts anywhere in `app/`. Action Cable is not exercised by this app today. Adding a Redis Kamal accessory purely to satisfy an unused code path would be scope creep beyond what #1160 needs; **no Redis accessory is in scope**. If Action Cable/Redis becomes load-bearing later, that's new work with its own issue.

### CI / registry

- `.github/workflows/ci.yml` has no Docker registry login step and no image push today (Heroku deploys via buildpack, not a container registry). There is currently **no container registry account or credential wired into this repo or its GitHub secrets**. Kamal's `kamal setup`/`kamal deploy` need *some* registry to push the built image to and have the Linode host pull it from — this decision doesn't exist yet and must be made by this spec (see [R5](#r5--registry-choice-is-explicit-and-ci-compatible)).
- `ci-gate` (`.github/workflows/ci.yml:77`) requires `lint` and `test` to pass; this spec does not change CI (that's #1162's job), but the implementing PR must still pass existing `ci-gate` unmodified.

## Requirements

1. **R1 — Single-host Kamal config, host/user via environment.** `config/deploy.yml` defines exactly one Linode server (no multi-host/role complexity) and resolves the target IP/hostname and SSH user from environment variables (e.g. via Kamal's built-in ERB evaluation of `config/deploy.yml`, reading `ENV["KAMAL_HOST"]`/`ENV["KAMAL_SSH_USER"]` or equivalent, optionally loaded from a git-ignored `.env`) rather than a literal IP committed to the repo. Document the exact variable names and a placeholder value in the runbook (R7) so a clean clone with those two values filled in is deployable. SSH port/user matches whatever the human's manual Linode/SSH setup already established — this spec does not prescribe or create that user, only names the variable that carries it.
2. **R2 — Fresh-DB boot includes seed parity with Heroku `release`.** On first boot against an empty database (and safely again on redeploys, given seeds are idempotent), the app must run the equivalent of `db:prepare` **and** `db:seed` — matching the two-step behavior `bin/release` already performs for Heroku, so the deployed app serves its real blog/projects content, not just an empty schema. The implementer chooses the mechanism (extend `bin/docker-entrypoint`, or use a Kamal hook such as `.kamal/hooks/post-deploy`) — either is acceptable as long as it runs automatically as part of `kamal setup`/`kamal deploy` with no manual `kamal app exec` step required by the operator. No restore, no import of existing Heroku data — `db:seed` only, exactly as `bin/seeds.rb` defines it today.
3. **R3 — Postgres accessory on the same host, with persisted data.** `config/deploy.yml`'s `accessories.postgres` block runs an official `postgres` image (pin a specific major version compatible with `pg ~> 1.1` and this app's `db/schema.rb`, e.g. `postgres:16`) on the same Linode host as the app, with a named/bind-mounted `directories` volume for `/var/lib/postgresql/data` so accessory restarts do not lose data. The accessory's Postgres user/database/password are supplied via `env.clear`/`env.secret` in the accessory block, matching the values the app's `DATABASE_URL` (below) is built from.
4. **R4 — App points at the accessory via `DATABASE_URL`, no `config/database.yml` restructuring required.** `config/database.yml`'s existing `production.url` (`ENV['SCHEMATOGO_URL'].presence || ENV['DATABASE_URL'].presence`) is reused as-is. The Kamal app service's `env.secret` supplies `DATABASE_URL` pointing at the Postgres accessory's Kamal-assigned container hostname (Kamal names accessory containers `<service>-<accessory-name>`, e.g. `jamesebentier-site-postgres`, reachable by that name from the app container on Kamal's private Docker network) and port `5432`, with credentials matching R3. No `SCHEMATOGO_URL` value is ever set outside Heroku — it remains a harmless dead fallback (see [Open Questions](#open-questions)).
5. **R5 — Registry choice is explicit and CI-compatible.** `config/deploy.yml`'s `registry` block names a real, working registry for `kamal setup`/`kamal deploy` to push to and the Linode host to pull from. Recommended default: **GitHub Container Registry (`ghcr.io`)**, authenticated with a GitHub Personal Access Token (classic, `write:packages` scope) supplied via `.kamal/secrets` as `KAMAL_REGISTRY_PASSWORD`, with `registry.username` set to the GitHub username/org. This is recommended (not Kamal's newer `localhost` self-hosted-registry option) specifically because #1162 will need CI (GitHub Actions) to push to the same registry later using `GITHUB_TOKEN`/`ghcr.io` credentials that already exist in that environment for free — choosing `ghcr.io` now avoids re-plumbing the registry when #1162 lands. If a different registry is chosen instead, the choice and rationale must be recorded in this spec's Open Questions before implementation, since it's a real fork in the design, not a detail.
6. **R6 — `config.hosts` allows IP-based verification pre-DNS-cutover.** `config/environments/production.rb`'s `config.hosts` allowlist gains an environment-driven extension point (e.g. append any hostnames/IPs from `ENV["ADDITIONAL_ALLOWED_HOSTS"]`, comma-separated, if present) so the operator can add the Linode's bare IP (or a temporary hostname) without editing and redeploying application code every time. The existing fixed entries (`jamesebentier.com`, its subdomain regex, and the Heroku hostname) are left untouched — this is additive, not a replacement, and is intentionally narrow (an explicit opt-in allowlist addition, not disabling host authorization entirely) since disabling `config.hosts` protection outright would reopen a DNS-rebinding attack surface for a convenience that's only needed until #1161 ships.
7. **R7 — First-deploy runbook.** A new, short (one printed page or so) operator-facing runbook document exists at `docs/ops/kamal-first-deploy.md` (new directory; this repo has no `docs/ops/` yet) covering, at minimum: (a) prerequisites already assumed true (Linode created, SSH reachable, `kamal` gem installed via `bundle install`); (b) exactly which environment variables / `.kamal/secrets` entries must be filled in before running anything, with a placeholder example for each (host/user from R1, `RAILS_MASTER_KEY`, Postgres password, registry credential from R5); (c) the exact command sequence for a first deploy (e.g. `kamal setup`, or `kamal accessory boot postgres` followed by `kamal deploy` if the implementer's chosen ordering needs the DB accessory up first); (d) how to verify success (`curl` or browser hit on `/up` and on a real page, against the Linode's IP per R6); (e) where secrets should live locally (a git-ignored `.env` and/or the operator's own password manager) and an explicit reminder that no real secret value is ever committed to `.kamal/secrets` itself (only `ENV["…"]` references are). This is a **new file to create**, not an update to an existing doc.
8. **R8 — No unrelated scope.** The PR's diff is limited to: `config/deploy.yml`, `.kamal/` (secrets file, and hooks if R2 uses that mechanism), `Gemfile`/`Gemfile.lock` (adding the `kamal` gem only), `Dockerfile`/`bin/docker-entrypoint` (only as needed for R2/R3/R4), `config/environments/production.rb` (only the R6 addition), `.gitignore` (if a local `.env` convention is introduced per R7), and the new `docs/ops/kamal-first-deploy.md`. No Terraform changes (`terraform/` is entirely out of scope here — Heroku stays defined in Terraform until #1163), no CI workflow changes, no DNS/CloudFront changes, no unrelated dependency bumps or refactors.

## Approach (Implementation Guidance)

This section is spec-level guidance for the **code** agent / implementer — not a substitute for their own verification against current Kamal docs (Kamal 2.12.0 is current at time of writing; `gem list -r kamal` confirms availability).

1. Confirm working in the issue worktree (`personal/jebentier/issue-1160-kamal-baseline-postgres-accessory`), branched from current `main`.
2. Add `gem "kamal", require: false` to the `:development` group in `Gemfile` (alongside `pry`, `web-console`) and `bundle install` to update `Gemfile.lock`. Do not add it to the production runtime image — Kamal orchestrates deploys from the operator's machine, it doesn't need to run inside the deployed container.
3. Run `bundle exec kamal init` to scaffold `config/deploy.yml` and `.kamal/secrets`, then hand-edit both to match R1–R5:
   - `service:` a short app identifier (e.g. `jamesebentier-site`, matching the existing Heroku app name for continuity).
   - `image:` `<registry-username>/jamesebentier-site` (or the `ghcr.io/<org>/<repo>` form if using GHCR per R5 — Kamal derives the full registry host from the `registry:` block, don't duplicate it in `image:`).
   - `servers:` a single host resolved from `ENV["KAMAL_HOST"]` (R1); `ssh: { user: <%= ENV["KAMAL_SSH_USER"] %> }` if a non-default SSH user is needed.
   - `proxy:` `app_port: 3000` (matches `Dockerfile`'s `EXPOSE 3000`/Puma's `PORT` default). Once the target host and public hostname are both known (as they are here — `jamesebentier.com` on the shared Linode), `proxy.host`/`proxy.ssl: true` can be configured now so Kamal's proxy requests its Let's Encrypt certificate and routes that hostname; this is independent of whether the DNS record itself already resolves there. Actual DNS record ownership/verification (Route53/CloudFront Terraform) remains #1161's job — this spec only configures the app/proxy side of the hostname, not the DNS side. Kamal's health check defaults to `/up`, which already exists (no config needed).
   - `registry:` per R5.
   - `builder:` set `arch:` to match the Linode's actual CPU architecture (most Linode plans are `amd64`) — if the operator's local machine is a different architecture (e.g. Apple Silicon), either configure Docker buildx for cross-compilation or use Kamal's `builder.remote` option to build directly over SSH on the target host, sidestepping cross-arch emulation entirely. Document whichever is chosen in the R7 runbook, since it changes what the operator needs installed locally.
   - `env.secret:` `RAILS_MASTER_KEY`, `DATABASE_URL` (or the accessory's discrete `POSTGRES_USER`/`POSTGRES_PASSWORD`/`DB_HOST` vars if that shape is preferred — either satisfies R4, pick one and be consistent with `accessories.postgres.env`).
   - `accessories.postgres:` per R3, with `host:` the same Linode IP as `servers:`, and `directories: ["data:/var/lib/postgresql/data"]`.
4. `.kamal/secrets`: reference every secret used above as `KEY=$KEY` (or `KEY=$(cat path/to/local/file)` for `RAILS_MASTER_KEY` from `config/master.key`/credentials tooling) — never a literal value. This file is committed; it must contain zero real secrets, only variable/command references, consistent with how `RAILS_MASTER_KEY` is already handled for Heroku (`terraform/heroku.tf`'s `heroku_config.sensitive_vars`, supplied out-of-band).
5. Implement R2 (seed-on-boot parity): either extend `bin/docker-entrypoint` to run `db:seed` right after the existing `db:prepare` call (simplest, mirrors current Heroku `release` semantics, runs on every container start — safe since seeds are idempotent), or add a `.kamal/hooks/post-deploy` script that runs `kamal app exec 'bin/rails db:seed'` after each deploy. Prefer the `docker-entrypoint` approach unless there's a reason boot time shouldn't include seeding (there doesn't appear to be one here, given idempotency).
6. Implement R6: add a small, guarded addition to `config/environments/production.rb`, e.g. appending `ENV["ADDITIONAL_ALLOWED_HOSTS"].to_s.split(",").map(&:strip)` to the existing `config.hosts` array, only when the env var is present. Leave the three existing entries untouched.
7. Write `docs/ops/kamal-first-deploy.md` per R7.
8. Verify locally to the extent possible without a real Linode: `bundle exec kamal deploy --help` / `bundle exec kamal config` (or equivalent lint/dry-run commands) succeed against the filled-in (placeholder) config without a syntax or reference error; `bundle exec rubocop` and `bundle exec rake spec` still pass (existing `ci-gate` must stay green — this PR shouldn't touch app behavior other than the R6 host-allowlist and R2 seed-on-boot additions). A real end-to-end `kamal setup` against an actual Linode is the human operator's post-merge step per the issue body — the implementer cannot and should not attempt that as part of this PR.

## Acceptance Criteria

- [ ] `config/deploy.yml` defines exactly one Linode host with IP/user sourced from environment, not hardcoded (R1)
- [ ] A fresh boot (empty DB) results in a migrated **and seeded** database with no manual operator step beyond `kamal setup`/`kamal deploy` (R2)
- [ ] `accessories.postgres` is defined on the same host with a persisted data volume (R3)
- [ ] The app's `DATABASE_URL` (or equivalent) correctly targets the Postgres accessory container by Kamal's assigned hostname (R4)
- [ ] A registry is chosen and configured end-to-end (`registry:` block + `.kamal/secrets` credential reference), with the choice and CI-compatibility rationale documented if it deviates from the R5 recommendation (R5)
- [ ] `config.hosts` accepts an environment-supplied additional host/IP without code changes, while the three existing production entries are unchanged (R6)
- [ ] `docs/ops/kamal-first-deploy.md` exists and covers prerequisites, required secrets/env vars with placeholders, the first-deploy command sequence, and a verification step (R7)
- [ ] PR diff matches the R8 file list — no Terraform, CI workflow, DNS, or unrelated dependency changes
- [ ] Existing `ci-gate` (`lint` + `test`) remains green on the PR, unmodified in definition
- [ ] `.kamal/secrets` contains only environment/command references, never a literal secret value
- [ ] Spec-level "Done when" from the issue is achievable post-merge: from a clean clone + filled secrets + the operator's own Linode, `kamal setup` results in the app answering HTTP(S) on the host (verified via IP per R6; public domain remains optional at this step, deferred to #1161)

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns) and the scribe's own delegation rules:

- **Implementation** (`Gemfile`/`config/deploy.yml`/`.kamal/`/`Dockerfile`/`bin/docker-entrypoint`/`config/environments/production.rb`/`docs/ops/kamal-first-deploy.md` changes, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (moving #1160's board status, closing #1160 on merge, leaving #1148 open, any triage of #1161/#1162/#1163 sequencing): delegate to the **orchestrator** — this spec does not perform those operations.
- **The R5 registry decision**, if the implementer wants to deviate from the GHCR recommendation: a decision for the orchestrator/user, not the scribe or the code agent to make unilaterally — see [Open Questions](#open-questions).
- **Actual creation of the Linode host, first real `kamal setup` run against it, and filling real secret values**: the human operator, after merge, per the issue body's "Manual ops" section — never an ADLC agent action.

## Open Questions

1. **Registry choice (R5).** This spec recommends `ghcr.io` for forward-compatibility with #1162's future CI deploy job (GitHub Actions gets free `ghcr.io` auth via `GITHUB_TOKEN`). An alternative — Kamal's `localhost` self-hosted-registry mode (available since Kamal 2.8, no external account needed, SSH-tunneled automatically) — is simpler for a single human operator today but would need to be swapped out when #1162 wires up CI, since GitHub Actions runners can't SSH-tunnel into the operator's laptop. Confirm GHCR (or name a different final choice) with the user/orchestrator before implementation if there's a preference not captured here.
2. **`SCHEMATOGO_URL` fallback.** Should `config/database.yml`'s dead `SCHEMATOGO_URL.presence ||` fallback be removed now (small, arguably-related cleanup) or left alone until #1163 (Heroku Terraform retirement) tidies up all Heroku-specific residue at once? This spec defaults to **leaving it** (R8's "no unrelated scope") but flags it since it's a one-line, low-risk removal someone might reasonably bundle in.
3. **Seed-on-boot mechanism (R2).** This spec allows either extending `bin/docker-entrypoint` or adding a Kamal `post-deploy` hook — both satisfy the requirement. If the implementer has a strong preference (e.g. hook-based keeps `bin/docker-entrypoint` untouched and closer to Heroku's release-phase separation-of-concerns), that's fine; not treated as a hard requirement here since either is spec-compliant.
4. **`RAILS_SERVE_STATIC_FILES` / `RAILS_LOG_TO_STDOUT`.** Some Kamal+Rails tutorials set these explicitly in `env.clear`. This app's `Dockerfile` already installs a `puma`-served app with no separate static-file server configured, and `config/environments/production.rb` already logs to `$stdout` unconditionally (`config/environments/production.rb:57`), so these are likely no-ops here — but the implementer should confirm `RAILS_SERVE_STATIC_FILES` isn't needed given `config.public_file_server.enabled` is left at its Rails default (commented out, i.e. enabled) in `config/environments/production.rb:26`.

## Changelog

### Version 2 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1160
**Change Type:** Minor (amendment for user-approved shared-host facts, pre-merge)

**Changes:**
- Amended the R1/proxy implementation guidance: the previous framing left `proxy.host`/`proxy.ssl` unset/placeholder-commented pending #1161. With the shared Linode IP (`97.107.129.135`, shared with `bot.biti.dev`) and public hostname (`jamesebentier.com`) now user-confirmed, `config/deploy.yml`'s `proxy.host`/`proxy.ssl: true` are configured in this PR. #1161 remains the owner of actual DNS record (Route53/CloudFront) ownership/verification — this amendment only acknowledges that the app/proxy-side hostname config no longer needs to wait for that.
- No change to R1–R8 requirements themselves, acceptance criteria, or scope (still no DB restore, no Terraform/CI/Heroku work here).

**Impact:** `config/deploy.yml` and `docs/ops/kamal-first-deploy.md` updated to match; no requirement or acceptance-criteria text changed.

---

### Version 1 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1160
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification for a single-Linode-host Kamal baseline with a Postgres accessory, scoped strictly to the first "Ready" slice of the #1148 epic split
- Verified current app state against the repo: `config/database.yml` already URL-driven, `bin/docker-entrypoint` already runs `db:prepare` on boot (but not `db:seed`), `Dockerfile` already Kamal-shaped, `/up` health check already present, Redis/Action Cable present but unused
- Identified and specified fixes for two concrete blockers to the epic's "Done when" criterion that fall inside this issue's boundary rather than #1161's: missing seed-on-boot parity with Heroku's `release` phase (R2), and `config.hosts` blocking IP-based verification pre-DNS-cutover (R6)
- Recommended `ghcr.io` as the registry choice specifically for forward-compatibility with the not-yet-built #1162 CI deploy job, and flagged it as an open decision rather than deciding unilaterally
- Scoped a new first-deploy runbook (`docs/ops/kamal-first-deploy.md`) as a required deliverable (R7) without authoring its content here, per scribe/code division of responsibility

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the code agent.

---
