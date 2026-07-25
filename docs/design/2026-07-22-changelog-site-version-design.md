# P1.12 — Build-in-public: /changelog + site version (#1191)

## Problem

The refresh should be documented publicly. Two code deliverables (the companion
"Rebuilding this site" Notes series is separate editorial via P1.4, out of scope here):

1. A **`/changelog`** page listing the site's notable changes over time.
2. A **site version** shown in the footer.

The site has **no version source today** — `package.json` has no `version`, there are no
git tags, no `VERSION` file. So this issue must establish one. The changelog page and the
footer version are the same information at two altitudes (the footer shows the newest
release; the page shows the history), so they must derive from **one source of truth** — a
footer version that can drift from the changelog is exactly the bug to avoid.

## Chosen approach

**One structured data file is the single source of truth**, read by a small plain-Ruby
`Changelog` domain object — no database table, no migration. A changelog is static,
in-repo, owner-edited content; a DB model (like `Post`) is the wrong altitude for it.

- **Source file:** `db/changelog.yml` — an ordered list of releases, newest first:
  ```yaml
  - version: "1.1.0"
    date: 2026-07-22
    title: "Legal pages"
    changes:
      - "Impressum + GDPR-compliant privacy policy, linked from the footer."
  - version: "1.0.0"
    date: 2026-07-DD
    title: "Terminal-identity redesign"
    changes:
      - "Full redesign across all six pages."
      - "First-party, cookieless analytics replacing Google Analytics + Metricool."
  ```
  YAML (not one-markdown-file-per-release) because a changelog is a *list of short dated
  entries*, and a single file keeps the whole history reviewable in one diff. Each
  free-text field may contain inline markdown, rendered through the **existing
  `BlogHelper#render_markdown`** so we reuse the site's Redcarpet pipeline (satisfies the
  P1.4 soft-dependency) without inventing a second content system.

- **Domain object:** `Changelog` (a PORO, `app/models/changelog.rb`) that loads and
  validates the YAML into `Changelog::Release` value objects, exposes `Changelog.releases`
  (ordered) and `Changelog.current` / `Changelog.current_version` (the newest release).
  Reads the file once and memoizes.

- **Route + page:** `get "changelog" => "changelog#index"` → a dedicated
  `ChangelogController#index` (matches the `projects`/`writing` content-index-controller
  convention rather than piling onto `welcome`). View `app/views/changelog/index.html.erb`
  in the established terminal-identity page style (like `about`/`privacy`): a
  `cat CHANGELOG.md`-style eyebrow, mono headings, each release rendered with its version,
  date, title, and change list.

- **Footer version:** the existing copyright block in
  `app/views/layouts/components/_footer.html.erb` gains `v#{Changelog.current_version}`,
  linked to `/changelog`. One helper call, sourced from the same object as the page.

**Versioning policy:** human-curated semver in the changelog file, owner-bumped per notable
change — not derived from git. The newest entry *is* the site version. Seeding the initial
file with a couple of real past milestones (redesign, analytics, legal) gives the page
non-empty content on day one.

No new gems (Redcarpet + YAML already present), no migration, no JS.

## Acceptance criteria

- `GET /changelog` returns 200 and renders each release from `db/changelog.yml` (version,
  date, title, changes), in newest-first order, with inline markdown rendered.
- The footer shows `v<current version>` on every page that renders the footer, linked to
  `/changelog`, and the value equals the newest release in `db/changelog.yml` (proving the
  single source of truth).
- Adding a new entry at the top of `db/changelog.yml` updates **both** the page and the
  footer version with no other code change.
- `Changelog` handles a malformed/missing file without 500-ing the whole site footer
  (degrade gracefully — e.g. blank/omitted version rather than crashing every page).
- Specs cover: the domain object (ordering, `current_version`, graceful degradation), the
  `/changelog` request (200 + content), and the footer version rendering + link.

## Open questions

1. **Changelog scope/voice** — build-in-public, visitor-facing prose (what shipped and why),
   *not* a raw commit log. I'll seed 2–3 real past milestones; **owner supplies/edits the
   exact copy and the starting version number** (defaulting to `1.0.0` = the redesign,
   `1.1.0` = legal, or a scheme you prefer). Confirm the version scheme.
2. **Footer placement** — `v1.1.0` sits next to the `© 2026 · Berlin` / `Impressum · Privacy`
   line. OK, or do you want it elsewhere (e.g. the `❯ james@ebentier` prompt line)?
3. **File location** — `db/changelog.yml` (alongside seeds/data) vs `config/changelog.yml`
   vs a root `CHANGELOG.md`. I lean `db/changelog.yml`. Object if you'd rather it live elsewhere.
