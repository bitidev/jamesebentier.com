# content-domain

> Per-subsystem deep-dive. Linked from [`docs/architecture/overview.md`](../overview.md).

---

## Purpose

Own blog and project content metadata in Postgres (via `declare_schema`) and resolve associated markdown bodies from `public/` on demand. This is the only subsystem that defines ActiveRecord models for site content.

---

## Anchor Files

- `app/models/post.rb` — Blog post schema, validations, `published` scope, markdown body via `file_path`
- `app/models/project.rb` — Project schema, status enum (`Pre-Launch`/`Beta`/`Live`), optional `public/projects/{slug}.md`
- `app/models/application_record.rb` — AR base + model-level `noindex?`

---

## Public Contract

- **Exports**: `Post`, `Project`, `ApplicationRecord`
- **Exports**: `Post#content` / `Project#content` — markdown body strings for rendering
- **Exports**: `Post.published` — scope filtering `published_at <= now`
- **Exports**: `Post.featured` / `Project.featured` — scopes filtering `featured: true`
- **Exports**: `Post.for_home` / `Project.for_home` — curated-first/chronological-fallback
  query powering the home page's Latest Writing / Featured Projects sections (see Key
  Invariants)
- **Exports**: `Project.by_status` — scope filtering by `status`, blank returns all, an
  unrecognized value returns none; powers `/projects`' server-rendered status filter.
  `Project::STATUSES` (`%w[Pre-Launch Beta Live]`) is the shared status-values constant
  referenced by both this scope's callers and the model's own inclusion validation.
- **Exports**: `ApplicationRecord.noindex?` — sitemap opt-out
- **Types**: UUID primary keys (`gen_random_uuid()`)

---

## Key Invariants

- Schema and validations are declared inline via `declare_schema` on the model — not hand-edited in migrations as the source of truth for new columns.
- Post slugs are downcased before validation; uniqueness is case-insensitive.
- Project `status` is constrained to `Pre-Launch`, `Beta`, or `Live`.
- Post markdown lives at `Rails.public_path.join('blog', file_path)`; front-matter is stripped after the second `---` delimiter.
- Project markdown is optional at `public/projects/{slug}.md`; missing files yield `_Project Details Coming Soon_`.
- `for_home(limit: 3)` is curated-first, chronological-fallback: if any `featured: true`
  rows exist, return up to `limit` of them (newest first); otherwise return up to `limit`
  of the most recent records overall. This lets a record appear on the home page without
  ever having been explicitly flagged featured, on a database with no curated rows yet.
  `Post.for_home` is always scoped under `published` first, so an unpublished/future-dated
  post can never surface via this path.
- `Project#read_url`/`Project#source_url` are optional (nullable) — `Project#url` remains
  the one required outbound link (the "demo" leg of the read → demo → source triple-link
  pattern). Rendering order everywhere is read → demo → source; `Demo` always renders,
  `Read`/`Source` render only when present.

## Security Posture

- **Trust boundary**: Database rows and files under `public/blog` / `public/projects`. Controllers trust model finders; markdown is considered author-controlled content.
- **Sensitive data handled**: none (public content).
- **Log hygiene**: Standard AR logging; no secrets in attributes.
- **Encryption posture**: Postgres at rest is infrastructure-managed; content is not encrypted at app layer.
- **Known risks**: `content` reads files from disk; path must stay basename/`file_path`-validated — never interpolate unsanitized user input into paths.

---

## State Owned

- `posts` and `projects` tables (UUID PKs).
- Seeded / synced from `db/seeds.rb` (projects hardcoded; posts scanned from `public/blog/*.md` YAML front matter).

---

## Dependencies

- None within app/lib catalog (depends on ActiveRecord / declare_schema framework gems only).

---

## Known Limitations

- No soft-delete or draft workflow beyond `published_at` future dating.
- `Post#content` memoizes per request but re-reads disk; no caching layer.
- Tags are JSON arrays without a join table.

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

- Prefer `declare_schema` for schema changes; generate migrations from it rather than editing migrations as primary.
- Controllers look up by slug (`find_by!` / `find_by`); keep unique indexes on slug.
- Seeds are idempotent via `find_or_initialize_by(slug: ...).update!`.
