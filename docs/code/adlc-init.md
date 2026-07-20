# docs/code/adlc-init.md

---
**Last Updated**: 2026-07-20
**Init Version**: 1.0
**Codebase Commit**: c2f4c3645fba66bfa9819cc5f303570d697024e5
**Status**: Current
---

## Project Overview

**Architecture Pattern**: Rails MVC (Hotwire) personal marketing site
**Primary Language(s)**: Ruby 3.3 / Rails 8.1; JavaScript (Stimulus) for progressive enhancement
**Key Frameworks**: Rails 8.1, Hotwire (Turbo + Stimulus), Tailwind CSS 4 + DaisyUI 5, Redcarpet

### Purpose

Personal website for James Ebentier (`jamesebentier.com`): landing page, resume, blog (markdown files under `public/blog`), and project portfolio. Deployed via Heroku + CloudFront (Terraform under `terraform/`).

### Key Architectural Principles

- Thin controllers; content metadata in ActiveRecord; bodies in markdown files under `public/`
- Schema declared on models via `declare_schema` (UUID PKs)
- Presentation via ERB + Tailwind/DaisyUI; Stimulus only for small UI behaviors
- Public, unauthenticated surface — no app-level auth

---

## Technology Stack

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| Runtime | Ruby | ~> 3.3 (`.ruby-version` 3.3.1) | Rails 8.1 / modern language features |
| Framework | Rails | ~> 8.1.3 (locked 8.1.3) | Full-stack MVC with Hotwire |
| Database | PostgreSQL | 16 in CI (`pg` gem) | UUID support; production via `DATABASE_URL` / `SCHEMATOGO_URL` |
| Cache / Cable | Redis | >= 4.0.1 | Action Cable adapter in production |
| Web server | Puma | >= 5.0 | Rails default |
| CSS | Tailwind 4.3 + DaisyUI 5.6 + cssbundling | yarn scripts | Utility-first theming |
| JS | Stimulus 3 + Turbo 8 + webpack 5 | jsbundling-rails | Modest interactivity, no SPA |
| Markdown | Redcarpet + custom `Blog::Renderer` | — | Blog/project body rendering |
| Schema | declare_schema | — | Model-declared schema + migrations |
| SEO | meta-tags, sitemap_generator | — | OG/Twitter tags + auto sitemap |
| HTTP client | Faraday (+ multipart, retry) | — | Available for outbound calls |
| Test | RSpec + FactoryBot + Shoulda + DatabaseCleaner | — | Model/request specs |
| Lint | RuboCop (+ rails/rspec/performance/factory_bot) | TargetRubyVersion 3.3 | Line length 150 |
| Infra | Terraform (Heroku, CloudFront, Route53, cert-manager) | — | DNS/CDN/app hosting |
| Node | Yarn 4.3 / nvm `lts/iron` | — | Asset builds |

### Key Dependencies

- **declare_schema**: Source of truth for `Post`/`Project` columns and validations
- **redcarpet** + `lib/blog/renderer.rb`: Markdown → Tailwind-styled HTML
- **meta-tags**: Central SEO tags in the application layout
- **sitemap_generator**: Reflects on models/controllers, honors `noindex?`
- **font-awesome-sass** + FA kit script: Social/brand icons

---

## Architecture

### Component Organization

```
jamesebentier.com/
├── app/
│   ├── controllers/     # Thin HTTP handlers (web-presentation + rails-runtime base)
│   ├── models/          # Post, Project (content-domain)
│   ├── views/           # ERB + RSS builders
│   ├── helpers/         # Markdown, resume, social icons
│   ├── javascript/      # Stimulus controllers
│   └── assets/          # Tailwind entry + images
├── lib/blog/            # Blog::Renderer (markdown-rendering)
├── public/blog/         # Markdown posts (YAML front matter + body)
├── public/projects/     # Optional project detail markdown
├── resume/              # resume.yml + PDF render tooling
├── db/                  # Migrations, schema, seeds
├── spec/                # RSpec (not a source root)
├── terraform/           # Heroku / CloudFront / DNS
└── docs/                # ADLC agent knowledge (this tree)
```

**Convention**: Presentation may import domain models and `Blog::Renderer`; models must not import controllers/helpers. See `docs/architecture/overview.md`.

### Data Flow

1. Request hits routes (`config/routes.rb`) → controller in web-presentation
2. Controller loads `Post`/`Project` by slug (content-domain) or resume YAML (helper)
3. View calls `render_markdown` → `Blog::Renderer` (markdown-rendering)
4. Layout wraps with meta-tags / header / footer; production analytics scripts
5. Response returned; RSS variants use `.rss.builder` alongside HTML indexes

### Service Boundaries

Single Rails monolith. Out-of-process concerns:

