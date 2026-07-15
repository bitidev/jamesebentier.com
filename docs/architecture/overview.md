# Architecture Overview

> **Authoritative boundary record for this project.** Every source file under this project's **source root(s)** belongs to exactly one subsystem listed here. Every cross-subsystem import must follow the dependency graph below. Orphan files and undeclared imports block merge.
>
> Reference: [`subsystem-architecture.md`](../../adlc/methods/universal/subsystem-architecture.md) for the conceptual model, and [Universal Rule 8](../../adlc/methods/universal-agent-rules.md) for the binding rules.

This document is maintained by:
- **Scribe** owns the structure (subsystem list order, catalog format, dependency-graph syntax).
- **Code** updates the catalog on every file add/move/delete in the same commit.
- **Architect** updates the subsystem list and dependency graph when a plan introduces or rearranges boundaries.
- **Reviewer** verifies orphan-free state and graph fidelity at PR time.

---

## Source Roots

- `app/` — Rails application code (controllers, models, views, helpers, JS, assets, mailers, jobs, channels)
- `lib/` — application libraries (markdown renderer; Rails `lib/tasks` / `lib/assets` keepfiles)

> Tests live under `spec/` — the test directory is **not** a source root. Config, `db/`, `bin/`, `resume/`, and `terraform/` are also outside this catalog.

The orphan check is `git ls-files app lib`.

---

## Subsystems

1. **rails-runtime** — Shared Rails base controllers/jobs/mailers/cable and sitemap opt-out hooks. See [`sub-systems/rails-runtime.md`](./sub-systems/rails-runtime.md).
2. **content-domain** — ActiveRecord models for blog posts and projects (schema, validations, scopes, content file resolution). See [`sub-systems/content-domain.md`](./sub-systems/content-domain.md).
3. **markdown-rendering** — Redcarpet HTML renderer that applies Tailwind class styling to blog/project markdown. See [`sub-systems/markdown-rendering.md`](./sub-systems/markdown-rendering.md).
4. **web-presentation** — Controllers, views, helpers, Stimulus, Tailwind assets, and page chrome for the public site. See [`sub-systems/web-presentation.md`](./sub-systems/web-presentation.md).

---

## Dependency Graph

```mermaid
graph TD
  WP[web-presentation]
  CD[content-domain]
  MR[markdown-rendering]
  RR[rails-runtime]

  WP --> CD
  WP --> MR
  WP --> RR
```

**How to read this graph**: an edge `A --> B` means "subsystem A may import from subsystem B's public contract." The reverse direction is NOT permitted unless a reverse edge is also drawn.

**How to extend**:
- New subsystem? Add a node.
- New cross-subsystem import? Add an edge — but first justify it in the architect's plan.
- Cycles are bugs. The graph must remain a DAG.

---

## Source File Catalog (One-to-One Subsystem Mapping)

Every file under `app/` and `lib/` appears here exactly once. Reviewers grep this list against `git ls-files app lib` to detect orphans. Catalog seed: **49** tracked files (`git ls-files app lib | wc -l`).

### rails-runtime

- `app/controllers/application_controller.rb` — Base controller; production host URL options; class-level `noindex`
- `lib/assets/.keep` — Rails lib/assets keepfile
- `lib/tasks/.keep` — Rails lib/tasks keepfile

### content-domain

- `app/models/application_record.rb` — ActiveRecord base; model-level `noindex` for sitemap
- `app/models/post.rb` — Blog post metadata + markdown file content loader
- `app/models/project.rb` — Project portfolio record + optional markdown detail loader
- `app/models/concerns/.keep` — Concerns directory keepfile

### markdown-rendering

- `lib/blog/renderer.rb` — `Blog::Renderer` Redcarpet HTML renderer with header/paragraph/list Tailwind classes

### web-presentation

- `app/controllers/blog_controller.rb` — Blog index/show
- `app/controllers/projects_controller.rb` — Projects index/show
- `app/controllers/welcome_controller.rb` — Landing + resume
- `app/controllers/concerns/.keep` — Concerns directory keepfile
- `app/helpers/application_helper.rb` — Social icon helpers
- `app/helpers/blog_helper.rb` — `render_markdown` via `Blog::Renderer`
- `app/helpers/resume_helper.rb` — Resume YAML load + skill-level CSS
- `app/helpers/welcome_helper.rb` — Welcome helper module (empty)
- `app/javascript/application.js` — JS entry
- `app/javascript/controllers/application.js` — Stimulus application
- `app/javascript/controllers/collapse_controller.js` — Collapse toggle Stimulus controller
- `app/javascript/controllers/hello_controller.js` — Scaffold Stimulus controller
- `app/javascript/controllers/index.js` — Stimulus controller index
- `app/jobs/application_job.rb` — Base Active Job (scaffold)
- `app/mailers/application_mailer.rb` — Base mailer (scaffold)
- `app/channels/application_cable/channel.rb` — Action Cable channel base
- `app/channels/application_cable/connection.rb` — Action Cable connection base
- `app/assets/builds/.keep` — Built assets keepfile
- `app/assets/config/manifest.js` — Sprockets/jsbundling manifest
- `app/assets/images/.keep` — Images keepfile
- `app/assets/images/landing-image.webp` — Landing hero image
- `app/assets/stylesheets/application.tailwind.css` — Tailwind entry CSS
- `app/views/layouts/application.html.erb` — Main HTML layout (meta-tags, analytics)
- `app/views/layouts/components/_header.html.erb` — Site header
- `app/views/layouts/components/_footer.html.erb` — Site footer
- `app/views/layouts/mailer.html.erb` — HTML mailer layout
- `app/views/layouts/mailer.text.erb` — Text mailer layout
- `app/views/blog/index.html.erb` — Blog listing
- `app/views/blog/index.rss.builder` — Blog RSS
- `app/views/blog/show.html.erb` — Blog post detail
- `app/views/projects/index.html.erb` — Projects listing
- `app/views/projects/index.rss.builder` — Projects RSS
- `app/views/projects/show.html.erb` — Project detail
- `app/views/welcome/index.html.erb` — Landing page
- `app/views/welcome/resume.html.erb` — Resume page shell
- `app/views/welcome/resume/_education.html.erb` — Resume education partial
- `app/views/welcome/resume/_header.html.erb` — Resume header partial
- `app/views/welcome/resume/_languages.html.erb` — Resume languages partial
- `app/views/welcome/resume/_main_summary.html.erb` — Resume summary partial
- `app/views/welcome/resume/_skills.html.erb` — Resume skills partial
- `app/views/welcome/resume/_work_experience.html.erb` — Resume work experience partial

---

## Ownership Counts

| Subsystem | File count |
|-----------|------------|
| rails-runtime | 3 |
| content-domain | 4 |
| markdown-rendering | 1 |
| web-presentation | 41 |
| **Total** | **49** |

Must equal `git ls-files app lib | wc -l`.
