# Kamal First Deploy (Linode)

Operator runbook for the first Kamal deploy of this app to a human-provisioned Linode
host. Covers [#1160](https://github.com/bitidev/jamesebentier.com/issues/1160)'s scope
only: a working, fresh-database app answering on the host (verifiable via its bare IP
regardless of DNS state, per [R6](../specs/1160-kamal-baseline-postgres-accessory.md#r6--confighosts-allows-ip-based-verification-pre-dns-cutover)),
with Kamal's proxy already configured for the app's public hostname,
`jamesebentier.com`. Whether the `jamesebentier.com` DNS record actually points at this
host yet, plus Route53/CloudFront ownership of that record, is
[#1161](https://github.com/bitidev/jamesebentier.com/issues/1161)'s job; a CI deploy job
is [#1162](https://github.com/bitidev/jamesebentier.com/issues/1162); Heroku teardown is
[#1163](https://github.com/bitidev/jamesebentier.com/issues/1163). None of that is done
here.

## Shared host

The target Linode (`97.107.129.135`) is **shared** with `bot.biti.dev`, an unrelated app
already running on it. Treat this as a multi-tenant box, not a dedicated one:

- Do not run a blind `kamal setup` as the default path (see [§3](#3-first-deploy)) — it
  can reconfigure/restart the host's Docker daemon and proxy in ways that disrupt the
  other app if Docker or Kamal's proxy container is already present from that app's own
  setup.
- Prefer booting the Postgres accessory and deploying the app as separate steps
  (`kamal accessory boot postgres` + `kamal deploy`) so nothing touches shared
  host-level state (Docker install, proxy container) that `bot.biti.dev` already
  depends on.
- Coordinate before running anything host-provisioning-shaped (`kamal setup`,
  `kamal server bootstrap`) against this host, since that's exactly the class of command
  that isn't scoped to just this app's containers.

## Prerequisites (assumed already true)

- A Linode instance exists and is reachable over SSH as some user (root or otherwise).
  Creating the Linode and setting up that SSH user is **not** part of this runbook — the
  human operator does this out-of-band. This particular instance already runs
  `bot.biti.dev` — see [Shared host](#shared-host) above.
- Local machine has this repo cloned, Ruby installed per `.ruby-version`, and
  `bundle install` has been run (installs the `kamal` gem, dev/test-only).
- Local Docker is running (Kamal builds the app image via Docker), unless using the
  remote/SSH builder option noted below.
- A GitHub Container Registry (`ghcr.io`) account/org with permission to push packages
  for this repo (`bitidev`), and a classic Personal Access Token with the
  `write:packages` scope.

## 1. Fill in environment variables and secrets

Kamal reads `config/deploy.yml` and `.kamal/secrets` via `dotenv`/ERB. The simplest setup
is a git-ignored `.env` file in the repo root (already covered by this repo's
`.gitignore` — `.env*` is ignored). Create one with:

```bash
# .env — local only, never committed
KAMAL_HOST=97.107.129.135        # the shared Linode's IP (also runs bot.biti.dev)
KAMAL_SSH_USER=root              # whatever SSH user your Linode setup created
KAMAL_REGISTRY_USERNAME=your-github-username-or-org
ADDITIONAL_ALLOWED_HOSTS=jamesebentier.com,97.107.129.135   # domain + bare IP, so Rails
                                                             # answers on either pre-DNS-cutover
```

`.kamal/secrets` (committed, contains **only** variable/command references — never a
real value) pulls the following from your shell/`.env`/password manager. Set these as
real environment variables before running any `kamal` command (a `.env` loaded by your
shell, e.g. via `direnv`, or exported manually — `.kamal/secrets` itself only ever
references `$VAR`, it does not define the value):

| Variable | Where it comes from | Example / placeholder |
|---|---|---|
| `KAMAL_REGISTRY_PASSWORD` | GitHub PAT (classic, `write:packages` scope) | `ghp_xxxxxxxxxxxxxxxxxxxx` |
| `RAILS_MASTER_KEY` | Read from `config/master.key` (not committed) — set up via `bin/rails credentials:edit` if you don't have one, or copy the value used for the Heroku deploy | `config/master.key` file must exist locally |
| `POSTGRES_PASSWORD` | Pick a strong password for the Postgres accessory | `use a password manager to generate one` |

`RAILS_MASTER_KEY` and `POSTGRES_PASSWORD` should live in your own password manager
long-term; a local `.env` is fine for the duration of running these commands, but treat
it the same as any other secrets file — never commit it (already git-ignored by
`/.env*` in `.gitignore`).

`DATABASE_URL` is derived automatically inside `.kamal/secrets` from `POSTGRES_PASSWORD`
(username/database are fixed, non-secret values in `config/deploy.yml`) — you don't need
to set it separately.

## 2. Architecture note (builder)

`config/deploy.yml`'s `builder.arch` is set to `amd64` (matches typical Linode plans). If
your local machine is a different architecture (e.g. Apple Silicon `arm64`), either:

- Ensure Docker Desktop's `buildx` is set up for cross-compilation (default on recent
  Docker Desktop installs — no action needed for most users), or
- Add `remote: ssh://<user>@<host>` under `builder:` in `config/deploy.yml` to build the
  image directly on the target host over SSH instead of cross-compiling locally.

## 3. First deploy

With the environment variables above exported and `.kamal/secrets` resolvable, from the
repo root, boot the Postgres accessory and deploy the app as two separate steps:

```bash
bundle exec kamal accessory boot postgres
bundle exec kamal deploy
```

This is the **preferred** sequence on this shared host: it only touches this app's own
containers (the `postgres` accessory and the app itself) and doesn't re-run
host-provisioning steps that `kamal setup` would (installing/reconfiguring Docker,
booting Kamal's proxy container) — steps that `bot.biti.dev`'s own Kamal setup on this
same host already covers, and re-running them blind risks disrupting it. `kamal deploy`
reuses an already-running proxy container if one exists and adds this app's routing to
it; it does not require the proxy to be freshly booted by this app.

`bin/docker-entrypoint` runs `db:prepare` (creates + migrates a fresh schema) and
`db:seed` (loads the real blog/projects content) automatically on every app boot, so the
first boot already serves real content — no manual `kamal app exec` step required.

`kamal setup` (which runs both of the above plus host bootstrapping/proxy boot in one
command) is Kamal's normal first-deploy path, but do **not** run it blind against this
host — see [Shared host](#shared-host). If Docker or Kamal's proxy is confirmed *not*
already present (e.g. this is genuinely the first Kamal app on the box), `kamal setup`
is fine; otherwise use the two-step sequence above.

## 4. Verify success

```bash
curl -i http://97.107.129.135/up          # expect HTTP 200 (Rails health check), bare IP
curl -i https://jamesebentier.com/up      # expect HTTP 200 once DNS/cert are live
curl -i https://jamesebentier.com/        # expect HTTP 200 and the real homepage
```

Or open `https://jamesebentier.com/` in a browser once DNS resolves there and Kamal's
proxy has issued its Let's Encrypt certificate (`proxy.host`/`proxy.ssl` in
`config/deploy.yml`). The bare-IP `curl` above works even before/without DNS pointing
here, because `ADDITIONAL_ALLOWED_HOSTS` (set
above) is appended to Rails' `config.hosts` allowlist in
`config/environments/production.rb`, alongside the app's normal domain entries — see R6
in the [spec](../specs/1160-kamal-baseline-postgres-accessory.md#r6--confighosts-allows-ip-based-verification-pre-dns-cutover).
Whether the `jamesebentier.com` DNS record already points at this host, or still needs
pointing/verifying, is [#1161](https://github.com/bitidev/jamesebentier.com/issues/1161)'s
job — this runbook only configures the app/proxy side.

## Notes

- This deploy is **fresh-database only** — no data is restored or imported from Heroku.
  `accessories.postgres` in `config/deploy.yml` persists its data in a named `data`
  volume across accessory restarts, but there is nothing in it until this first deploy
  seeds it.
- `proxy.host`/`proxy.ssl` in `config/deploy.yml` are set to `jamesebentier.com` /
  `true` since the domain and host are both known — Kamal's proxy will request a Let's
  Encrypt certificate for that hostname and route HTTPS traffic to the app. Actual DNS
  record ownership/verification for `jamesebentier.com` pointing at `97.107.129.135` is
  still [#1161](https://github.com/bitidev/jamesebentier.com/issues/1161)'s job; until
  that DNS record resolves here, use the bare-IP `curl` in [§4](#4-verify-success) to
  verify.
- Subsequent deploys are just `bundle exec kamal deploy` once the above is set up once.
- This host is shared with `bot.biti.dev` — re-read [Shared host](#shared-host) before
  running anything beyond `kamal deploy`/`kamal accessory boot postgres`.