- **Postgres** — content metadata
- **Redis** — Action Cable (scaffold-level)
- **Heroku + CloudFront** — deploy/CDN (Terraform)
- **External analytics** — Metricool + Google Analytics (production layout only)

---

## Code Organization Conventions

### Naming Conventions

**Files**:
- Ruby: `snake_case.rb` (`blog_controller.rb`, `post.rb`)
- ERB: `action.html.erb`, partials `_name.html.erb`
- Stimulus: `snake_case_controller.js` → `data-controller="snake-case"`
- Specs: `*_spec.rb` mirroring app paths under `spec/`

**Ruby**:
- Classes/modules: `PascalCase`
- Methods/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Files start with `# frozen_string_literal: true`

### Module Organization

- One public model/controller class per file
- Helpers namespaced by feature (`BlogHelper`, `ResumeHelper`)
- Library code under `lib/<feature>/` (autoload via Rails)

---

## Common Patterns

See `docs/code/patterns.md` for DO/DON'T detail. Highlights:

- **declare_schema** on models for columns + validations
- Slug lookups (`find_by!(slug: params[:slug].downcase)`)
- Markdown bodies on disk; DB holds metadata
- Idempotent seeds via `find_or_initialize_by(...).update!`
- RuboCop `Style/Documentation` often disabled on small classes

---

## Anti-Patterns to Avoid

See `docs/code/anti-patterns.md`. Critical:

- Don't put markdown bodies in the DB — keep files under `public/`
- Don't add auth/admin UI without a deliberate subsystem plan
- Don't render untrusted markdown with `.html_safe`
- Don't bypass `declare_schema` for ad-hoc schema drift

---

## Integration Patterns

| Integration | Pattern |
|-------------|---------|
| Blog markdown | `public/blog/*.md` → seed into `Post` → `Post#content` → `BlogHelper#render_markdown` |
| Project markdown | optional `public/projects/{slug}.md` via `Project#content` |
| Resume | `resume/resume.yml` via `ResumeHelper#resume_data` |
| Sitemap | `config/sitemap.rb` reflection + `noindex?` |
| Faraday | Present in Gemfile; no first-class client wrapper yet |
| Production DB | `SCHEMATOGO_URL` or `DATABASE_URL` |

---

## Configuration Management

- Secrets: Rails credentials (`config/master.key` gitignored); env vars for DB host/user/pass
- `.env.sample` documents ADLC/`gh` setup; copy to `.env` locally (gitignored)
- Dev DB defaults in `config/database.yml` for local Postgres role `james_ebentier_development`
- `bin/setup` → bundle, yarn, `db:prepare`
- `bin/dev` / Procfiles for web + asset watchers

---

## Testing Strategy

- **Framework**: RSpec Rails; `spec/rails_helper.rb` uses DatabaseCleaner around examples
- **Factories**: FactoryBot under `spec/factories/`
- **Matchers**: Shoulda for DB columns/validations (see `spec/models/post_spec.rb`)
- **Types**: Model specs + request specs (`spec/requests/`); no system tests yet
- **CI**: `.github/workflows/ci.yml` — Danger + Test (Postgres service, yarn, assets:precompile, `rake spec`)
- Run: `bundle exec rake spec`

---

## Git Workflow and Team Conventions

- Default branch: `main`
- Recent history heavily Dependabot version bumps
- ADLC issue branches: `personal/<username>/issue-<NUMBER>-<description>` (see ADLC orchestrator git integration)
- PRs: Danger runs RuboCop on new offenses only (`Dangerfile`)
- Commits: conventional short summaries from Dependabot (`Bump X from A to B (#PR)`)

---

## Troubleshooting Playbook

See `docs/code/troubleshooting-playbook.md` for symptoms → fixes.

---

## Decision Rationale and Trade-offs

| Decision | Why | Trade-off |
|----------|-----|-----------|
| Markdown on disk, metadata in DB | Easy authoring/git history for posts; queryable metadata | Seeds must stay in sync with `public/blog` |
| declare_schema | Single place for columns + validations | Team must know the gem's migration workflow |
| Hotwire not SPA | Simple public site; minimal JS | Richer interactive apps would need more Stimulus/Turbo work |
| DaisyUI + light theme | Fast styled UI | Theme coupling in markup |
| Terraform for infra | Reproducible Heroku/CDN/DNS | Infra changes need TF familiarity |
| Public repo under `bitidev` | Open portfolio/site source | Careful with secrets (master.key, .env ignored) |

---

## Subsystem Map

Authoritative boundaries: [`docs/architecture/overview.md`](../architecture/overview.md)

| Subsystem | Role |
|-----------|------|
| rails-runtime | `ApplicationController` + lib keepfiles |
| content-domain | `Post` / `Project` / `ApplicationRecord` |
| markdown-rendering | `Blog::Renderer` |
| web-presentation | Controllers, views, helpers, assets, JS, mailers/jobs/cable scaffolds |
