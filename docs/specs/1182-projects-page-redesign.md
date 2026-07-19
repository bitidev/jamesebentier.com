<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1182 -->
<!-- Last Updated: 2026-07-19T00:00:00+02:00 -->
<!-- Description Hash: ad05ae895bc6 -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# P1.3 — Projects Page Redesign

**Issue:** [bitidev/jamesebentier.com#1182](https://github.com/bitidev/jamesebentier.com/issues/1182)
**Parent epic:** [#1179 — 2026 Site Redesign, Phase 1](https://github.com/bitidev/jamesebentier.com/issues/1179)
**Branch:** `personal/jebentier/issue-1182-p13-projects-page-redesign`
**Design:** [`docs/design/redesign-2026.md`](../design/redesign-2026.md) §4 (Information architecture),
§5 (Content model — `Project`)
**Blocked by:** [P1.1 — #1180](../specs/1180-design-system-pass-refined-terminal.md) — **MERGED**
(`main` @ `9687463`); this spec builds against the real, shipped token/component API, not a
hypothetical one (see [Current State](#current-state-verified)).
**Consumes:** [P1.2 — #1181](../specs/1181-home-hero-redesign.md)'s `featured` boolean +
`Project.for_home` contract — **already shipped on `main`** (verified below). This issue does
**not** re-declare or re-migrate `featured`; it only adds the triple-link fields and the
grid/filter/show UI.
**Blocks:** none directly.

## Overview

`docs/design/redesign-2026.md` §4 calls for `/projects` to become "Grid, filterable by status
(Pre-Launch / Beta / Live), triple-link cards." Today (verified in this worktree, `main` @
`3ac7288`, which includes P1.1 #1180 and P1.2 #1181 merged), `app/views/projects/index.html.erb`
is a single-column `space-y-6` stack of P1.1 `card`/`pill`/`cta_button` partials (already
migrated off raw markup by 1180's own R9), and `app/views/projects/show.html.erb` is still the
**pre-1180 raw markup** — a hand-rolled two-column flex layout with a hardcoded `badge-accent`
and `text-[#999]` literal-color utilities, using none of the four shared P1.1 partials.

This issue: (1) adds two new optional link columns to `Project` (`read_url`, `source_url` —
the triple-link pattern's other two legs; `url` already exists and becomes the "demo" leg, see
[R1](#r1--schema-triple-link-fields)), (2) turns the index into a responsive card grid with a
server-rendered status filter and empty/coming-soon states, (3) rewrites `show.html.erb` onto
the same four P1.1 partials, and (4) does **not** touch `welcome/index.html.erb`, `featured`,
or any P1.1 partial — those are explicitly out of scope (see [Out of Scope](#out-of-scope)).

## Goal

A visitor on `/projects` sees a filterable grid of project cards, each showing a status pill
and up to three outbound links (Read → Demo → Source) shown only when the underlying data is
present. A visitor on `/projects/:slug` sees the same status pill and triple-links plus the
full project write-up, styled consistently with the rest of the redesigned site. A reviewer of
this PR can confirm: every visual element traces to an existing P1.1 token or partial (or is
plain, already-in-use Tailwind/DaisyUI utility markup for the one new bit of page-local UI — the
status-filter links — which no P1.1 partial covers), `featured`/`Project.for_home` are
untouched and still pass 1181's own test suite, and the new schema is additive only (no
renamed/dropped columns, zero data-migration risk).

## In Scope

- `Project` schema additions: `read_url` (string, nullable, optional) and `source_url` (string,
  nullable, optional), added via `declare_schema` + the generated `declare_schema:migration`,
  per [R1](#r1--schema-triple-link-fields). **Not** re-adding `featured` (already shipped by
  #1181 — see [Current State](#current-state-verified)).
- A `Project::STATUSES` constant (`%w[Pre-Launch Beta Live]`) and a `Project.by_status` scope,
  replacing the inline literal array currently embedded only in the `status` validation, so the
  filter UI and the model validation share one source of truth ([R2](#r2--project-model-statuses-constant--by_status-scope)).
- `app/views/projects/index.html.erb` rewrite: responsive card grid (`grid grid-cols-1
  md:grid-cols-3 gap-6`), each card's title itself a real link to the show page (replacing the
  old separate "View Project" CTA — see [R3](#r3--projects-index-card-grid) for why), status
  pill, and the triple-links (read → demo → source) rendered via `components/cta_button`, shown
  only when the corresponding URL is present ([R3](#r3--projects-index-card-grid)).
- Server-rendered status filter (`?status=`) with an "All" default, reusing the header nav's own
  active-link convention ([R4](#r4--filter-by-status)).
- Empty-table and empty-filter-result "coming soon" states ([R5](#r5--empty--coming-soon-states)).
- `app/views/projects/show.html.erb` rewrite onto `components/section` + `components/pill` +
  `components/cta_button` ([R6](#r6--projects-show-page-rewrite)).
- Updating `docs/architecture/sub-systems/content-domain.md` (new columns/scope) per the
  scribe's architecture-doc ownership rule ([R9](#r9--update-content-domain-architecture-doc)).
- New/updated request specs (`spec/requests/projects_spec.rb`), model specs
  (`spec/models/project_spec.rb`), and factory (`spec/factories/project.rb`) coverage.

## Out of Scope

- **Re-declaring, re-migrating, or altering `featured`.** #1181 already added
  `Project#featured` (`boolean, null: false, default: false`) and `Project.for_home` — both are
  present in this worktree today (see [Current State](#current-state-verified)). This issue
  consumes them as-is; the schema diff this issue introduces is `read_url`/`source_url` only.
- **`welcome/index.html.erb` and its Featured Projects section.** #1181's home page composes its
  own inline copy of the card pattern (title/pill/description/"View Project" CTA) — it is not a
  shared partial, so changing `projects/index.html.erb`'s card composition in this issue (e.g.
  linking the title instead of a separate CTA) does not affect home. Home is not touched, and
  its own request-spec coverage from #1181 must remain green untouched (see
  [R8](#r8--home--featured-compatibility-no-change)). Extracting a shared `project_card` partial
  so both call sites converge is a reasonable future cleanup but is not called for by this spec
  and is not done here.
- **Any change to a P1.1 shared partial** (`components/_section`, `_card`, `_pill`,
  `_cta_button`), the `motion`/`theme-picker` Stimulus controllers, or
  `application.tailwind.css` tokens/themes. This issue is a pure consumer of all four partials
  exactly as documented in their own header comments (see
  [Current State](#current-state-verified)).
- **Client-side/JS status filtering.** The filter is a plain server-rendered query-string link
  (full navigation, no Stimulus controller, no `fetch`). See
  [Testing Strategy](#testing-strategy) for why this keeps the whole issue at request/view/model
  spec coverage with zero system specs needed. A live, no-reload client-side filter is a
  plausible future enhancement, not part of this issue.
- **`ProjectsController#show`'s `find_by` (vs. `find_by!`) 404 behavior.** Flagged today in
  `docs/architecture/sub-systems/web-presentation.md`'s Known Limitations as a pre-existing
  inconsistency with `blog#show`'s `find_by!`. Not introduced or worsened by this issue (a
  missing `@project` would already raise `NoMethodError` today calling `@project.title` in
  `set_meta_tags`); fixing it is unrelated to the design-system pass and is left as a
  pre-existing item for a future ticket — see [Open Questions](#open-questions) item 3.
- **`index.rss.builder` / `search_index_controller.rb`.** Neither references `read_url` or
  `source_url`; both continue to use `project.url`/`title`/`description`/`image`/`slug`
  unchanged — confirmed by reading both files directly (see
  [R7](#r7--rss--search-index-no-change-expected)).
- **Format/URL validation on `read_url`/`source_url`.** `url` itself has no format validation
  today (presence only) — the two new fields follow the same, existing, minimal-validation
  convention, not a new stricter one.
- **Any Bardic Labs / `/lab` content.** Phase 2, unrelated to this issue.

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch `jb-brown` /
`Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against this worktree (branch
`personal/jebentier/issue-1182-p13-projects-page-redesign`, currently at the same commit as
`origin/main`, `3ac7288`, confirmed via `git merge-base --is-ancestor 9687463 HEAD` — P1.1's
merge commit is an ancestor) as of 2026-07-19. `3ac7288` is itself #1181's (P1.2) own merge
commit, so **both** P1.1 and P1.2 are shipped and present here already.

### `Project` today — `featured` already shipped, no triple-link fields yet
```ruby
# app/models/project.rb
declare_schema id: :uuid, default: 'gen_random_uuid()' do
  string :slug,   limit: 255,  null: false, validates: { presence: true, uniqueness: true }, index: { unique: true }
  string :title,  limit: 1024, null: false, validates: { presence: true }
  string :status, limit: 255, null: false,  validates: { presence: true, inclusion: { in: %w[Pre-Launch Beta Live] } },
                  default: 'Beta'
  string :url,    limit: 1024, null: false, validates: { presence: true }
  string :image,  limit: 1024, null: false, validates: { presence: true }
  text   :description, null: false, validates: { presence: true }
  boolean :featured, null: false, default: false
end

scope :featured, -> { where(featured: true) }

def self.for_home(limit: 3)
  featured.any? ? featured.order(created_at: :desc).limit(limit) : order(created_at: :desc).limit(limit)
end
```
`db/schema.rb`'s `projects` table matches exactly (`id` uuid, `created_at`, `description`,
`featured` boolean default false, `image`, `lock_version`, `slug` unique index, `status` default
`"Beta"`, `title`, `updated_at`, `url`) — **no `read_url`/`source_url` column exists today**.
`declare_schema:migration` for `featured` already ran (`db/migrate/20260719004505_add_featured_to_projects_and_posts.rb`,
a plain `add_column :projects, :featured, :boolean, null: false, default: false` /
`add_column :posts, :featured, ...` pair) — this is the migration this issue must **not**
duplicate.

### The real, shipped P1.1 component API (verified by reading the partials directly)
- **`components/_section.html.erb`** — `render(layout: "components/section", locals: {
  eyebrow: nil, title: nil }) { body }`. Wraps `yield` in `<section class="mb-16"
  data-controller="motion">`; renders an optional Commit Mono eyebrow and an optional `<h2
  class="font-mono text-2xl mb-6">`.
- **`components/_card.html.erb`** — `render(layout: "components/card", locals: { href:,
  image_url: nil }) { body }`. `href` (required) drives a full-card **stretched-link** overlay
  (`link_to "", href, class: "absolute inset-0 rounded-box", tabindex: "-1", "aria-hidden":
  "true"`) rendered **after** `card-body` in DOM order; the overlay is `position: absolute` so it
  paints above any non-positioned sibling content regardless of DOM order. The partial's own
  header comment states the a11y contract explicitly: pointer users get the whole-card click via
  the (aria-hidden, unfocusable) overlay; **keyboard and screen-reader users must reach the same
  destination through a real, labeled link the caller places in the body** — any interactive
  child whose own href *differs* from the card's `href` (e.g. an external CTA) must sit `relative
  z-10` to stay independently clickable above the overlay; a child whose href is the *same* as
  the card's `href` (e.g. a linked title) does not strictly need `z-10` since a pointer click
  landing on the overlay instead of the link still reaches the identical destination. This
  distinction directly drives [R3](#r3--projects-index-card-grid)'s design (linked title, no
  `z-10` needed there; triple-link CTAs, `z-10` needed, mirroring the existing `card-actions
  relative z-10` pattern already used by `projects/index.html.erb` today).
- **`components/_pill.html.erb`** — `render "components/pill", label:, variant: :status`.
  `Pre-Launch → badge-warning`, `Beta → badge-info`, `Live → badge-success`, unrecognized →
  `badge-neutral`.
- **`components/_cta_button.html.erb`** — `render "components/cta_button", label:, href:, style:
  :primary`. `style: :primary` → `btn btn-primary font-mono`; `style: :ghost` → `btn-ghost`.
  Text-only label, no block-content variant.

### `app/views/projects/index.html.erb` today (already migrated by 1180's own R9)
```erb
<%= render layout: "components/section" do %>
  <div class='space-y-6'>
    <% Project.find_each do |project| %>
      <%= render layout: "components/card", locals: { href: project_url(slug: project.slug), image_url: project.image } do %>
        <h2 class='card-title font-mono text-xl'><%= project.title %></h2>
        <div><%= render "components/pill", label: project.status, variant: :status %></div>
        <p class='mb-0'><%= project.description %></p>
        <div class='card-actions relative z-10 mt-2'>
          <%= render "components/cta_button", label: "View Project", href: project_url(slug: project.slug), style: :primary %>
        </div>
      <% end %>
    <% end %>
  </div>
<% end %>
```
Single-column stack (`space-y-6`, no grid), no filter UI, no triple-links — exactly the parts
this issue's [R3](#r3--projects-index-card-grid)/[R4](#r4--filter-by-status) replace.

### `app/views/projects/show.html.erb` today (**not yet migrated** to P1.1 — pre-1180 markup)
```erb
<div class='flex flex-row mb-6 space-x-4'>
  <div class='p-4 w-1/4 ... border rounded shadow'>
    <img src="<%= @project.image %>" ... />
    <p class='text-sm text-[#999] ...'><%= link_to @project.url, @project.url, target: '_blank', rel: 'noreferrer', class: 'link link-hover underline' %></p>
    <p class='text-sm text-[#999] ...'><span class='badge badge-accent'><%= @project.status %></span></p>
  </div>
  <div class='p-4 m-auto border rounded shadow'>
    <h1 class='text-3xl mb-5'><%= @project.title %></h1>
    <div class='prose w-full max-w-none'><%= render_markdown(@project.content) %></div>
  </div>
</div>
```
Uses a hardcoded `text-[#999]` literal-color utility and `badge-accent` (not the `_pill`
partial's status→role mapping) — both retired by this issue's
[R6](#r6--projects-show-page-rewrite). **No test coverage exists for this action at all today**
(`spec/requests/projects_spec.rb` only covers `GET /projects`; there is no `show`-action request
spec) — this issue adds the first one.

### `ProjectsController` / routes today
```ruby
class ProjectsController < ApplicationController
  def index; end
  def show
    @project = Project.find_by(slug: params[:slug])
  end
end
```
`get "projects" => "projects#index", as: :projects`; `get "projects/:slug" => "projects#show",
as: :project`. Controller stays thin (matches `web-presentation.md`'s "controllers stay thin...
views query directly" invariant) — this issue does not add controller-side query logic; the
status filter is read from `params[:status]` directly in the view, matching
`Project.for_home`/`Project.find_each` already being called directly in views, not controllers.

### `index.rss.builder` / `search_index_controller.rb` — confirmed unaffected
`index.rss.builder` uses `project.title`/`description`/`url`/`slug`/`image` only — `xml.link
project.url` is the existing, sole "external project URL" reference, confirming `url` already
functions as the project's canonical outbound "demo/live" link today, independent of this issue.
`SearchIndexController#serialize_project` uses `title`/`url` (→ `project_url(slug:)`, the
**internal** show page, not `project.url`)/`description`/`tags: []` only. Neither file needs any
change for `read_url`/`source_url`.

### The header's active-link convention (reused for the status filter, see R4)
`app/views/layouts/components/_header.html.erb`'s nav links use:
```erb
link_to 'Projects', projects_url, class: current_page?(projects_url) ? 'text-primary cursor-default' : 'link link-hover'
```
This issue's status-filter links follow the same on/off visual convention (`text-primary` +
non-interactive cursor for the active filter, `link link-hover` otherwise) rather than inventing
a new active-state pattern.

### Schema-change tooling (confirmed working command, per #1181's own verified use)
`bundle exec rails generate declare_schema:migration` (interactive — prompts for a migration
name) generates the migration from a `declare_schema` block diff; `--pretend` reports "Database
and models match -- nothing to change" when there is no drift. `db/migrate/20260719004505_add_featured_to_projects_and_posts.rb`
(from #1181) is the most recent proof this exact command works in this repo. `declare_schema`
has no documented column-rename primitive (verified: no `renamed_from`/`rename` mention in the
gem's own README) — reinforcing [R1](#r1--schema-triple-link-fields)'s decision to keep `url`
unchanged rather than attempt a rename through `declare_schema`.

## R1 — Schema: Triple-Link Fields

**Decision: keep `url` exactly as-is (required, unchanged); add two new optional, nullable
columns — `read_url` and `source_url`.**

Design doc §5: *"Triple-link fields — read (article/details) → demo (live URL) → source (repo).
`url` exists; add the others as optional."* Reading this against the actual codebase: `url` is
already the project's outbound "live product" reference everywhere it's used today (the RSS
`<link>`, and the show page's own external link) — i.e., it already fills the **demo** slot.
This issue therefore:

- Does **not** rename, repurpose, or re-validate `url`. No existing code path
  (`index.rss.builder`, `show.html.erb`, the factory, seeds, `project_spec.rb`) changes shape.
  This is a deliberate, additive-only, zero-data-migration-risk choice — `declare_schema` has no
  rename primitive (see [Current State](#current-state-verified)), so a rename would require a
  hand-written `rename_column` migration ahead of the generated one, working against the
  content-domain invariant that `declare_schema` (not hand-edited migrations) is the schema
  source of truth. Reusing `url` in place avoids that entirely.
- Adds, to `app/models/project.rb`'s `declare_schema` block:
  ```ruby
  string :read_url,   limit: 1024, null: true
  string :source_url, limit: 1024, null: true
  ```
  No `validates: { presence: true }` on either — both are genuinely optional per the design doc
  ("optional read/demo/source links"), matching `url`'s own lack of format validation (presence
  only, and only on `url` itself).
- Generates the migration via `bundle exec rails generate declare_schema:migration` (e.g. name it
  `add_read_and_source_links_to_projects`), reviews it adds exactly two nullable string columns
  (no `NOT NULL`, no default), runs `bundle exec rails db:migrate`, regenerates `db/schema.rb`,
  and confirms `declare_schema:migration --pretend` reports no drift afterward.
- **Does not touch `featured`** anywhere in the `declare_schema` block, the generated migration,
  or `db/schema.rb`'s existing `featured` line — it is already correct and shipped.

**Triple-link semantics used throughout this spec:**

| Leg | Source | Presence | Meaning |
|---|---|---|---|
| **Read** | `project.read_url` | optional | A write-up/article about the project (e.g. a blog post) |
| **Demo** | `project.url` | always present (existing required column) | The live product/demo URL |
| **Source** | `project.source_url` | optional | The public repo, when one exists |

Rendering order everywhere in this issue (card, show page) is **read → demo → source**, per the
design doc's own ordering, even though demo is the one leg guaranteed to always render.

## R2 — `Project` Model: `STATUSES` Constant + `by_status` Scope

- Add `STATUSES = %w[Pre-Launch Beta Live].freeze` as a `Project` class constant, and change the
  `status` column's `validates: { inclusion: { in: %w[Pre-Launch Beta Live] } }` to `validates: {
  inclusion: { in: STATUSES } }` — a single source of truth so the filter UI
  ([R4](#r4--filter-by-status)) and the model validation can never drift apart (today they'd be
  two independently-hardcoded copies of the same three-element array).
- Add `scope :by_status, ->(status) { status.present? ? where(status: status) : all }` — used
  directly in `projects/index.html.erb` (matching the existing "views query directly, controllers
  stay thin" convention already used by `Project.find_each`/`Project.for_home`). An unrecognized
  `status` value (e.g. a hand-edited query string) is not specially validated or rescued — AR's
  `where(status: "Foo")` simply returns zero rows, which renders as the same "no results for this
  filter" empty state as a legitimately-empty status (see
  [R5](#r5--empty--coming-soon-states)), never a 500.

## R3 — Projects Index: Card Grid

- Wrap the listing in `components/section` (unchanged wrapper usage) but change the body from
  `space-y-6` to a responsive grid: `grid grid-cols-1 md:grid-cols-3 gap-6` — the same
  Tailwind/DaisyUI utility pair #1181's R3/R4 already established for the home page's Featured
  Projects/Latest Writing grids (no new grid pattern invented).
- Each card, composed via `components/card` (`href: project_url(slug: project.slug), image_url:
  project.image` — **unchanged** from today):
  - **Title as the real link** — `<h2 class="card-title font-mono text-xl"><%= link_to
    project.title, project_url(slug: project.slug) %></h2>` — replacing today's plain (non-linked)
    `<h2>` + separate "View Project" CTA. This is the card's a11y-required "real, labeled link to
    the same destination as the card's own `href`" (see `_card`'s contract, restated in [Current
    State](#current-state-verified)) — now that the CTA-button area holds the triple-links
    instead of a dedicated "View Project" button, the title itself must carry that
    keyboard/screen-reader-reachable duty. No `relative z-10` is required on the title link (its
    destination is identical to the overlay's, so a pointer click landing on either one reaches
    the same place) — this is a deliberate, documented exception to the "give interactive children
    `z-10`" rule, not an oversight.
  - Status pill: `render "components/pill", label: project.status, variant: :status` — unchanged.
  - `project.description` — unchanged, no truncation added.
  - Triple-links, inside `card-actions relative z-10 mt-2` (the existing wrapper class,
    unchanged) — each rendered via `components/cta_button`, shown only when present, in **read →
    demo → source** order:
    ```erb
    <div class='card-actions relative z-10 mt-2'>
      <% if project.read_url.present? %>
        <%= render "components/cta_button", label: "Read", href: project.read_url, style: :ghost %>
      <% end %>
      <%= render "components/cta_button", label: "Demo", href: project.url, style: :primary %>
      <% if project.source_url.present? %>
        <%= render "components/cta_button", label: "Source", href: project.source_url, style: :ghost %>
      <% end %>
    </div>
    ```
    `Demo` (`project.url`) always renders (`style: :primary` — the one guaranteed, primary
    outbound action); `Read`/`Source` render only when their URL is present (`style: :ghost` —
    secondary). This satisfies "shown only when present" for the two optional legs while keeping
    exactly one deterministic, always-present CTA for test assertions to anchor on.
  - `z-10` on `card-actions` is unchanged/reused, not new — it already exists in today's markup
    for exactly this reason (interactive children whose href differs from the card's own `href`
    must stay independently clickable above the stretched-link overlay).
- No new component partial is added for the grid or the triple-links — everything above is
  composed from the four existing P1.1 partials.

## R4 — Filter by Status

- A small filter-links row rendered above the grid (inside or immediately preceding the
  `components/section` body — implementer's call within this shape), one link per
  `Project::STATUSES` entry plus an "All" default:
  ```erb
  <nav class='flex gap-4 mb-6 font-mono text-sm' aria-label='Filter projects by status'>
    <%= link_to 'All', projects_path, class: params[:status].blank? ? 'text-primary cursor-default' : 'link link-hover' %>
    <% Project::STATUSES.each do |status| %>
      <%= link_to status, projects_path(status: status), class: params[:status] == status ? 'text-primary cursor-default' : 'link link-hover' %>
    <% end %>
  </nav>
  ```
  This reuses the header nav's own active/inactive convention verbatim (`text-primary
  cursor-default` vs. `link link-hover` — see [Current State](#current-state-verified)) rather
  than inventing a new one, and needs no new component partial, no new Tailwind token, and no
  Stimulus controller.
- The grid body iterates `Project.by_status(params[:status])` instead of `Project.find_each`
  ([R2](#r2--project-model-statuses-constant--by_status-scope)) — called directly in the view,
  matching the existing controller-thin convention (`ProjectsController#index` stays `def index;
  end`, unchanged).
- This is a **full server-rendered navigation** (a plain `link_to` with a query string), not a
  client-side/JS filter — see [Testing Strategy](#testing-strategy) for why this keeps the whole
  feature at request-spec coverage.
- No RSS/search-index change: `index.rss.builder` and `/search-index.json` are unaffected by
  `params[:status]` (they don't read it) — confirmed in
  [R7](#r7--rss--search-index-no-change-expected).

## R5 — Empty / Coming-Soon States

Two distinct cases, both rendered in place of the grid (never an empty grid with no
explanation):

1. **Table-wide empty** (`Project.count.zero?` — a brand-new database before `db/seeds.rb` runs):
   a generic message, e.g. *"Projects are coming soon — check back shortly."* No filter row is
   shown in this case either (there is nothing to filter).
2. **Filtered-empty** (the table has rows, but `Project.by_status(params[:status])` returns none
   for the selected status — including an unrecognized/hand-edited `status` query value, per
   [R2](#r2--project-model-statuses-constant--by_status-scope)): a narrower message, e.g. *"No
   {status} projects yet."*, plus the filter row itself (including the working "All" link) stays
   visible so the visitor can clear the filter.

Both states render inside the same `components/section` wrapper (so spacing/motion stay
consistent with the populated case) — only the grid's contents change, per case 1 vs. 2 above;
case 1 additionally omits the filter row.

## R6 — Projects Show Page Rewrite

Rebuild `app/views/projects/show.html.erb` onto the P1.1 component set, retiring all pre-1180
raw markup (`text-[#999]`, `badge-accent`, the hand-rolled two-column flex layout):

- Wrap the page body in `components/section` (no `eyebrow`/`title` locals needed — the page's own
  `<h1>` carries the heading) purely for the consistent `mb-16` spacing + scroll-fade-in motion
  parity with every other section-wrapped page.
- `<h1 class="font-mono text-3xl mb-4"><%= @project.title %></h1>` — Commit Mono, matching
  `projects/index.html.erb`'s own existing `<h1>` treatment (`font-mono text-3xl mb-4`) for
  visual consistency between the two pages.
- Status pill: `render "components/pill", label: @project.status, variant: :status` — replacing
  the hardcoded `badge badge-accent` span.
- Triple-links, identical read→demo→source conditional composition as
  [R3](#r3--projects-index-card-grid) (same three `cta_button` calls, `Demo` always present,
  `Read`/`Source` conditional) — replacing the old single `link_to @project.url, @project.url,
  target: '_blank', rel: 'noreferrer'` external link.
- Project image: `image_tag @project.image, alt: @project.title` — kept, but restyled with
  DaisyUI token classes (`border-base-300`, `bg-base-100`) instead of the plain `border rounded
  shadow` literal-ish utility mix, so it visually matches the token-cleaned rest of the page (no
  hardcoded hex anywhere on this page after this change).
- Project markdown body: `render_markdown(@project.content)` inside `.prose w-full max-w-none` —
  unchanged (already token-agnostic, no hardcoded colors to clean up here).
- `set_meta_tags(title: @project.title, description: @project.description)` — unchanged.

## R7 — RSS / Search-Index: No Change Expected

- `app/views/projects/index.rss.builder` — confirmed (by reading the file) to reference only
  `project.title`/`description`/`url`/`slug`/`image`; `read_url`/`source_url` are never read.
  No change.
- `app/controllers/search_index_controller.rb#serialize_project` — confirmed (by reading the
  file) to reference only `title`/`project_url(slug:)`/`description.truncate(160)`/`tags: []`;
  `read_url`/`source_url`/`url` are never read. No change.
- If implementation finds either file needs a change for some reason not anticipated here, that
  deviation must be called out explicitly in the PR description — this spec does not expect it.

## R8 — Home / `featured` Compatibility: No Change

- `Project.featured` / `Project.for_home` ([P1.2 #1181](../specs/1181-home-hero-redesign.md) R2)
  are untouched by this issue's schema change (additive-only —
  [R1](#r1--schema-triple-link-fields)) and untouched by its view changes (`welcome/index.html.erb`
  is not edited by this issue — see [Out of Scope](#out-of-scope)).
- Acceptance requires re-running (not just reading) #1181's own `spec/requests/welcome_spec.rb`
  and `spec/models/project_spec.rb` `.featured`/`.for_home` examples after this issue's migration
  lands, confirming they remain green — proof that adding `read_url`/`source_url` doesn't
  perturb `featured`'s behavior (new nullable columns cannot affect existing scope/query
  behavior, but this is the cheap, concrete way to confirm it rather than asserting it from
  reasoning alone).

## R9 — Update `content-domain` Architecture Doc

`docs/architecture/sub-systems/content-domain.md`:
- **Anchor Files**: no new files (the new columns/scope live in the existing
  `app/models/project.rb`).
- **Public Contract**: add `Project.by_status` to the Exports list, next to
  `Post.featured`/`Project.featured`. Note `Project::STATUSES` as the shared status-values
  constant.
- **Key Invariants**: add a bullet: *"`read_url`/`source_url` are optional (nullable) —
  `url` remains the one required outbound link (the 'demo' leg of the read→demo→source triple-link
  pattern); rendering order is read → demo → source, `Demo` always present, `Read`/`Source`
  conditional on presence."*
- **State Owned**: no change (still the same table; both new columns are additive).
- No new subsystem, no dependency-graph change.

## R10 — Web-Presentation Doc: Minor Update

`docs/architecture/sub-systems/web-presentation.md`'s Anchor Files entry for
`app/views/components/` already lists the four shared partials generically — no change needed
there. Add one line under Known Limitations reiterating (not fixing) the existing `find_by` vs.
`find_by!` note stays accurate post-this-issue (unchanged behavior, just confirming the note
doesn't need updating since this issue doesn't touch that code path).

## Testing Strategy

These are server-rendered pages with **zero client-side JS behavior** (the status filter is a
plain `link_to` full-page navigation, not a Stimulus-driven live filter) — request + view + model
specs give full, sufficient coverage. No Capybara/system specs are added by this issue.

- **Model specs** (`spec/models/project_spec.rb`): schema/column specs for `read_url`/
  `source_url` (nullable string, `limit: 1024`, no presence validation), `Project::STATUSES`
  constant value, and `Project.by_status` (returns matching-status projects only; returns all
  projects when `status` is blank; returns none for an unrecognized status). Existing
  `.featured`/`.for_home` examples are re-run, not rewritten.
- **Request specs** (`spec/requests/projects_spec.rb`, extending the existing `GET /projects`
  coverage, plus new `GET /projects/:slug` coverage — today entirely absent):
  - Grid renders `grid-cols-1 md:grid-cols-3` classes.
  - Card title is a real `<a>` to the project's own show path (not just the stretched-link
    overlay).
  - Triple-link presence/absence: a project with all three URLs renders three `cta_button`s
    (`Read`/`Demo`/`Source`, in that DOM order); a project with only `url` set renders exactly one
    (`Demo`, `.btn-primary`); `Read`/`Source` never render when their URL is `nil`.
  - Status filter: `GET /projects?status=Live` renders only `Live` projects;
    `GET /projects?status=Live` marks the "Live" filter link active (`text-primary
    cursor-default`) and "All" inactive; `GET /projects` (no param) marks "All" active.
  - Empty states: zero projects in the table renders the table-wide empty message and no filter
    row; some projects but zero matching the selected status renders the filtered-empty message
    plus a working "All" link.
  - `GET /projects/:slug` (new): renders the status pill with the correct badge role, renders the
    same conditional triple-links as the index card, renders the project's markdown content, and
    returns `200`.
- **Factory** (`spec/factories/project.rb`): `read_url`/`source_url` stay unset (`nil`) by
  default — specs needing a populated triple-link project pass them explicitly (e.g.
  `create(:project, read_url: "https://example.com/writeup", source_url:
  "https://github.com/example/repo")`), matching the factory's existing minimal-by-default style.
- **No system specs.** If a future issue adds live, no-reload client-side filtering (a Stimulus
  controller hiding/showing cards without navigation), *that* issue is the one that would need
  Cuprite/system-spec coverage (the infra exists on `main` since #1187) — not this one, since
  this issue's filter has no client-side behavior to exercise.

## Approach (Implementation Guidance)

Spec-level guidance for the **code** agent — not a substitute for re-verifying the current
`declare_schema`/Tailwind/DaisyUI state at implementation time, per this repo's own standing
practice.

1. Confirm working in this issue's worktree/branch, based on current `main` (P1.1 #1180 and P1.2
   #1181 both already merged in).
2. Add `Project::STATUSES` and update the `status` validation to reference it
   ([R2](#r2--project-model-statuses-constant--by_status-scope)). Add `read_url`/`source_url` to
   the `declare_schema` block ([R1](#r1--schema-triple-link-fields)). Run `bundle exec rails
   generate declare_schema:migration` (interactive — supply a descriptive name, e.g.
   `add_read_and_source_links_to_projects`), review the generated migration adds exactly the two
   nullable string columns, `bundle exec rails db:migrate`, regenerate `db/schema.rb`. Confirm
   `--pretend` reports no remaining drift and that `featured`'s own migration/column are
   untouched.
3. Add `Project.by_status` scope.
4. Rewrite `app/views/projects/index.html.erb` per
   [R3](#r3--projects-index-card-grid)/[R4](#r4--filter-by-status)/[R5](#r5--empty--coming-soon-states).
5. Rewrite `app/views/projects/show.html.erb` per [R6](#r6--projects-show-page-rewrite).
6. Confirm (do not need to change) `index.rss.builder` and `search_index_controller.rb` per
   [R7](#r7--rss--search-index-no-change-expected).
7. Update `spec/factories/project.rb` (add commented-optional `read_url`/`source_url`, left unset
   by default) and add/extend specs per [Testing Strategy](#testing-strategy).
8. Update `docs/architecture/sub-systems/content-domain.md` per
   [R9](#r9--update-content-domain-architecture-doc) and confirm
   `docs/architecture/sub-systems/web-presentation.md` per
   [R10](#r10--web-presentation-doc-minor-update).
9. Verify: `bundle exec rubocop` and `bundle exec rspec` (`ci-gate`) green; `bundle exec rails
   generate declare_schema:migration --pretend` reports no drift; re-run #1181's own
   `spec/requests/welcome_spec.rb` and `spec/models/project_spec.rb` `.featured`/`.for_home`
   examples to confirm no regression ([R8](#r8--home--featured-compatibility-no-change));
   `yarn build:css` unaffected (no new Tailwind classes beyond the existing grid/flex/spacing
   utility vocabulary already in use since #1181). Manually verify in-browser: switch all six
   themes on `/projects` and `/projects/:slug` and confirm the grid/cards/pills/CTAs all re-theme
   correctly; resize to a phone-width viewport and confirm the grid collapses to one column;
   click through the status filter links and confirm the active/inactive states match the header
   nav's own convention; confirm a project with zero optional links shows exactly one CTA
   (`Demo`) and a project with all three shows three, in read→demo→source order.

## Acceptance Criteria

- [ ] `Project` has `read_url` and `source_url` (nullable string, `limit: 1024`, no presence
      validation), added via `declare_schema` + generated migration, with `db/schema.rb`
      regenerated and `declare_schema:migration --pretend` reporting no drift (R1)
- [ ] `Project`'s existing `featured` column/migration/scopes are untouched — no duplicate
      migration, no re-declaration (R1, R8)
- [ ] `Project::STATUSES` is the single source of truth for valid status values, referenced by
      both the model's own inclusion validation and the index page's filter links (R2)
- [ ] `Project.by_status(status)` returns only matching-status projects when `status` is present,
      all projects when blank, and none (not an error) for an unrecognized value (R2)
- [ ] `/projects` renders a responsive grid (`grid-cols-1` below `md`, `md:grid-cols-3` at/above)
      of cards, each composed via `components/card` + `components/pill` (`variant: :status`) +
      `components/cta_button` (R3)
- [ ] Each card's title is a real, focusable `<a>` linking to the project's own show page (not
      just the card's stretched-link overlay) (R3)
- [ ] Each card shows the "Demo" CTA (`project.url`) always; "Read" (`project.read_url`) and
      "Source" (`project.source_url`) render only when present, in read → demo → source order (R3)
- [ ] `/projects` renders a status-filter row (All / Pre-Launch / Beta / Live) using the same
      active/inactive link convention as the header nav; `?status=X` filters the grid to only
      that status (R4)
- [ ] A project table with zero rows renders a table-wide "coming soon" message with no filter row
      (R5)
- [ ] A non-empty project table with zero rows matching the selected status renders a
      filtered-empty message while keeping the filter row (including a working "All" link)
      visible (R5)
- [ ] `/projects/:slug` is rewritten onto `components/section` + `components/pill` +
      `components/cta_button`, with no remaining hardcoded `text-[#999]`/`badge-accent`
      literal-color markup (R6)
- [ ] `/projects/:slug` renders the same conditional read→demo→source triple-links as the index
      card (R6)
- [ ] `index.rss.builder` and `/search-index.json` are unaffected (no reference to
      `read_url`/`source_url`, `project.url` usage unchanged) (R7)
- [ ] `#1181`'s own `welcome/index.html.erb`, `Project.featured`, and `Project.for_home` request/
      model specs remain green after this issue's migration (R8)
- [ ] `docs/architecture/sub-systems/content-domain.md`'s Public Contract and Key Invariants
      reflect `Project.by_status`, `Project::STATUSES`, and the read/demo/source column
      semantics (R9)
- [ ] No changes to any P1.1 component partial, Stimulus controller, or
      `application.tailwind.css` token/theme definition (this issue is a pure consumer)
- [ ] No changes to `welcome/index.html.erb` (home page's own Featured Projects composition is
      untouched)
- [ ] No system/Capybara specs added (the filter has no client-side JS behavior to exercise)
- [ ] Existing `ci-gate` (`lint` + `test`) remains green

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns)
and the scribe's own delegation rules:

- **Implementation** (all of R1–R10: the `read_url`/`source_url` migration, the `STATUSES`
  constant + `by_status` scope, the full `index.html.erb`/`show.html.erb` rewrites, the
  `content-domain.md`/`web-presentation.md` updates, the new/updated specs, opening the PR):
  delegate to the **code** agent.
- **GitHub Issues lifecycle** (moving #1182's board status, closing on merge): delegate to the
  **orchestrator** — this spec does not perform those operations.
- **Manual in-browser verification** of theme re-rendering and responsive breakpoints (no
  automated visual-regression coverage exists in this repo): part of the implementer's own
  pre-PR verification (per the `verify` skill).
- **Final exact wording** for the empty/coming-soon copy, the filter row's exact placement
  (inside vs. immediately above the `components/section` body), and whether the show page's image
  block gets any further layout polish beyond the token-class swap in
  [R6](#r6--projects-show-page-rewrite): implementer/visual-QA call within the constraints
  already stated — not a decision requiring further scribe/user sign-off.

## Open Questions

1. **Whether to backfill `read_url`/`source_url` on the two seeded projects
   (`not-my-real-email`, `the-game-about-people`) in `db/seeds.rb`.** Both new columns are
   optional and default to `nil`, so leaving the seeds unchanged is safe — cards for both
   projects would render only the "Demo" CTA post-merge, which is a fully valid, tested state
   ([R3](#r3--projects-index-card-grid)). Not blocking; James can add real `read_url`/`source_url`
   values to either seed (or to `db/seeds.rb` itself) post-merge if desired.
2. **Exact empty/coming-soon copy.** *"Projects are coming soon — check back shortly."* /
   *"No {status} projects yet."* are placeholders in the shape [R5](#r5--empty--coming-soon-states)
   requires — final wording is an implementer/visual-QA call, not a functional gap.
3. **`ProjectsController#show`'s `find_by` vs. `find_by!`.** Pre-existing inconsistency (see
   [Out of Scope](#out-of-scope)), not introduced by this issue. Worth its own small ticket
   (align with `blog#show`'s `find_by!` + a proper 404) but not folded into this design-system
   pass.
4. **Extracting a shared `project_card` partial** so `projects/index.html.erb` and
   `welcome/index.html.erb`'s Featured Projects section converge on one composition instead of
   two independently-maintained copies of the same pattern. Reasonable future cleanup, not
   required by this spec (see [Out of Scope](#out-of-scope)) — flagging so it isn't lost.

## Changelog

### Version 1 - 2026-07-19
**Source Issue:** bitidev/jamesebentier.com#1182
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification for the projects page redesign: `Project` gains `read_url`/`source_url`
  (optional, nullable) to complete the read→demo→source triple-link pattern, reusing the
  existing required `url` column as the "demo" leg rather than renaming it (additive-only,
  zero-data-migration-risk, since `declare_schema` has no rename primitive)
- Confirmed `featured`/`Project.for_home` (#1181/P1.2) are already shipped on `main` at this
  worktree's base commit and are explicitly not re-declared or re-migrated by this issue
- Card grid (`grid-cols-1`/`md:grid-cols-3`), server-rendered status filter (`?status=`, reusing
  the header nav's own active-link convention), and table-wide vs. filtered-empty "coming soon"
  states — all composed from the four existing P1.1 partials plus page-local Tailwind/DaisyUI
  utility markup for the filter row (no new shared component)
- Resolved the card's post-triple-link a11y requirement (a real, keyboard/screen-reader-reachable
  link to the show page) by making the card title itself the link, rather than keeping a
  redundant separate "View Project" CTA alongside three new triple-link CTAs
- Full `projects/show.html.erb` rewrite onto `components/section`/`pill`/`cta_button`, retiring
  its pre-1180 hardcoded `text-[#999]`/`badge-accent` markup — this page was not touched by 1180's
  own migration and is the last projects-related view still on raw markup
- Verified `index.rss.builder` and `search_index_controller.rb` need no change (neither
  references the new columns)
- Testing strategy: request/view/model specs only, no system specs — the status filter is a
  plain server-rendered link, not client-side JS
- Flagged four non-blocking open items: seed-data backfill for the new optional links, exact
  empty-state copy, the pre-existing `find_by`/`find_by!` show-action inconsistency (not
  introduced here), and a possible future shared `project_card` partial extraction

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the
code agent.

---
