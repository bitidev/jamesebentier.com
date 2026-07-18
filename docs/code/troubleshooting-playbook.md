# Troubleshooting Playbook

Common failures for local/CI work on jamesebentier.com.

---

## Postgres Connection Refused / Auth Failed

**Symptoms**: `PG::ConnectionBad`, boot fails in development/test.

**Causes**:
- Local Postgres not running
- Wrong `DATABASE_HOST` / user / password vs `config/database.yml` defaults

**Fix**:
1. Start Postgres locally
2. Create role/DB matching defaults, or export:
   - `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`
3. `bin/rails db:prepare`

**Prevention**: Use `bin/setup`; document personal overrides in local `.env` (not committed).

---

## Assets Missing / Unstyled Pages

**Symptoms**: No CSS/JS; 404 on `/assets/...`.

**Causes**: Webpack/Tailwind builds not run; empty `app/assets/builds`.

**Fix**:
```bash
yarn install
yarn build
yarn build:css
# or: bin/dev / Procfile.dev watchers
```

**Prevention**: CI runs `assets:precompile` before specs — mirror that locally after dependency changes.

---

## Blog Post 404 / Empty Content

**Symptoms**: `/blog/:slug` not found, or show page with blank body.

**Causes**:
- Seeds not run after adding markdown
- Slug casing mismatch
- `file_path` points at missing file under `public/blog`

**Fix**:
1. Confirm file exists: `public/blog/<file>.md` with YAML front matter including `slug`
2. `bin/rails db:seed`
3. Hit `/blog/<slug>` with downcased slug

**Prevention**: Add post markdown + seed in the same change; assert factory `file_path` in specs when relevant.

---

## RuboCop / Danger Failures on PR

**Symptoms**: Danger comments with new RuboCop offenses.

**Causes**: Style violations in changed lines (docs: `Dangerfile` → `only_report_new_offenses`).

**Fix**: `bundle exec rubocop -A` on touched files; respect Max 150 line length and frozen-string-literal.

**Prevention**: Run RuboCop locally before push; don't fight disabled cops (`Style/StringLiterals`).

---

## Spec Suite Fails on Clean Checkout

**Symptoms**: Pending migration abort; factory uniqueness errors.

**Causes**:
- Migrations not applied
- Spec expects existing row (`before { create(:post) }`) colliding without cleaning

**Fix**:
```bash
RAILS_ENV=test bundle exec rake db:prepare
bundle exec rake spec
```

DatabaseCleaner is configured in `rails_helper` — if disabled, restore the around hook.

---

## Production Host Links Wrong in Local Email/URL Helpers

**Symptoms**: Generated URLs point at `jamesebentier.com` unexpectedly (or not in production).

**Causes**: `ApplicationController#default_url_options` sets host only when `Rails.env.production?`.

**Fix**: Use correct `RAILS_ENV`; for mailer previews set `default_url_options` in the environment config if needed.

---

## Terraform / Deploy Confusion

**Symptoms**: DNS/CDN changes unclear; unsure where app runs.

**Causes**: Infra lives in `terraform/` (Heroku, CloudFront, Route53, cert-manager) separate from Rails code.

**Fix**: Read `terraform/*.tf` and apply via normal Terraform workflow with local `*.tfvars` (gitignored). Don't put secrets in committed TF files.

---

## ADLC Agents Missing Project Rules

**Symptoms**: Agents don't follow worktree/orchestrator rules.

**Causes**: Missing `CLAUDE.md` import or `.cursor/rules/adlc-rules.mdc`.

**Fix**: Ensure root `CLAUDE.md` contains `@adlc/methods/session-rules.md` and Cursor rule exists; confirm `adlc/` symlink resolves (`ls -la adlc`).

**Prevention**: Re-run `/adlc-init verify` after bootstrap changes.
