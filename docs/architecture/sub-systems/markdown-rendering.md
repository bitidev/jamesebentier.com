# markdown-rendering

> Per-subsystem deep-dive. Linked from [`docs/architecture/overview.md`](../overview.md).

---

## Purpose

Convert markdown strings into HTML with Tailwind-friendly class names for headers, paragraphs, and lists, used by blog (and project) presentation helpers.

---

## Anchor Files

- `lib/blog/renderer.rb` — `Blog::Renderer < Redcarpet::Render::HTML`

---

## Public Contract

- **Exports**: `Blog::Renderer` — pass to `Redcarpet::Markdown.new(Blog::Renderer, autolink: true, tables: true)`
- **Behavior**: Headers are rendered one level deeper (`h1` markdown → `h2` HTML) with mapped Tailwind classes

---

## Key Invariants

- Renderer is pure: input markdown/text → HTML string; no AR or controller dependencies.
- Header class map is frozen (`HEADER_LEVEL_CLASSES`).

## Security Posture

- **Trust boundary**: Author-controlled markdown. Output is marked `html_safe` by callers — XSS risk if untrusted input is ever rendered.
- **Sensitive data handled**: none.
- **Log hygiene**: none.
- **Encryption posture**: n/a.
- **Known risks**: `BlogHelper#render_markdown` uses `.html_safe` (rubocop disabled). Treat blog markdown as trusted author content only; never pipe arbitrary user input through this path without sanitization.

---

## State Owned

- None.

---

## Dependencies

- None (Redcarpet gem only).

---

## Known Limitations

- Limited element coverage (header, paragraph, list) — other markdown elements get Redcarpet defaults without Tailwind classes.
- Header level offset (+1) is intentional for nesting under page `h1` but surprising if reused outside blog context.

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

- Call site is `BlogHelper#render_markdown` in web-presentation; keep require path `require 'blog/renderer'`.
- Prefer extending `Blog::Renderer` methods over sprinkling presentation logic into models.
