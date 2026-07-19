<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1181 -->
<!-- Last Updated: 2026-07-19T00:00:00+02:00 -->
<!-- Description Hash: dab963071f00 -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# P1.2 — Home / Hero Redesign

**Issue:** [bitidev/jamesebentier.com#1181](https://github.com/bitidev/jamesebentier.com/issues/1181)
**Parent epic:** [#1179 — 2026 Site Redesign, Phase 1](https://github.com/bitidev/jamesebentier.com/issues/1179)
**Branch:** `personal/jebentier/issue-1181-p12-home-hero-redesign`
**Board:** org `bitidev` project — Status: In Progress; Assignee: `jebentier`
**Design:** [`docs/design/redesign-2026.md`](../design/redesign-2026.md) §2 (Positioning), §4 (Information architecture)
**Blocked by:** [P1.1 — #1180](../specs/1180-design-system-pass-refined-terminal.md) — **MERGED** (`main` @ `9687463`); this spec builds
against the real, shipped token/component API, not a hypothetical one (see
[Current State](#current-state-verified)).
**Soft-depends on:** P1.3 (#1182, projects) and P1.4 (#1183, writing) for real `featured`
curation data — see [R2](#r2--featured-data-contract-project-and-post) for the stub this
issue defines so it does not have to wait on either.
**Blocks:** none directly. P1.3/P1.4's own future specs must not re-add the `featured`
column this issue introduces — see [R2](#r2--featured-data-contract-project-and-post) and
[Dependencies / Coordination](#dependencies--coordination).

## Overview

This is the home-page redesign for the 2026 refresh. Today's `welcome/index.html.erb` is a
single paragraph of personal-bio prose ("Hello, my name is James Ebentier...") with no
positioning, no content teasers, and no call to action. This issue replaces it with the home
page the design doc's information architecture (§4) calls for: **Hero (positioning) →
Featured projects → Latest writing → understated CTA** — built entirely out of P1.1's four
shipped component partials (`components/section`, `components/card`, `components/pill`,
`components/cta_button`) and its shipped token/theme system, with zero new components or
tokens of its own.

Two of the three content sections (Featured Projects, Latest Writing) are driven by a
`featured` boolean that, per the design doc (§5), ultimately belongs to `Project` and `Post`.
P1.3 and P1.4 — the issues that own the rest of those models' new fields — are not done yet.
Rather than block on them, this issue **introduces the `featured` column on both models
itself** (a small, self-contained schema addition, not "someone else's field borrowed early")
together with a curated-first/chronological-fallback query so the home page always renders
real content today, and needs zero rework when P1.3/P1.4 land and start actually curating.

## Goal

A developer implementing P1.3/P1.4 later can flip `featured: true` on real records and watch
home pick them up automatically — no code change on either side, no migration conflict, no
"wire this up now" follow-up work. A reviewer of *this* PR can confirm: the hero carries the
final positioning line, Featured Projects and Latest Writing both render (empty-DB-safe),
the "Work with me" CTA is present and functional, the layout is responsive, and every visual
element traces to an existing P1.1 token or partial — nothing new is invented at the
CSS/component layer.

## In Scope

- Full rewrite of `app/views/welcome/index.html.erb`: new hero copy/layout (positioning line
  + supporting line, replacing the current bio paragraph), a Featured Projects section, a
  Latest Writing section, and a "Work with me" CTA — in that order, per the design doc's IA
  (§4).
- `Project#featured` and `Post#featured` — new `boolean, null: false, default: false` columns
  via `declare_schema` (matching this repo's existing schema-declaration convention — see
  [Current State](#current-state-verified)) plus the migration `declare_schema:migration`
  generates for them.
- `Project.featured` / `Post.featured` scopes and a `Project.for_home` / `Post.for_home`
  query method on each model, implementing the curated-first/chronological-fallback contract
  in [R2](#r2--featured-data-contract-project-and-post).
- Baseline `set_meta_tags` title/description for the root page (today it has none at all —
  `blog#index`/`projects#index` already call `set_meta_tags`; home does not).
- Updating `docs/architecture/sub-systems/content-domain.md` (new `featured` column/scopes
  on `Post`/`Project`) per the scribe's architecture-doc ownership rule.
- Updating/replacing the hero-specific assertions in `spec/requests/welcome_spec.rb` that are
  superseded by this rewrite (see [R10](#r10--supersede-the-old-hero-assertions-in-welcome_specrb)).

## Out of Scope

- **Any change to P1.1's tokens, themes, or the four shared partials themselves.** This issue
  is a pure consumer of `components/section` / `components/card` / `components/pill` /
  `components/cta_button` exactly as documented in
  [1180's Component API](./1180-design-system-pass-refined-terminal.md#component-api) — no
  new locals, no new partial, no CSS/theme changes. If the home page needs something the
  four partials can't express, that's a spec amendment to 1180's contract, not a workaround
  invented here.
- **`Project`'s triple-link fields (read/demo/source) and the projects grid/filter UI** —
  P1.3 (#1182). Featured-project cards here use the same single `project.url`-driven
  composition `projects/index.html.erb` already established in 1180's R9.
- **`Post.kind` (Notes/Deep Dives), `excerpt`, `reading_time`, and surfacing `Post#tags` in
  the UI** — P1.4 (#1183). Latest-Writing cards here use only fields that exist on `Post`
  today (`title`, `description`, `published_at`); `description` stands in for the
  not-yet-added `excerpt` and is not itself changed or renamed.
- **The actual "Work with me" mechanism/landing** (`/about`, a contact form, booking flow) —
  P1.5 (#1184). Per the design doc's own decision log, the mechanism *is* `mailto:` "for now,"
  and P1.5's job is the `/about` page plus placing this same CTA on about + footer. This issue
  ships the CTA's home instance and its concrete `mailto:` target now (it is real and
  functional, not a dead stub) — see [R5](#r5--work-with-me-cta).
- **Newsletter signup placement on home** — design doc §5 mentions "a tasteful home
  placement" but that is explicitly P1.7's (#1186) deliverable (the `Subscriber` model,
  double opt-in, form). Not pulled forward here.
- **JSON-LD `Person` structured data, OG image generation** — P1.10 (#1189). This issue adds
  only a plain title/description via the existing `meta-tags` gem, matching the pattern
  `blog#index`/`projects#index` already use — not new SEO infrastructure.
- **The keyboard command layer** (`g h` home shortcut, etc.) — P1.8 (#1187), a separate,
  larger issue depending on P1.1, not this one.
- **`WelcomeController#projects`/`#resume` actions, the header/footer, and the theme picker**
  — untouched; this issue only touches `#index` and its view.
- **Backfilling `featured: true` on real seed/production data.** [R2](#r2--featured-data-contract-project-and-post)'s
  fallback is specifically designed so this is optional, not a blocking prerequisite — see
  [Open Questions](#open-questions) item 1.

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch
`jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC
contribution.

## Current State (Verified)

Verified directly against this worktree (branch `personal/jebentier/issue-1181-p12-home-hero-redesign`,
based on `main` @ `9687463` — P1.1's merge commit, confirmed via
`git merge-base --is-ancestor`) as of 2026-07-19:

### The page this issue replaces
`app/views/welcome/index.html.erb` (12 lines, already token-cleaned by 1180's R10) is one
`<p>` of bio prose — name, "Software Architect for Invoca Inc.", Berlin location, "hacker /
community advocate / mentor" — followed by `image_tag 'landing-image.webp'`. No positioning
line, no project/post teasers, no CTA. `WelcomeController#index` is `def index; end` — no
instance variables set. `root "welcome#index"` (`config/routes.rb:17`).

### The real, shipped P1.1 component API (verified by reading the partials directly)
- **`components/_section.html.erb`** — rendered as a layout:
  `render(layout: "components/section", locals: { eyebrow: nil, title: nil }) { body }`.
  Wraps `yield` in a `<section class="mb-16" data-controller="motion">`; renders an optional
  Commit Mono `eyebrow` line and an optional `<h2 class="font-mono text-2xl mb-6">title</h2>`.
  Participates in the scroll fade/slide-in motion system automatically.
- **`components/_card.html.erb`** — rendered as a layout:
  `render(layout: "components/card", locals: { href:, image_url: nil }) { body }`. `href` is
  required (drives a "stretched-link" full-card `<a>` overlay, `aria-hidden`, `tabindex="-1"`);
  `image_url` is optional (rendered `alt=""`, decorative, figure omitted entirely when absent
  — confirmed via `local_assigns[:image_url].present?`, so a blank `Post#image` — the model's
  own default — safely omits the figure with no extra guard needed here). Any interactive
  child inside the block (e.g. a `cta_button`) must be `relative z-10` to stay clickable above
  the overlay, per the partial's own header comment — `projects/index.html.erb` already
  demonstrates this (`card-actions relative z-10`).
- **`components/_pill.html.erb`** — `render "components/pill", label:, variant: :tag`.
  `variant: :status` maps `Project#status` to a badge role: `Pre-Launch → badge-warning`,
  `Beta → badge-info`, `Live → badge-success` (unrecognized value falls back to
  `badge-neutral`). `variant: :tag` (default) renders a neutral `badge-outline` — used for
  free-form tags, not needed by this issue (`Post#tags` surfacing is P1.4's job).
- **`components/_cta_button.html.erb`** — `render "components/cta_button", label:, href:,
  style: :primary`. `style: :primary` (default) renders `btn btn-primary font-mono` — always
  the DaisyUI `primary` role, never a hardcoded hex, so it re-themes correctly across all six
  bundled themes; `style: :ghost` renders `btn-ghost` for a secondary action. Text-only label,
  no block-content variant (1180's own Open Questions flagged this as a future amendment if a
  page needs richer CTA content — this issue's CTA is text-only, so no amendment is needed).

### The real, shipped tokens/themes (verified in `application.tailwind.css`)
- Six registered DaisyUI themes, in order: `light --default, dark, dracula, nord, gruvbox,
  catppuccin`. `--color-primary` resolves to `#fab73a` in `dark` and the WCAG-AA-safe
  deepened `#8a5a10` in `light` (via `[data-theme="..."]` overrides) — the CTA button and any
  `text-primary` accent already re-theme correctly with no per-theme handling needed here.
- Type scale: `--text-base` 18px through `--text-4xl` 55px (Major Third 1.250), each with a
  paired `--text-*--line-height` token.
- Fonts: `--font-mono` → `"Commit Mono", ui-monospace, ...` (headings/nav/labels/code);
  `--font-sans` → `"Inter Variable", ui-sans-serif, ...` (body; also the page default via
  Tailwind's `--default-font-family`, applied today at `application.html.erb`'s
  `<div class="max-w-screen-lg m-auto font-sans">` wrapper).
- `theme-picker` (`app/javascript/controllers/theme_picker_controller.js`) and `motion`
  (`app/javascript/controllers/motion_controller.js`) Stimulus controllers both exist and are
  wired (header + the `section` partial respectively). Neither needs any change for this
  issue — `motion` is inherited for free by any `section` usage; `theme-picker` is untouched.
- `app/views/projects/index.html.erb` is the **existing, shipped reference implementation**
  for composing all four partials around a `Project`: `section` wraps the listing;
  each project renders via `card` (`href: project_url(slug: project.slug), image_url:
  project.image`); status via `pill` (`variant: :status`); a `cta_button`
  (`style: :primary`) inside `card-actions relative z-10`. This issue's Featured Projects
  section reuses this exact composition, just inside a grid instead of a `space-y-6` stack.

### `Project` / `Post` models today (no `featured` column on either)
```ruby
# app/models/project.rb (declare_schema block)
string :slug, ...    string :title, ...    string :status, ... (Pre-Launch/Beta/Live)
string :url, ...     string :image, ...    text :description, ...
```
```ruby
# app/models/post.rb (declare_schema block)
string :slug, ...    string :title, ...       string :description, ...
string :keywords, ...  string :image, default: ""  string :file_path, ...
json :tags, default: []   datetime :published_at, ...
scope :published, -> { where(published_at: ..Time.zone.now) }
```
Neither model has a `featured` column, a `for_home`-style query, nor any home-facing scope
today — confirmed via `db/schema.rb` and both `declare_schema` blocks. `docs/architecture/sub-systems/content-domain.md`
lists `Post`/`Project`'s current exports and does not yet mention `featured`.

### Routes / helpers available for this issue
`root_path` (`/`), `project_path(slug:)` / `project_url(slug:)`, `post_path(slug:)` /
`post_url(slug:)` (from `blog`'s `as: :post`/`as: :posts` route names), and the existing
`ResumeHelper#resume_data` helper (`YAML.safe_load_file("resume/resume.yml")`, memoized,
globally available since Rails includes all helpers by default) already exposes
`resume_data[:basics][:email]` → `jebentier@gmail.com` — the same address the resume page's
own `mailto:` link (`app/views/welcome/resume/_header.html.erb:13`) already uses. This is the
one real, published contact address anywhere in the codebase today.

### Schema-change tooling (confirmed working command, per prior specs in this repo)
`bundle exec rails generate declare_schema:migration` (interactive — prompts for a migration
name) generates the migration from a `declare_schema` block diff; `--pretend` reports
"Database and models match -- nothing to change" when there is no drift. This is the
established, repo-standard way new columns are added (see `docs/specs/1157-upgrade-ruby-runtime-app-gem-majors.md`
and `docs/specs/1159-upgrade-rails-7-1-to-8-x.md` for prior, verified uses of this exact
command) — not hand-written migrations as the primary source of truth for the column
definition itself.

### Existing test coverage this issue must reconcile with
`spec/requests/welcome_spec.rb` (from 1180) asserts against the *current* hero markup:
a "no rainbow-utility classes" regression guard and a `strong.text-primary` presence check
(1180's R10 token-only pass), plus a theme-picker option-list check (header, untouched by
this issue). The first two are tied to markup this issue deletes wholesale — see
[R10](#r10--supersede-the-old-hero-assertions-in-welcome_specrb).

## R2 — Featured Data Contract (`Project` and `Post`)

This is the soft-dependency resolution the issue calls for: a clean, testable stub today,
zero rework when P1.3/P1.4 land.

**Schema:** add `featured` (`boolean, null: false, default: false`) to both `Project` and
`Post` via each model's `declare_schema` block, generated/applied via
`bundle exec rails generate declare_schema:migration` (see [Current State](#current-state-verified)).
This is a real, permanent column — not a throwaway/temporary flag — and is the *same* column
P1.3/P1.4 will curate against later; it is owned by this issue going forward (see
[Dependencies / Coordination](#dependencies--coordination) for why those issues must not
redeclare it).

**Query contract — curated-first, chronological fallback:**

| Model | Scope | `for_home(limit: 3)` behavior |
|---|---|---|
| `Project` | `scope :featured, -> { where(featured: true) }` | If `featured` has any rows, return up to `limit` of them (ordered `created_at: :desc`); otherwise return up to `limit` of **all** projects, ordered `created_at: :desc` |
| `Post` | `scope :featured, -> { where(featured: true) }` | Always scoped under `published` first (never show unpublished/future-dated posts, matching `blog#index`'s existing behavior). If `published.featured` has any rows, return up to `limit` of them ordered `published_at: :desc`; otherwise return up to `limit` of `published` posts ordered `published_at: :desc` |

`limit` defaults to `3` (one screen-width row on a 3-column grid at the `md` breakpoint) —
an implementer/visual-QA-adjustable constant, not a hard-pinned number.

This means: on a fresh database with zero `featured: true` rows anywhere (true today, and
true until P1.3/P1.4 ship and someone flags real records), the home page still renders the
most recent real projects and posts — never an empty section, never fake/placeholder markup.
The moment P1.3 or P1.4 flips `featured: true` on real records, `for_home` picks the curated
set up automatically with no template change on this issue's side. This is the literal "safe
fallback/sample so P1.2 can render and be tested now, and later swap to real data without
rework" the issue asks for.

**Empty-table edge case:** if a model has **zero rows at all** (e.g., a brand-new database
before `db/seeds.rb` runs), `for_home` returns an empty relation. The corresponding home
section (Featured Projects or Latest Writing) is omitted entirely in that case — see
[R3](#r3--featured-projects-section)/[R4](#r4--latest-writing-section) — rather than
rendering an empty `section` wrapper with a heading and no cards.

**Where the query lives:** per `web-presentation`'s own documented invariant ("Controllers
stay thin... leave markup to views/helpers"), and matching `projects/index.html.erb`/`blog/index.html.erb`'s
existing precedent of calling `Project.find_each` / `Post.published.order(...)` **directly in
the view** rather than via a controller-set instance variable, `welcome/index.html.erb` calls
`Project.for_home(limit: 3)` / `Post.for_home(limit: 3)` directly. `WelcomeController#index`
stays `def index; end` — unchanged.

## Hero Copy (Final)

Per the issue's own ask, hero copy is drafted and finalized here, not left as a TODO for the
code agent:

- **Eyebrow** (Commit Mono, small, `text-primary`, terminal-flavored — a light nod to the
  "refined terminal" personality per design doc §3, distinct from `components/_section`'s own
  eyebrow slot since the hero is not itself wrapped in a `section` — see [R1](#r1--hero-rewrite)):
  ```
  $ whoami
  ```
- **H1** (Commit Mono, the largest type-scale step appropriate for a single-line headline —
  `text-3xl` or `text-4xl`, implementer/visual-QA call within that pair — the **final,
  verbatim positioning line**, not paraphrased):
  ```
  I help engineers get their systems right — a fraction of the time, all of the leverage.
  ```
- **Subhead** (Inter/`font-sans`, `text-lg`, a legible muted tone — see the contrast note in
  [R1](#r1--hero-rewrite)):
  ```
  James Ebentier — fractional architect & CTO based in Berlin, Germany. I embed with
  engineering teams to unblock hard technical decisions and mentor the people who'll own the
  system long after I'm gone.
  ```

This intentionally **drops** the current copy's explicit "Software Architect for Invoca Inc."
employer claim — the whole point of this redesign (design doc §2) is repositioning away from
day-job framing toward the fractional/mentorship narrative, and naming a current employer
alongside a "hire me for fractional work" pitch reads as a conflict of interest. This is a
real, factual claim about James's current professional affiliation, not a stylistic call the
scribe can make unilaterally — flagged explicitly in [Open Questions](#open-questions) item 2
with this safe default (omit it) so implementation is not blocked on an answer.

## R1 — Hero Rewrite

- Replace `welcome/index.html.erb`'s entire current `<div class='text-lg font-extralight
  text-center'>...</div>` block with the [Hero Copy](#hero-copy-final) above, structured as
  eyebrow → H1 → subhead, in that DOM order.
- **Not** wrapped in `components/section` — the hero is the page's singular headline element
  above the fold, distinct in visual weight from the `section`-wrapped content below it (whose
  own `<h2>` title slot is deliberately smaller, `text-2xl`, per 1180's Component API). Reusing
  `section` here would both under-size the H1 and pull in scroll-triggered fade-in for content
  that should be visible immediately on load.
- One `<h1>` per page (existing convention, see `projects/index.html.erb`'s own comment on
  this) — the positioning line is that `<h1>`.
- The existing `landing-image.webp` banner (`image_tag 'landing-image.webp', alt: 'James
  Ebentier Banner', class: 'w-full rounded-xl mb-8'`) is kept, repositioned/resized to fit
  the new copy layout (e.g., beside the copy on wide viewports, stacked below on narrow ones)
  — exact treatment is an implementer/visual-QA call, not a hard requirement; removing it
  entirely is also acceptable if visual-QA judges the new copy stands on its own, but is not
  required by this spec.
- **Contrast requirement:** the subhead's muted tone (e.g., a `base-content` opacity utility
  like `text-base-content/70`) must still meet WCAG AA (4.5:1) against `base-100` in every one
  of the six bundled themes — the same discipline 1180's R2 established for the amber tokens,
  now extended to any new opacity-modified color usage this issue introduces. Verify with a
  contrast calculator per theme before merge, same as 1180's gate.

## R3 — Featured Projects Section

- Wrapped in `components/section` with `eyebrow: "Portfolio"` (or similar short label — exact
  wording an implementer call) and `title: "Featured Projects"`.
- Body: a responsive grid (`grid grid-cols-1 md:grid-cols-3 gap-6`) of up to `limit` cards
  from `Project.for_home(limit: 3)` ([R2](#r2--featured-data-contract-project-and-post)),
  each composed **exactly** like `projects/index.html.erb`'s existing per-project block (1180
  R9's reference implementation — see [Current State](#current-state-verified)): `card`
  (`href: project_url(slug:), image_url: project.image`) wrapping an `<h2 class="card-title
  font-mono text-xl">project.title</h2>`, the status `pill` (`variant: :status`),
  `project.description`, and a `cta_button` (`style: :primary`, `href:` the same
  `project_url`, label "View Project") inside `card-actions relative z-10`.
- **Omit the entire section** (no `section` wrapper, no heading) when `Project.for_home`
  returns an empty relation (only possible on a completely empty `projects` table) — per
  [R2](#r2--featured-data-contract-project-and-post)'s empty-table edge case.
- No triple-link UI, no filter UI, no new `Project` fields beyond `featured` — explicitly
  P1.3's territory (see [Out of Scope](#out-of-scope)).

## R4 — Latest Writing Section

- Wrapped in `components/section` with `eyebrow: "Writing"` (or similar) and `title: "Latest
  Writing"`.
- Body: the same responsive grid pattern as Featured Projects (`grid grid-cols-1
  md:grid-cols-3 gap-6`), one `card` per post from `Post.for_home(limit: 3)`
  ([R2](#r2--featured-data-contract-project-and-post)). Each card: `href: post_url(slug:
  post.slug), image_url: post.image` (safely omits the figure when blank — see
  [Current State](#current-state-verified)); body is an `<h2 class="card-title font-mono
  text-xl">post.title</h2>`, a small published-date line (Inter, `text-sm`, muted —
  `post.published_at.strftime("%B %d, %Y")`, matching `blog/index.html.erb`'s existing date
  format), `post.description` (standing in for the not-yet-added `excerpt` — see
  [Out of Scope](#out-of-scope)), and a `cta_button` (`style: :primary`, `href:` the same
  `post_url`, label "Read Post") inside `card-actions relative z-10`.
- **Omit the entire section** (no `section` wrapper, no heading) when `Post.for_home` returns
  an empty relation.
- No `kind`/Notes-vs-Deep-Dives badge, no tags, no reading time, no excerpt field — explicitly
  P1.4's territory (see [Out of Scope](#out-of-scope)).

## R5 — "Work with me" CTA

- Placed last on the page, per the design doc's IA (§4: "...→ understated CTA").
- Wrapped in `components/section` (for consistent spacing/motion with the two sections above
  it) with a modest `eyebrow: "Get in touch"` and **no oversized banner treatment** — per
  design doc §2's explicit "no banners" — a single supporting sentence plus one
  `cta_button` (`style: :primary`, `label: "Work with me"`).
- **Href — the concrete, functional target for today:**
  `mailto:#{resume_data[:basics][:email]}` (resolves to `mailto:jebentier@gmail.com`, reusing
  the one real published contact address already in the codebase — see
  [Current State](#current-state-verified)) — **not** a dead placeholder like `href="#"`.
  This matches the design doc's own decision log ("Contact CTA: `mailto:` link for now,
  expandable later") — the mechanism named there already *is* a working `mailto:` link, so
  this issue ships a real, clickable CTA rather than a stub awaiting P1.5.
- Reusing `resume_data[:basics][:email]` (rather than a second hardcoded literal) keeps the
  one published address single-sourced from `resume/resume.yml`; if that coupling feels wrong
  once P1.5 (#1184) builds a dedicated contact mechanism, swapping the `href` — or extracting
  a small shared "work with me" partial P1.5 can reuse across home/about/footer — is a
  same-line change, no redesign (per design doc's own future-proofing language for this CTA).
- No new copy/form/booking flow — P1.5's job (see [Out of Scope](#out-of-scope)).

## R6 — Responsive Layout

- Hero: copy readable at all viewport widths; if the banner image sits beside the copy on
  wide viewports (implementer's layout call per [R1](#r1--hero-rewrite)), it must stack below
  the copy at the `md` breakpoint or narrower — no fixed-width layout that could overflow or
  clip on a phone-width viewport.
- Featured Projects / Latest Writing grids: `grid-cols-1` below `md`, `md:grid-cols-3` at and
  above — single-column stacking on mobile is the testable, class-name-verifiable
  responsiveness signal (see [Acceptance Criteria](#acceptance-criteria); this repo has no
  Capybara/system-test infra to visually assert breakpoints, matching 1180's own documented
  limitation).
- CTA section: centered, readable at all widths — no special breakpoint handling needed
  beyond what `components/section`/`components/cta_button` already provide.

## R7 — Baseline Home Meta Tags

- Add a `set_meta_tags` call to `welcome/index.html.erb` (today it has none — `blog#index`
  and `projects#index` already do this; home is the one page missing it). Minimal scope:
  `title:` and `description:` only — no OG image override, no JSON-LD (explicitly P1.10's
  job, see [Out of Scope](#out-of-scope)).
- `title:` a short identity string, e.g. `"James Ebentier — Fractional Architect & CTO"`;
  `description:` a short paraphrase of the positioning line (not necessarily verbatim, since
  meta descriptions have their own length/SEO conventions) — exact wording an
  implementer/content call within that shape.

## Dependencies / Coordination

- **Blocked by P1.1 (#1180) — satisfied.** Merged to `main` (`9687463`); this spec was
  written against and verified directly against the shipped tokens/components (see
  [Current State](#current-state-verified)), not the 1180 spec's proposed design.
- **Soft-depends on P1.3 (#1182) and P1.4 (#1183)** for real curated `featured` data — resolved
  by [R2](#r2--featured-data-contract-project-and-post)'s stub/fallback; no code-side blocking
  dependency remains.
- **Coordination requirement for P1.3/P1.4's own future specs:** this issue's
  `declare_schema` migration is the one that adds `featured` to both `Project` and `Post`.
  When the P1.3 and P1.4 specs are written, they must be told (by whoever authors them) to add
  their *other* new fields (triple-links; `kind`/`excerpt`/`reading_time`) **without**
  redeclaring `featured` — it already exists once this issue merges. This is a note for that
  future scribe work, not an action this spec can perform on specs that don't exist yet.
- **Feeds P1.5 (#1184):** P1.5's "CTA component ... placement on home + about + footer" will
  most naturally reuse or extract the CTA this issue ships (see [R5](#r5--work-with-me-cta))
  rather than building home's instance from scratch — left to P1.5's own spec to decide
  exactly how (reuse in place vs. extract to a shared partial).

## R8 — Update `content-domain` Architecture Doc

`docs/architecture/sub-systems/content-domain.md`:
- **Anchor Files**: no new files (the `featured` column and scopes live in the existing
  `app/models/post.rb` / `app/models/project.rb`).
- **Public Contract**: add `Project.featured` / `Project.for_home`, `Post.featured` /
  `Post.for_home` to the Exports list, next to the existing `Post.published` entry.
- **Key Invariants**: add a bullet documenting the curated-first/chronological-fallback
  behavior of `for_home` (so a future reader of this doc — not this spec — understands why a
  project/post can appear on home without ever having been explicitly flagged featured).
- **State Owned**: no change (still the same two tables; `featured` is an additive column).
- No new subsystem, no dependency-graph change.

## R9 — Web-Presentation Doc: No Change Expected

`docs/architecture/sub-systems/web-presentation.md`'s existing Public Contract/Key Invariants
already cover `WelcomeController`, the four component partials, and the "controllers stay
thin, views query directly" invariant this issue follows exactly (see
[R2](#r2--featured-data-contract-project-and-post)'s "Where the query lives"). No route
changes, no new Stimulus controller, no new component. If implementation ends up deviating
from "controllers stay thin" for a good reason, that deviation must be reflected here in the
same PR — but this spec does not anticipate needing to.

## R10 — Supersede the Old Hero Assertions in `welcome_spec.rb`

`spec/requests/welcome_spec.rb`'s two hero-specific examples from 1180 —
`"retires all six rainbow hero utilities..."` and `"carries the single amber accent token on
the emphasized name..."` (`strong.text-primary` lookup) — assert against markup this issue
deletes wholesale ([R1](#r1--hero-rewrite)). They must be **replaced**, not left red or
deleted outright: replace them with equivalent assertions against the *new* hero (e.g., the
positioning line's exact text is present in the rendered `<h1>`; the eyebrow/hero region still
carries no reintroduced rainbow utility classes). The theme-picker example in the same file
(header markup, untouched by this issue) is unaffected and stays as-is.

## Approach (Implementation Guidance)

Spec-level guidance for the **code** agent — not a substitute for re-verifying the current
`declare_schema`/Tailwind/DaisyUI state at implementation time, per this repo's own standing
practice.

1. Confirm working in this issue's worktree/branch, based on current `main` (P1.1 already
   merged in).
2. Add `boolean :featured, null: false, default: false` to both `Project`'s and `Post`'s
   `declare_schema` blocks. Run `bundle exec rails generate declare_schema:migration`
   (interactive — supply a descriptive name, e.g. `add_featured_to_projects_and_posts`),
   review the generated migration adds exactly the two boolean columns, `bundle exec rails
   db:migrate`, regenerate `db/schema.rb`. Confirm `--pretend` reports no remaining drift.
3. Add `scope :featured, -> { where(featured: true) }` and a `for_home(limit: 3)` class
   method to each model per [R2](#r2--featured-data-contract-project-and-post)'s exact
   fallback contract.
4. Rewrite `app/views/welcome/index.html.erb` top-to-bottom per
   [R1](#r1--hero-rewrite)–[R5](#r5--work-with-me-cta), in IA order: hero, Featured Projects,
   Latest Writing, CTA. Add the `set_meta_tags` call per [R7](#r7--baseline-home-meta-tags).
5. Update `spec/requests/welcome_spec.rb` per [R10](#r10--supersede-the-old-hero-assertions-in-welcome_specrb);
   add new request-spec coverage for: hero copy present; Featured Projects section renders 0
   (omitted)/1/3+ projects, curated set preferred over fallback when any `featured: true`
   exists; same three cases for Latest Writing against `Post`; CTA renders with the correct
   `mailto:` href; responsive grid classes present. Follow this repo's existing pattern of
   exercising real controller/view stack (see `spec/requests/projects_spec.rb`'s own note on
   call-site-wiring verification) rather than only unit-testing the model scopes in isolation.
6. Update `docs/architecture/sub-systems/content-domain.md` per
   [R8](#r8--update-content-domain-architecture-doc).
7. Verify: `bundle exec rubocop` and `bundle exec rspec` (`ci-gate`) green;
   `bundle exec rails generate declare_schema:migration --pretend` reports no drift;
   `yarn build:css` unaffected (no new Tailwind classes beyond ones already in the P1.1
   utility vocabulary — grid/flex/spacing utilities are stock Tailwind, not new tokens).
   Manually verify in-browser: switch all six themes on the redesigned home page and confirm
   the hero/cards/CTA all re-theme correctly (no hardcoded colors were introduced); resize to
   a phone-width viewport and confirm both grids collapse to one column and the CTA reads
   cleanly.

## Acceptance Criteria

- [ ] `welcome/index.html.erb` renders the hero with the exact, verbatim positioning line as
      an `<h1>`: "I help engineers get their systems right — a fraction of the time, all of
      the leverage." (R1)
- [ ] The old bio-paragraph hero markup (name/employer/location sentence,
      `text-2xl`-wrapped `<strong>` spans) is fully removed, not left alongside the new copy (R1)
- [ ] `Project` and `Post` both have a `featured` boolean column (`null: false, default:
      false`), added via `declare_schema` + generated migration, with `db/schema.rb`
      regenerated and `declare_schema:migration --pretend` reporting no drift (R2)
- [ ] `Project.for_home`/`Post.for_home` return the curated (`featured: true`) set when any
      exists, and fall back to the `limit` most recent records (chronological) when none do —
      verified for both "zero featured" and "some featured" cases (R2)
- [ ] With zero rows in a table, the corresponding home section (Featured Projects / Latest
      Writing) does not render its `section` wrapper at all (R2, R3, R4)
- [ ] Home renders a Featured Projects section using `components/section` +
      `components/card` + `components/pill` (`variant: :status`) + `components/cta_button`
      per project, composed identically to `projects/index.html.erb`'s established pattern (R3)
- [ ] Home renders a Latest Writing section using `components/section` + `components/card` +
      `components/cta_button` per post, scoped under `Post.published` (never shows
      unpublished/future-dated posts) (R4)
- [ ] The "Work with me" CTA renders via `components/cta_button` with
      `href="mailto:jebentier@gmail.com"` (sourced from `resume_data[:basics][:email]`, not a
      second hardcoded literal) and is the last element on the page (R5)
- [ ] Featured Projects and Latest Writing grids use `grid-cols-1` below `md` and
      `md:grid-cols-3` at/above it (R6)
- [ ] `welcome/index.html.erb` calls `set_meta_tags` with a `title:`/`description:` reflecting
      the new positioning (currently absent entirely) (R7)
- [ ] `docs/architecture/sub-systems/content-domain.md`'s Public Contract and Key Invariants
      reflect the new `featured` columns/scopes/`for_home` behavior (R8)
- [ ] `spec/requests/welcome_spec.rb`'s two hero-specific examples from 1180 are replaced with
      equivalent assertions against the new hero, not left failing or silently deleted (R10)
- [ ] No changes to any P1.1 component partial, Stimulus controller, or `application.tailwind.css`
      token/theme definition (this issue is a pure consumer)
- [ ] No `Project`/`Post` fields beyond `featured` are added (triple-links, `kind`, `excerpt`,
      `reading_time`, tag surfacing all explicitly excluded — see [Out of Scope](#out-of-scope))
- [ ] Existing `ci-gate` (`lint` + `test`) remains green

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns)
and the scribe's own delegation rules:

- **Implementation** (all of R1–R10: the `featured` migration on both models, the model
  scopes/`for_home` methods, the full `welcome/index.html.erb` rewrite, the meta-tags
  addition, the `content-domain.md` update, updating/adding the request specs, opening the
  PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (moving #1181's board status, closing on merge): delegate to
  the **orchestrator** — this spec does not perform those operations.
- **Manual in-browser verification** of theme re-rendering and responsive breakpoints (no
  automated system-test coverage exists in this repo, matching 1180's own documented
  limitation): part of the implementer's own pre-PR verification (per the `verify` skill).
- **Final exact wording** for the section eyebrows ("Portfolio"/"Writing"/"Get in touch"),
  the hero H1's exact `text-3xl` vs `text-4xl` size, the meta title/description phrasing
  beyond the shapes given here, and whether/how the `landing-image.webp` banner is
  repositioned: implementer/visual-QA call within the constraints already stated — not a
  decision requiring further scribe/user sign-off.

## Open Questions

1. **Backfilling `featured: true` on real seed/production data.** `db/seeds.rb`'s two seeded
   projects (`not-my-real-email`, `the-game-about-people`) and any real published posts will
   all default to `featured: false`, so on first deploy the home page shows the
   chronological-fallback set for both sections, not a hand-curated one. That's expected and
   safe per [R2](#r2--featured-data-contract-project-and-post) — flagging only so James can
   flip a couple of real records to `featured: true` post-merge if a curated (rather than
   purely chronological) home page is wanted sooner than P1.3/P1.4. Not blocking.
2. **Dropping the "Software Architect for Invoca Inc." employer line from the hero.** The
   [Hero Copy](#hero-copy-final) intentionally omits this real, current professional-affiliation
   claim the existing copy makes, for the reasons given there. This is a factual/biographical
   call only James can confirm — the spec ships with omission as the safe default so
   implementation isn't blocked, but this is worth an explicit go/no-go before merge, not
   after.
3. **`$ whoami` eyebrow treatment.** A small personality flourish tying into the "refined
   terminal" identity (design doc §3), not a design-doc-mandated element — left to
   implementer/visual-QA judgment whether it reads as charming or gimmicky in practice; safe
   to drop the eyebrow entirely (going straight to the H1) if visual-QA prefers, without
   affecting any other requirement in this spec.
4. **Section eyebrow copy ("Portfolio", "Writing", "Get in touch") and exact grid `gap`/card
   sizing.** Genuine visual-design judgment calls within the structural requirements already
   fixed (R3/R4/R5), not functional gaps.

## Changelog

### Version 1 - 2026-07-19
**Source Issue:** bitidev/jamesebentier.com#1181
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification for the home/hero redesign: final hero copy (positioning line +
  supporting identity line), a Featured Projects section, a Latest Writing section, and a
  functional "Work with me" `mailto:` CTA — composed entirely from P1.1's shipped
  `components/section`/`card`/`pill`/`cta_button` partials and token/theme system, verified
  directly against the merged P1.1 code (not the 1180 spec's proposal)
- Resolved the P1.3/P1.4 soft-dependency on `featured` data by introducing a real
  `featured` boolean column on both `Project` and `Post` in this issue, with a
  curated-first/chronological-fallback query (`for_home`) so home renders real content today
  and needs no rework once P1.3/P1.4 start actually curating
- Verified current app state: `welcome/index.html.erb` is a single bio paragraph with no
  positioning/teasers/CTA and no meta tags; neither `Project` nor `Post` has a `featured`
  column today; `projects/index.html.erb` is the existing, shipped reference implementation
  for composing all four P1.1 partials around a `Project`, reused here for the Featured
  Projects section
- Flagged two items needing explicit owner confirmation rather than deciding unilaterally:
  dropping the current copy's "Software Architect for Invoca Inc." employer claim from the
  hero, and whether to backfill any real `featured: true` records post-merge
- Scoped out everything belonging to sibling Phase-1 issues (P1.3 triple-links/grid/filter,
  P1.4 kind/excerpt/reading-time/tags, P1.5's actual contact mechanism and `/about` page,
  P1.7 newsletter placement, P1.8 keyboard shortcuts, P1.10 JSON-LD/OG), and named the
  coordination requirement that P1.3/P1.4's own future specs must not redeclare the
  `featured` column this issue introduces

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by
the code agent.

---
