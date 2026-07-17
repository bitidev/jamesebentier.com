# Kamal First Deploy (Linode)

Operator runbook for the first Kamal deploy of this app to a human-provisioned Linode
host. Covers [#1160](https://github.com/bitidev/jamesebentier.com/issues/1160)'s scope
only: a working, fresh-database app answering HTTP on the host's bare IP. Public DNS
cutover is [#1161](https://github.com/bitidev/jamesebentier.com/issues/1161); a CI deploy
job is [#1162](https://github.com/bitidev/jamesebentier.com/issues/1162); Heroku
teardown is [#1163](https://github.com/bitidev/jamesebentier.com/issues/1163). None of
that is done here.

## Prerequisites (assumed already true)

- A Linode instance exists and is reachable over SSH as some user (root or otherwise).
  Creating the Linode and setting up that SSH user is **not** part of this runbook — the
  human operator does this out-of-band.
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
KAMAL_HOST=203.0.113.10          # the Linode's IP address
KAMAL_SSH_USER=root              # whatever SSH user your Linode setup created
KAMAL_REGISTRY_USERNAME=your-github-username-or-org
ADDITIONAL_ALLOWED_HOSTS=203.0.113.10   # same IP, so Rails answers on it pre-DNS-cutover
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
repo root:

```bash
bundle exec kamal setup
```

`kamal setup` provisions the host (installs Docker if needed), boots the `postgres`
accessory, and deploys the app — all in one command, no manual `kamal app exec` step
required. `bin/docker-entrypoint` runs `db:prepare` (creates + migrates a fresh schema)
and `db:seed` (loads the real blog/projects content) automatically on every app boot, so
the first boot already serves real content.

If you ever need to run these steps individually (e.g. after changing the Postgres
image/version):

```bash
bundle exec kamal accessory boot postgres
bundle exec kamal deploy
```

## 4. Verify success

```bash
curl -i http://<KAMAL_HOST>/up            # expect HTTP 200 (Rails health check)
curl -i http://<KAMAL_HOST>/              # expect HTTP 200 and the real homepage
```

Or open `http://<KAMAL_HOST>/` in a browser. This works pre-DNS-cutover because
`ADDITIONAL_ALLOWED_HOSTS` (set above) is appended to Rails' `config.hosts` allowlist in
`config/environments/production.rb`, alongside the app's normal domain entries — see R6
in the [spec](../specs/1160-kamal-baseline-postgres-accessory.md#r6--confighosts-allows-ip-based-verification-pre-dns-cutover).
A public domain is optional at this step; that's [#1161](https://github.com/bitidev/jamesebentier.com/issues/1161)'s job.

## Notes

- This deploy is **fresh-database only** — no data is restored or imported from Heroku.
  `accessories.postgres` in `config/deploy.yml` persists its data in a named `data`
  volume across accessory restarts, but there is nothing in it until this first deploy
  seeds it.
- No TLS/SSL is configured yet (`proxy.ssl`/`proxy.host` are commented out in
  `config/deploy.yml`) since no domain resolves to this host until #1161. HTTP-only is
  expected and fine for this step.
- Subsequent deploys are just `bundle exec kamal deploy` once the above is set up once.
