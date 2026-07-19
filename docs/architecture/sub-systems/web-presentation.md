# web-presentation

> Per-subsystem deep-dive. Linked from [`docs/architecture/overview.md`](../overview.md).

---

## Purpose

Render the public jamesebentier.com experience — landing, resume, blog, and projects — including ERB/RSS views, helpers, Stimulus controllers, Tailwind/DaisyUI assets, layout chrome (header/footer, meta-tags, analytics), and unused Rails delivery scaffolds (mailers, jobs, Action Cable).

---

## Anchor Files

- `config/routes.rb` — (outside source roots, but the entry map) root + blog/projects/resume/search-index
- `app/controllers/welcome_controller.rb` / `blog_controller.rb` / `projects_controller.rb` — thin action controllers
- `app/controllers/search_index_controller.rb` — `GET /search-index.json`; SEARCH mode's
  (#1187 R9) plain-text-fields-only JSON index (`title`/`url`/`excerpt`/`tags`/`type`)
  over `Post.published`/`Project`
- `app/views/layouts/application.html.erb` — layout, meta-tags, Font Awesome, production analytics, FOUC-prevention theme script
- `app/assets/stylesheets/application.tailwind.css` — theme/token source of truth (type scale, self-hosted fonts, DaisyUI theme set)
- `app/views/components/` — shared ERB component partials (section, card, pill, cta_button)
- `app/helpers/blog_helper.rb` — markdown rendering bridge
- `app/helpers/resume_helper.rb` — `resume/resume.yml` loader
- `app/javascript/controllers/keyboard_nav_controller.js` — modal NORMAL/COMMAND/SEARCH
  keyboard-navigation layer (site-as-terminal, #1187); mode state machine + the single
  document-level key-dispatch guard. `app/javascript/keyboard_nav/` holds this
  controller's pure ES-module helpers as later increments add them.

---

## Public Contract

- **HTTP routes**: `/`, `/resume`, `/blog`, `/blog/:slug`, `/projects`, `/projects/:slug`, `/search-index.json`, `/up`
- **Exports**: helpers `render_markdown`, `resume_data`, `style_for_level`, `social_profile_icon`
- **Component partials**: `components/section`, `components/card`, `components/pill`, `components/cta_button` (plain ERB, rendered via `render` / `render layout:`; see the partials' own header comments for the locals/block contract and the pill status→badge-role map)
- **Stimulus**: `data-controller="collapse"` toggle behavior; `data-controller="theme-picker"` (theme switch + `localStorage` persist); `data-controller="motion"` (scroll fade/slide-in, reduced-motion aware); `data-controller="keyboard-nav"` (mounted once on `<body>` — modal NORMAL/COMMAND/SEARCH keyboard layer, #1187; ships incrementally, see that controller's file header for what's live today)
- **Assets**: webpack JS bundle + Tailwind CSS build (`yarn build` / `yarn build:css`); self-hosted webfonts under `public/fonts/` (Commit Mono, Inter)

---

## Key Invariants

- Controllers stay thin: load models by slug, leave markup to views/helpers.
- Resume content is YAML at `resume/resume.yml` (rendered HTML may also be produced separately under `resume/` tooling) — not the DB.
- Production-only analytics (Metricool, Google Analytics) are gated by `Rails.env.production?` in the layout.
- Theme is client-driven: a render-blocking inline script in the layout `<head>` applies the visitor's stored choice (the `theme` `localStorage` key) to `<html data-theme>` before first paint, the `theme-picker` controller switches and persists it, and it defaults to `light` for first-time visitors. The centered `max-w-screen-lg` content column is unchanged.
- The `keyboard-nav` layer never intercepts keys in native form fields or its own COMMAND/SEARCH inputs (single generic editable-target guard, checked via `.closest()` so it also covers a native `<select>`'s own open-dropdown descendants); `Esc` always returns to NORMAL; the layer attaches no `keydown` listener on touch/no-hover-precise-pointer devices.

## Security Posture

- **Trust boundary**: Public unauthenticated HTTP. CSRF protection remains enabled for non-GET (Rails default) even though the surface is mostly read-only.
- **Sensitive data handled**: none in views; resume is public professional data from YAML.
- **Log hygiene**: filter parameter logging via Rails initializer; no PII collection forms today.
- **Encryption posture**: TLS at CloudFront/Heroku edge.
- **Known risks**: Third-party script tags (Font Awesome kit, Metricool, gtag) load in production; `render_markdown` marks HTML safe.

---

## State Owned

- None persisted. Transient view assigns (`@post`, `@project`, `@resume_data` memo).

---

## Dependencies

- **content-domain** — `Post` / `Project` lookups and `#content`
- **markdown-rendering** — `Blog::Renderer` via `BlogHelper`
- **rails-runtime** — inherits `ApplicationController`

---

## Known Limitations

- `ProjectsController#show` uses `find_by` (returns nil) while blog uses `find_by!` — inconsistent 404 behavior.
- `WelcomeController` still declares unused `projects` action (routing uses `ProjectsController`).
- Stimulus includes unused scaffold `hello_controller`.
- Capybara/Cuprite (`spec/system/`) always runs JS, so it cannot exercise the
  "full site works with JS entirely off" progressive-enhancement check (#1187 R11) —
  that check stays manual pre-merge verification, not automated coverage.

---

## Last Hardened

_none yet_

---

## Hardening History

| Date | Commit | Bugs Found | Bugs Fixed | Theatre Tests | Pyramid Migrations | Notes |
|------|--------|------------|------------|---------------|---------------------|-------|
| _none yet_ | | | | | | |

---

## Key Design Notes

- Prefer DaisyUI + Tailwind utility classes in ERB; keep Stimulus controllers small and colocated under `app/javascript/controllers/`.
- SEO: `meta-tags` gem drives title/OG/Twitter; keep `display_meta_tags` in the layout.
- RSS builders live beside HTML index views (`index.rss.builder`).
