# Conventions

Team and project conventions for jamesebentier.com.

---

## Language Standards

Agents that write or review code (**builder**, **test**, **reviewer**) must apply these ADLC language best-practice guides, copied into `docs/code/` alongside the project docs:

1. [`universal.md`](universal.md) — always
2. [`ruby.md`](ruby.md) — Ruby code
3. [`rails.md`](rails.md) — Rails-specific code
4. [`typescript-javascript.md`](typescript-javascript.md) — Stimulus JS under `app/javascript/`

Selection source: [`universal.md` — How Agents Select the Right File](universal.md#how-agents-select-the-right-file) (Rails app → `ruby.md` + `rails.md`).

---

## Ruby / Rails Style

| Convention | Detail |
|------------|--------|
| Frozen string literal | Every Ruby file starts with `# frozen_string_literal: true` |
| RuboCop | TargetRubyVersion 3.3; Max line length 150; migrations excluded |
| Documentation cops | Often disabled inline on small classes (`Style/Documentation`) |
| String literals | `Style/StringLiterals` disabled — single or double quotes both OK |
| Controllers | Thin; instance vars for views; inherit `ApplicationController` |
| Models | `declare_schema` blocks; UUID PKs; validations in schema DSL |

---

## Frontend

| Convention | Detail |
|------------|--------|
| CSS | Tailwind utilities + DaisyUI components; entry `application.tailwind.css` |
| Theme | `data-theme='light'` on `<html>` |
| Layout | Centered `max-w-screen-lg` content column |
| JS | Stimulus controllers under `app/javascript/controllers/` |
| Builds | `yarn build` (webpack), `yarn build:css` (tailwindcli) |
| Icons | Font Awesome (kit in layout + `font-awesome-sass` / helper classes) |

---

## Naming

- Routes use plural resource names (`blog`, `projects`) with slug params
- Route helpers: `posts_path`, `post_path`, `projects_path`, `project_path`, `resume_path`
- Factories mirror model names under `spec/factories/`
- Partials: leading underscore, feature folders under views

---

## Git / PR Workflow

- Base branch: `main`
- Issue work (ADLC): `personal/<username>/issue-<NUMBER>-<short-description>`
- PRs should include `Closes #<NUMBER>` when finishing an issue
- Danger enforces RuboCop on **new** offenses only
- Prefer small, reviewable PRs while building ADLC trust (`docs/strategic-priorities.md`)

---

## Testing Conventions

- `require 'rails_helper'` at top of model/request specs
- FactoryBot + Faker for fixtures; create minimally in `before` when uniqueness requires a row
- Prefer Shoulda for column/validation lockstep with schema
- Request specs for HTTP surface (`spec/requests/`)
- Run suite: `bundle exec rake spec` (CI also precompiles assets)

---

## Configuration

- Never commit `.env`, `config/master.key`, Terraform `*.tfvars`, or `resume/resume.json` / `resume/dist/`
- Use env vars for DB in CI (`DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`)
- Production DB URL: `SCHEMATOGO_URL` or `DATABASE_URL`

---

## Subsystem Boundaries

Every new file under `app/` or `lib/` must be added to exactly one subsystem catalog in `docs/architecture/overview.md` in the same commit. Cross-subsystem imports must follow the dependency graph (web-presentation → content-domain, markdown-rendering, rails-runtime).

---

## Comments

- Prefer "why" comments; models already carry brief purpose comments
- Avoid commented-out code — use git history
