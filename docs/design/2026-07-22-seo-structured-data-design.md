# P1.10 — SEO / meta / structured-data polish (#1189)

**Date:** 2026-07-22 · **Epic:** Phase 1 (#1179) · **Soft-dep:** #1183 (article metadata, landed)

## Problem

The site's discoverability metadata is thin and partly broken:

- **No structured data at all.** Nothing emits JSON-LD, so search engines and social
  scrapers get no `Person`/`Article` graph — the issue's core deliverable.
- **OG image is wrong for large-image cards.** The layout advertises
  `twitter:card = summary_large_image` but points every page at `logo192.png` (192×192).
  Large-image cards want ~1200×630; a 192px square renders as a tiny/blank thumbnail.
- **A blank-image bug on posts.** `writing/show` sets
  `og:image = "https://jamesebentier.com/#{@post.image}"`, but `Post#image` defaults to
  `""`, so a post without an explicit image emits `https://jamesebentier.com/` as its
  image URL — an invalid image.
- **`og:type` is `website` for everything,** including posts, which should be `article`.
- **Canonicals are inconsistent.** Only `writing/show` sets a canonical; every other page
  relies on scrapers guessing, and query-string variants (`?kind=note`, `?status=beta`)
  have no canonical pointing back to the clean URL.

## Chosen approach

Keep it inside the existing `meta-tags` gem + a small JSON-LD helper. No new runtime
rendering pipeline, no new gems.

1. **JSON-LD via a helper** (`app/helpers/structured_data_helper.rb`) that renders
   `<script type="application/ld+json">` blocks:
   - **`Person`** (site-wide, from the layout) — James Ebentier, jobTitle "Software
     Architect", Berlin, `sameAs` his real profile URLs (LinkedIn/GitHub/etc. — reuse
     whatever `social_profiles` the footer already lists), `url` = site root.
   - **`WebSite`** (site-wide) — name + url, so the site itself is a first-class entity.
   - **`BlogPosting`** (posts only, from `writing/show`) — `headline`, `description`,
     `datePublished` (`@post.published_at.iso8601`), `author` (a reference to the Person),
     `keywords` (`@post.tags`), `mainEntityOfPage` = canonical post URL, `wordCount` and
     `timeRequired` (ISO-8601 `PT#{reading_time}M`), `image` = resolved OG image.
   Emitted through `yield :head` / a layout slot so each entity is a separate script tag
   (valid, and what Google's tooling prefers over one mega-graph).

2. **OG image** — one static branded 1200×630 default, `public/og-default.png`, replacing
   `logo192.png` as the site-wide OG/Twitter image. Terminal-styled to match the redesign
   (dark base, `❯ james@ebentier` prompt, name + "Software Architect · Berlin"). A post
   with its own `@post.image` still overrides it; a post **without** one falls back to the
   branded default (fixing the blank-image bug). One asset, committed; no per-request or
   per-post image generation. See the open question below.

3. **`og:type = article` on posts** + `article:published_time` / `article:author` meta.
   The layout default stays `website`; `writing/show` overrides `og: { type: 'article', ... }`.

4. **Canonicals everywhere.** Add a layout-level default canonical
   (`request.original_url` minus query string) so filtered index views
   (`?kind=`, `?status=`) canonicalize to the clean path; pages that already set one
   (posts) keep theirs.

5. **Sanity pass** on every page's title/description: confirm each is present, unique,
   within meta-tags' 70/300 limits, and free of the dropped "fractional/CTO" wording
   (consistent with the #1226 redesign). Fix any that read awkwardly.

## Acceptance criteria

- Every page emits a valid `Person` + `WebSite` JSON-LD block; post pages additionally emit
  a valid `BlogPosting` block. All validate cleanly (schema.org / Google Rich Results
  structure — no errors).
- Every page emits `og:title`, `og:description`, `og:url`, `og:type`, and an `og:image`
  that resolves to a real ≥1200×630 image. Posts emit `og:type=article`.
- No page emits `https://jamesebentier.com/` (or any empty-path URL) as an image.
- Every page emits a `<link rel="canonical">`; filtered index URLs canonicalize to the
  clean path.
- Titles/descriptions present, unique, within limits, no "fractional/CTO".
- Specs cover: JSON-LD presence + key fields per page type, `og:type=article` on posts,
  image fallback (post without image → default), and canonical presence/normalization.

## Open questions

1. **OG image strategy — static branded default (recommended) vs. templated generator.**
   Recommendation: ship the single static `og-default.png` (matches the imagery-free
   terminal aesthetic, zero runtime cost, one committed asset). A per-page/per-post
   *generated* image (headless-Chrome screenshot of an HTML card, or an image-lib
   template) is materially more machinery — new dependency, a render/caching path, and an
   asset per post — for a personal site whose posts rarely carry bespoke art. Deferring the
   generator keeps this issue right-sized; it can be its own follow-up if wanted. **Need
   operator's call before build.**
2. **`sameAs` profile list** — reuse exactly the profiles the footer already renders
   (single source of truth), or curate a different set for the Person entity? Default:
   reuse the footer's.
