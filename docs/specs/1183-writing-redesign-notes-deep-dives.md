<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1183 -->
<!-- Last Updated: 2026-07-19T00:00:00+02:00 -->
<!-- Description Hash: 5f4f36ab2d7d -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# P1.4 — Writing Redesign + Notes/Deep Dives Content Model

**Issue:** [bitidev/jamesebentier.com#1183](https://github.com/bitidev/jamesebentier.com/issues/1183)
**Parent epic:** [#1179 — 2026 Site Redesign, Phase 1](https://github.com/bitidev/jamesebentier.com/issues/1179)
**Branch:** `personal/jebentier/issue-1183-p14-writing-redesign-notes-deep-dives`
**Board:** org `bitidev` project — Status: In Progress; Assignee: `jebentier`
**Design:** [`docs/design/redesign-2026.md`](../design/redesign-2026.md) §4 (Information architecture),
§5 (Content model, Note vs. Deep Dive editorial guidelines)
**Blocked by:** [P1.1 — #1180](./1180-design-system-pass-refined-terminal.md) — **MERGED**
(`main` @ `9687463`) — this spec builds against the real, shipped component API, not a
hypothetical one.
**Consumes:** [P1.2 — #1181](./1181-home-hero-redesign.md)'s `Post.featured` column and
`Post.for_home` query — **MERGED** (`main` @ current HEAD `3ac7288`, itself a merge of P1.8/
#1187) — verified directly in [Current State](#current-state-verified); this issue does
**not** redeclare `featured`, per 1181's own coordination note.
**Siblings (not touched, not blocking):** P1.3 — Projects redesign (#1182, in progress —
its worktree is explicitly out of bounds for this spec); P1.6 — Medium syndication (#1185,
not started — owns `medium_url`/`canonical_url`, out of scope here, see
[Out of Scope](#out-of-scope)).

## Overview

This is the writing/content-model redesign for the 2026 refresh. Today `/blog` and
`/blog/:slug` render `Post` records through pre-P1.1 markup (`bg-white`, `text-black`,
hardcoded `shadow`/`badge-accent` classes) with no content-type distinction, no excerpt, and
no reading time. This issue does four things:

1. **Introduces the Notes vs. Deep Dives content model** — `Post.kind` (`note` | `deep_dive`),
   `Post#excerpt`, and a computed `Post#reading_time` — per design doc §5.
2. **Renames the public route** `/blog` → `/writing` (clean refresh, no redirect, per the
   issue's own explicit instruction and the design doc's decision log) and renames the
   controller/views accordingly.
3. **Migrates `/writing`'s index and article pages onto the shipped P1.1 component library**
   (`components/section`/`card`/`pill`/`cta_button`), the same migration
   `projects/index.html.erb` already went through in P1.1 — `blog/index.html.erb` and
   `blog/show.html.erb` are the last two unmigrated content-facing views in the app (verified
   in [Current State](#current-state-verified)).
4. **Adds the Note vs. Deep Dive editorial guidelines** (design doc §5's table + heuristic)
   as a section on the `/writing` index page, and a kind filter driven by a plain
   query-string parameter (no client-side JS — see [D10](#d10--kind-filter-is-server-rendered-no-js)).

## Goal

A developer implementing this spec ships: `Post.kind`/`Post#excerpt` as real, validated,
backfilled schema; `Post#reading_time` as a derived (non-stored) value; `/writing` and
`/writing/:slug` rendering through the same shared component partials every other migrated
page uses, with tags/excerpt/date/reading-time/kind all visible; a filterable index (Notes /
Deep Dives / All); and the editorial guidelines readers and the future writer both need. A
reviewer can confirm: the old `/blog` route is gone (not redirected), nothing on `/writing`
invents a new color/token/component outside the sanctioned pill amendment
([D7](#d7--pill-component-amendment-variant-kind)), `#1181`'s home page and `#1187`'s search
index and keyboard-nav layer all keep working unmodified in behavior (only two known,
pre-identified test assertions in `#1187`'s own suite must be updated to match the new,
intentionally-improved reality — see [R9](#r9--reconcile-1187s-search-index-tests)), and the
existing ten posts read, unambiguously, as Deep Dives.

## In Scope

- `Post` schema additions: `kind` (string enum-like column, `note`/`deep_dive`), `excerpt`
  (string), both via `declare_schema` + a generated `declare_schema:migration`, plus a
  one-time data backfill for `excerpt` (see [R1](#r1--schema-kind-and-excerpt)).
- `Post#reading_time` — computed instance method, not a column (see
  [D5](#d5--readingtime-is-computed-not-stored)).
- `Post.by_kind(kind)` scope (whitelisted filter, safe against invalid/blank input) and
  `Post::KINDS` / `Post#kind_label` (see [R2](#r2--post-model-additions)).
- Route rename `/blog` → `/writing`, `/blog/:slug` → `/writing/:slug` — **path only**, route
  helper names (`posts_path`/`post_path`/`posts_url`/`post_url`) unchanged (see
  [D1](#d1--route-rename-is-path-only-helper-names-are-untouched)).
- `BlogController` → `WritingController` rename (file + class), `app/views/blog/` →
  `app/views/writing/` rename, both views rewritten onto the P1.1 component library.
- `/writing` index: kind filter (`?kind=note` / `?kind=deep_dive` / no param = all), one
  `components/card` per post (title, excerpt, date, reading time, tags via
  `components/pill` `variant: :tag`, kind badge via the new `components/pill`
  `variant: :kind`), plus the editorial guidelines section (design doc §5's table +
  heuristic, verbatim).
- `/writing/:slug` article page: typography polish (Commit Mono `<h1>`, metadata row: kind
  badge, tags, date, reading time — all via shared components), Inter body (already the
  global default, no change needed there).
- `components/_pill.html.erb` amendment: new `variant: :kind` (see
  [D7](#d7--pill-component-amendment-variant-kind)) — the **one** sanctioned, additive
  change to a P1.1 partial this issue makes.
- Header/footer nav copy: "Blog" → "Writing" label text (route helper names, hrefs, and
  `data-nav-target="writing"` are already correct today — see
  [Current State](#current-state-verified)) — see [D8](#d8--nav-copy-rename-blog--writing).
- `welcome/index.html.erb`'s Latest Writing card: swap the `post.description` stand-in for
  the real `post.excerpt` now that it exists (see
  [R7](#r7--home-latest-writing-consistency-1181-follow-through)) — a small, low-risk,
  same-file-owner-going-forward completion of what 1181's own Out of Scope section
  explicitly deferred to this issue.
- Reconciling `#1187`'s two now-superseded `search_index_controller` test assertions (see
  [R9](#r9--reconcile-1187s-search-index-tests)) and simplifying the controller's
  `has_attribute?(:excerpt)` bridge now that the column permanently exists (see
  [D6](#d6--search_index_controller-simplify-the-nowalwaystrue-fallback)).
- Updating `docs/architecture/sub-systems/content-domain.md` and
  `docs/architecture/sub-systems/web-presentation.md` and `docs/architecture/overview.md`'s
  file catalog (renamed files) per the scribe's architecture-doc ownership rule.
- New request/model specs; updating the existing specs enumerated in
  [Testing Strategy](#testing-strategy).

## Out of Scope

- **`medium_url` / `canonical_url` on `Post`.** Design doc §5 lists these under "`Post`"
  additions, but the phased roadmap (§7) splits them into a separate issue — **P1.6 — Medium
  syndication, #1185** — which is not started. This issue's own "ADLC delivers" list does not
  mention them either. Not added here.
- **`Post.featured` / `Post.for_home`.** Already shipped by P1.2 (#1181) — verified present in
  [Current State](#current-state-verified). This issue is a pure consumer; no redeclaration,
  no scope/behavior change (Notes remain eligible for `featured`/`for_home` exactly like Deep
  Dives always were — `kind` is orthogonal to curation, see
  [R2](#r2--post-model-additions)).
- **P1.3's territory** (#1182, in progress elsewhere — do not enter that worktree): the
  Projects grid/filter UI, triple-link fields, and `projects/show.html.erb`'s own
  (still-unmigrated) typography pass are untouched here.
- **`Blog::Renderer` / `BlogHelper`'s markdown-body rendering** (`lib/blog/renderer.rb`,
  `app/helpers/blog_helper.rb`). These are shared with `Project#content` rendering
  (`projects/show.html.erb` also calls `render_markdown`) — verified by grep in
  [Current State](#current-state-verified). "Typography polish" in this issue means the
  **article page's own chrome** (`<h1>`, metadata row) inside `writing/show.html.erb`, not
  the shared, cross-cutting markdown-body renderer, which stays untouched to avoid a
  needless merge-conflict surface with P1.3's own in-flight typography work on the Project
  side of the same shared file. Neither the module name (`Blog::Renderer`) nor the helper
  name (`BlogHelper`) is renamed for the same reason — renaming a two-consumer shared utility
  is a cross-cutting call neither this issue nor P1.3 alone should make unilaterally.
- **Moving `public/blog/` (markdown files + images) to `public/writing/`.** The public *route*
  changes; the internal file-storage/asset path does not. See
  [D2](#d2--publicblog-storage-path-is-unchanged).
- **A JS-driven kind filter, or any new Stimulus controller/system spec for it.** The filter
  is plain server-rendered query-string links. See
  [D10](#d10--kind-filter-is-server-rendered-no-js).
- **A dedicated `/writing/guidelines` (or similar) route.** The editorial guidelines render
  as a section on the existing `/writing` index — no new entry in the design doc's own IA
  route table (§4). See [D9](#d9--editorial-guidelines-live-on-the-writing-index-no-new-route).
- **Backfilling real, hand-written `excerpt` copy for the ten existing posts beyond the
  mechanical `description`-copy backfill in [R1](#r1--schema-kind-and-excerpt).** Writing a
  better, bespoke one-two-line teaser for each of the ten existing Deep Dives is an editorial
  task for James, not a code deliverable — flagged in [Open Questions](#open-questions).
- **Re-classifying any existing post as a Note.** The issue and design doc are explicit: *all*
  existing posts backfill to `deep_dive`. Whether any of the ten should actually read as a
  Note is an editorial call, not this issue's to make.

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`, only in
`jamesebentier.com-issue-1183`. Never touch the `#1182` worktree, `jb-brown` / `Invoca-ADLC`
remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against this worktree (branch
`personal/jebentier/issue-1183-p14-writing-redesign-notes-deep-dives`, currently tracking
`origin/main` at `3ac7288` — P1.8/#1187's merge commit, which itself sits on top of P1.1/#1180
and P1.2/#1181) as of 2026-07-19.

### `Post` today (`app/models/post.rb`, `db/schema.rb`)
```ruby
declare_schema id: :uuid, default: 'gen_random_uuid()' do
  string :slug,        limit: 255,  null: false, validates: {...}, index: { unique: true }
  string :title,       limit: 1024, null: false, validates: { presence: true }
  string :description, limit: 1024, null: false, validates: { presence: true }
  string :keywords,    limit: 1024, null: false, validates: { presence: true }
  string :image,       limit: 1024, null: false, default: ""
  string :file_path,   limit: 1024, null: false, validates: { presence: true }
  json   :tags, null: false, default: []
  datetime :published_at, null: false, validates: { presence: true }
  boolean :featured, null: false, default: false
end

scope :published, -> { where(published_at: ..Time.zone.now) }
scope :featured, -> { where(featured: true) }
def self.for_home(limit: 3) ... end   # curated-first/chronological-fallback (1181 R2)
def content ... end                    # reads Rails.public_path.join('blog', file_path)
```
**No `kind`, `excerpt`, or `reading_time` exists today** — confirmed directly against the
model and `db/schema.rb`'s `create_table "posts"` block. `featured`, `tags`, `scope
:featured`, and `for_home` **already exist** (shipped by #1181) — this issue must not
redeclare them, only consume them.

### Routes today (`config/routes.rb`)
```ruby
get "blog"           => "blog#index",       as: :posts
get "blog/:slug"     => "blog#show",        as: :post
```
`BlogController` is two bare actions (`index; end`, `show` does `Post.find_by!(slug:
params.expect(:slug).downcase)`). `app/views/blog/index.html.erb`, `index.rss.builder`,
`show.html.erb` exist; **neither view has been migrated to the P1.1 component library** —
both still use pre-redesign markup (`bg-white`, `text-black`, `text-[#999]`, hardcoded
`badge-accent`), unlike `projects/index.html.erb`, which P1.1's own R9 already migrated as
its reference implementation. `projects/show.html.erb` is *also* still unmigrated — that is
explicitly P1.3's (#1182) job, not this issue's.

### The header/footer already anticipated this rename
`app/views/layouts/components/_header.html.erb` (lines 5-12) — **verbatim, load-bearing
comment already in the codebase**:
> "`data-nav-target` attributes... 'writing' (not 'blog') matches the design doc's target IA
> name, so a future /blog -> /writing route rename requires zero keyboard-layer changes.
> Rails' own root_url/posts_url/projects_url/resume_path remain the single source of the
> actual href — no URL literal here."

Concretely: `link_to 'Blog', posts_url, ..., data: { nav_target: 'writing' }` — the route
helper name (`posts_url`) and the `data-nav-target` value (`"writing"`) are **already**
correct for the post-rename world; only the **path string** (`"blog"` → `"writing"`) and the
**visible label text** (`'Blog'` → `'Writing'`) need to change. This is strong, direct
evidence for [D1](#d1--route-rename-is-path-only-helper-names-are-untouched). The footer
(`_footer.html.erb` lines 23, 46-48) has the same "Blog" label text (nav link + RSS feed
link/title attr) needing the same copy update.

### `search_index_controller.rb` already has a forward-compatible excerpt bridge
```ruby
def serialize_post(post)
  excerpt = post.has_attribute?(:excerpt) ? post.excerpt : post.description
  { title: post.title, url: post_url(slug: post.slug), excerpt: excerpt, tags: post.tags, type: "post" }
end
```
Added defensively by #1187 *ahead of* this issue, with a comment explicitly naming P1.4/this
worktree. Once `Post#excerpt` exists, `has_attribute?(:excerpt)` is permanently `true` and
this branch stops firing — **no code change is functionally required** for the search index
to start preferring `excerpt`. However, `spec/requests/search_index_spec.rb` has **two**
assertions that hard-code the *pre-1183* state and will start failing/become false the moment
this column ships — see [R9](#r9--reconcile-1187s-search-index-tests)) — and the now
permanently-true `has_attribute?` branch is worth simplifying away, see
[D6](#d6--search_index_controller-simplify-the-nowalwaystrue-fallback).

### The real, shipped P1.1 component API (verified by reading the partials directly)
Identical to what 1181 verified and shipped against — see that spec's own [Current State](
./1181-home-hero-redesign.md#current-state-verified) for the full write-up of
`components/_section`, `components/_card`, `components/_cta_button`. Repeating only the
`_pill` contract here, since this issue amends it:

```
render "components/pill", label:, variant: :tag   # default
```
`variant: :status` → `Project#status` badge-role map (`Pre-Launch → badge-warning`, `Beta →
badge-info`, `Live → badge-success`, unrecognized → `badge-neutral`). `variant: :tag`
(default) → neutral `badge-outline`, used today for nothing yet in production markup (1180's
own Component API doc names this variant as reserved for `Post#tags`, "exercised by P1.4, not
[1180]"). **No `:kind` variant exists yet** — this issue adds one, see
[D7](#d7--pill-component-amendment-variant-kind).

### `projects/index.html.erb` — the existing, shipped reference implementation this issue's
### `/writing` index composition follows
```erb
<h1 class='font-mono text-3xl mb-4'>Recent Projects</h1>
<%= render layout: "components/section" do %>
  <div class='space-y-6'>
    <% Project.find_each do |project| %>
      <%= render layout: "components/card", locals: { href: project_url(...), image_url: project.image } do %>
        <h2 class='card-title font-mono text-xl'><%= project.title %></h2>
        <div><%= render "components/pill", label: project.status, variant: :status %></div>
        <p class='mb-0'><%= project.description %></p>
        <div class='card-actions relative z-10 mt-2'>
          <%= render "components/cta_button", label: "View Project", href: project_url(...), style: :primary %>
        </div>
      <% end %>
    <% end %>
  </div>
<% end %>
```
`blog/index.html.erb`'s current `<h1 class='text-3xl mb-4'>` (no `font-mono`) is itself
inconsistent with this pattern — part of what "typography polish" fixes.

### `public/blog/` storage — 10 real markdown files, 7 embed `/blog/images/*` URLs in their bodies
```
$ ls public/blog/*.md | wc -l
10
$ grep -l 'blog/images' public/blog/*.md | wc -l
7
```
These are real, already-served static asset URLs embedded directly in already-published
markdown body content (e.g. `![...](/blog/images/heroku-terraform-configuration.webp)`).
This is the concrete evidence behind [D2](#d2--publicblog-storage-path-is-unchanged).

### `db/seeds.rb`'s `Post` loop
```ruby
Dir[File.expand_path('../public/blog/*.md', __dir__)].each do |file|
  data = YAML.safe_load_file(file, symbolize_names: true, permitted_classes: [Date])
  Post.find_or_initialize_by(slug: (data[:slug] || data[:title].parameterize).downcase).update!(
    file_path: File.basename(file), **data
  )
end
```
`data` is the YAML front matter hash; a key **absent** from front matter is never passed to
`update!` at all (Ruby hash double-splat), so it is a true no-op on that attribute — it does
**not** overwrite a previously-set/backfilled DB value with `nil`. This is the mechanism that
makes the `excerpt` backfill in [R1](#r1--schema-kind-and-excerpt) durable across repeated
`db:seed` runs even though none of the ten existing markdown files' front matter has an
`excerpt:` key yet.

### Existing test coverage this issue must reconcile with
No `spec/requests/blog_spec.rb` or `spec/views/**` exists today — `/blog` currently has **zero**
request/view-spec coverage (confirmed via `find spec -iname '*blog*'` returning nothing), so
this issue is *adding* coverage from scratch for `/writing`, not migrating existing specs.
Three **existing** files do assert against current `Post`/nav state and need reconciling:
- `spec/factories/post.rb` — no `kind`/`excerpt` today; every `create(:post)` call site
  (currently `post_spec.rb`, `welcome_spec.rb`, and several `spec/system/*` files) will start
  failing `excerpt` presence validation the moment [R1](#r1--schema-kind-and-excerpt) ships,
  unless the factory is updated in the same change — see
  [Testing Strategy](#testing-strategy).
- `spec/requests/header_nav_spec.rb:33` — asserts nav link text
  `include("Home", "Blog", "Projects", "Resume")` — breaks under
  [D8](#d8--nav-copy-rename-blog--writing).
- `spec/system/keyboard_nav_no_js_spec.rb:47` — `within("header") { click_link "Blog" }` —
  breaks under the same rename. (`keyboard_nav_normal_navigation_spec.rb`'s "g w... writing
  (blog index) URL" test asserts via `posts_path`/`have_current_path`, not literal text — it
  keeps passing unmodified; only its comment is stale afterward, non-blocking.)
- `spec/requests/search_index_spec.rb` — two assertions hard-code the pre-`excerpt` world —
  see [R9](#r9--reconcile-1187s-search-index-tests).

---

## Decisions

### D1 — Route rename is path-only; helper names are untouched
`config/routes.rb` changes only the path segment:
```ruby
get "writing"        => "writing#index", as: :posts
get "writing/:slug"  => "writing#show",  as: :post
```
`as: :posts` / `as: :post` (and therefore every `posts_path`/`posts_url`/`post_path`/
`post_url` call site — header, footer, `welcome/index.html.erb` (#1181), `search_index_
controller.rb`, both RSS builders, every keyboard-nav/system spec) needs **zero** changes.
This is not a convenience shortcut — it is what the header partial's own pre-existing comment
already documented as the intended contract (see
[Current State](#current-state-verified)). The **controller class** (`BlogController` →
`WritingController`) and **views directory** (`app/views/blog/` → `app/views/writing/`) are
renamed for identity clarity (a `WritingController` serving `/writing` reads correctly; a
`BlogController` serving it would be a confusing leftover) — this is a contained,
zero-external-call-site rename (nothing outside `config/routes.rb` references the controller
class by name — verified by grep).

### D2 — `public/blog/` storage path is unchanged
The **route** (`/writing`) is a clean, deliberate reset per the issue and design doc. The
**internal, on-disk storage path** (`public/blog/*.md`, `public/blog/images/*`) and
`Post#content`'s `Rails.public_path.join('blog', file_path)` read are a separate concern —
implementation detail, invisible to visitors — and are **not** renamed, for two concrete
reasons verified in [Current State](#current-state-verified):
1. Seven of the ten existing markdown files embed real, already-served `/blog/images/*.webp`
   URLs directly in their body content. Renaming the directory would require rewriting every
   one of those embedded URLs (a content edit, not a code change) and risks breaking any
   already-syndicated copy (Medium "Import a story," per design doc §6.2) or external
   backlink pointing at today's `/blog/images/...` asset URLs.
2. Precedent: `Project#content`'s optional `public/projects/{slug}.md` path is already named
   independently of the `/projects` route — internal storage naming has never been coupled to
   the public route in this codebase.
If a future issue wants to rename `public/blog/` too, that is a separate, purely-mechanical
follow-up (rewrite 7 embedded URLs + move ~15 files) with no user-facing route implication —
not bundled here.

### D3 — `kind`: `declare_schema` string column with a DB-level default, mirroring `Project#status`
```ruby
string :kind, limit: 20, null: false, default: 'deep_dive',
              validates: { presence: true, inclusion: { in: Post::KINDS } }
```
This is the *exact* shape `Project#status` already uses (`string ..., default: 'Beta',
validates: { inclusion: { in: %w[Pre-Launch Beta Live] } }`). The DB-level `default:
'deep_dive'` on a `NOT NULL ADD COLUMN` is what satisfies "backfill all existing posts →
deep_dive" — Postgres (11+) sets every pre-existing row to the column's default at the
catalog level as part of the `ADD COLUMN` itself, no separate `UPDATE` statement needed. This
is the same mechanism 1181's own `featured` column already relies on (`default: false`
silently backfilled every existing row to `false`) — verified working precedent, not a new
technique.

### D4 — `excerpt`: real column + a testable, idempotent backfill method (not raw migration SQL)
```ruby
string :excerpt, limit: 280, null: false, validates: { presence: true }, default: ''
```
Because `save`/`update!` runs **full** model validation regardless of which attributes
changed, the moment this column ships, `db/seeds.rb`'s next run (or any environment sync) would
raise `ActiveRecord::RecordInvalid` on **every** existing post (front-matter re-`update!`
always touches `title`/`description`/etc, triggering full validation, including presence of
`excerpt`, which the schema-level `default: ''` alone does not satisfy). This is not
optional/deferrable — it must be resolved in the same change. Rather than a raw
migration-only `execute("UPDATE posts SET excerpt = description WHERE excerpt = ''")` (opaque,
untestable, easy to typo), add a small, named, idempotent class method to the model itself:
```ruby
def self.backfill_excerpt_from_description!
  where(excerpt: '').find_each { |post| post.update_column(:excerpt, post.description.truncate(280)) }
end
```
called once from the generated migration's `self.up` (after the `add_column` calls). This
keeps the actual backfill *logic* in the model layer, where it is directly unit-testable (a
post with a blank excerpt gets backfilled from `description`; a post with a real excerpt
already set is left untouched — idempotency safety in case the method is ever re-invoked) —
see [Testing Strategy](#testing-strategy). Going forward, any **new** post's markdown front
matter must supply a real `excerpt:` key (enforced by the presence validation — `db:seed`
raises loudly if a new file omits it, which is the correct discipline per design doc §5:
"a one/two-line summary shown under titles in the feed" is core content, not optional
metadata).

### D5 — `reading_time` is computed, not stored
`Post#reading_time` is a plain instance method, **not** a `declare_schema` column:
```ruby
WORDS_PER_MINUTE = 200

def reading_time
  [(content.split.size / WORDS_PER_MINUTE.to_f).ceil, 1].max
end
```
Rationale: `Post#content` is already an intentionally uncached, always-fresh disk read on
every access (`content-domain.md`'s own "Known Limitations" already documents this: "`Post#
content` memoizes per request but re-reads disk; no caching layer"). A *stored*
`reading_time` column would be a derived value that can silently go stale the instant a
markdown body is hand-edited without a matching front-matter/DB touch — no write path in this
codebase re-triggers a recompute on a bare content edit (`db/seeds.rb`'s loop only re-syncs
front-matter keys, and a plain content edit with unchanged front matter produces no `update!`
call at all). Storing it would introduce exactly the dual-state class of bug this codebase's
own hardening practice already watches for. A computed method is always correct, costs one
cheap in-memory `String#split` per request on files that are a few KB at most, and needs no
migration/backfill of its own.

### D6 — `search_index_controller.rb`: simplify the now-always-true fallback
```ruby
# Before (defensive bridge added by #1187 ahead of this issue):
excerpt = post.has_attribute?(:excerpt) ? post.excerpt : post.description
# After (this issue ships Post#excerpt as a permanent, always-present column):
excerpt = post.excerpt
```
Once this issue merges, `post.has_attribute?(:excerpt)` is unconditionally `true` forever —
the `else` branch (`post.description`) becomes permanently dead code. Per this codebase's own
reductionist practice (the branch's own comment already anticipated this exact moment: "when
P1.4 ships Post#excerpt, this branch simply stops firing, no shape change"), simplify it away
rather than carry a permanently-unreachable conditional. This is a one-line, in-scope
follow-through directly required anyway by [R9](#r9--reconcile-1187s-search-index-tests)'s
test updates in the same file's spec.

### D7 — Pill component amendment: `variant: :kind`
The shipped `components/_pill.html.erb` only knows `:status` (Project-specific) and `:tag`
(neutral, free-form). Neither is a good fit for the Note/Deep-Dive distinction the design doc
treats as a first-class, visually-meaningful signal (§5's whole table is about the two kinds
reading differently). Rather than invent a one-off, non-reusable badge outside the shared
component (which 1181's own Out-of-Scope section names as the wrong move — "a spec amendment
to 1180's contract, not a workaround"), this issue makes the smallest possible **additive**
amendment to the one partial it genuinely needs a new capability from:
```erb
<% kind_badge_roles = { "note" => "badge-info", "deep_dive" => "badge-accent" }.freeze %>
<% badge_role = case pill_variant
   when :status then status_badge_roles.fetch(label, "badge-neutral")
   when :kind   then kind_badge_roles.fetch(label, "badge-neutral")
   else "badge-outline"
   end %>
```
`badge-info` / `badge-accent` are both real, themed DaisyUI roles already in active use
elsewhere in `application.tailwind.css` across all six bundled themes (verified: `--color-
info`/`--color-accent` are explicitly defined for every custom theme that needs an override —
gruvbox, catppuccin; dracula/nord/light/dark get theirs from DaisyUI's own stock palettes or
the existing amber repoint) — no new hex, no new token. Existing `:status`/`:tag` callers
(`projects/index.html.erb`) are unaffected — this is a pure addition, not a breaking change,
and needs no cross-file changelog edit to 1180's already-merged spec (per this repo's own
established precedent: 1181 recorded its own later amendments in *its own* file's changelog,
not by editing 1180.md after the fact — see that spec's "P2 amendment" callouts). This
spec is where the amendment is documented, since this is the issue making it.

### D8 — Nav copy rename: "Blog" → "Writing"
`_header.html.erb`'s `link_to 'Blog', posts_url, ...` → `link_to 'Writing', posts_url, ...`
(one word, `data-nav-target`/href untouched — see [D1](#d1--route-rename-is-path-only-helper-names-are-untouched)).
`_footer.html.erb`: the "Blog" nav link label (line 23) and the "Blog" RSS-feed link's visible
text + `title` attribute (line 46-48, `"blog rss feed"` → `"writing rss feed"`, `Blog` →
`Writing`). `blog/index.rss.builder`'s (→ `writing/index.rss.builder`) feed `<title>`
("Blog | James Ebentier | RSS") and `<image><title>` copy update to "Writing" for the same
reason — the RSS feed is public-facing branded copy, not an internal identifier. Exact tests
requiring an update in lockstep, already enumerated in [Current State](#current-state-verified):
`spec/requests/header_nav_spec.rb:33`, `spec/system/keyboard_nav_no_js_spec.rb:47`.

### D9 — Editorial guidelines live on the `/writing` index, no new route
Design doc §4's IA route table has no `/writing/guidelines`-shaped entry — adding one would be
new information architecture this issue wasn't asked to introduce. The Note vs. Deep Dive
table + heuristic (§5, reproduced verbatim — see [R6](#r6--writing-index-page)) render as a
section on the existing `/writing` index page, below (or beside) the kind filter and post
list. Whether it is its own partial (`writing/_editorial_guidelines.html.erb`) or inline
markup in `index.html.erb` is an implementer call — either is a single, contained addition
with no route/IA implication.

### D10 — Kind filter is server-rendered, no JS
`/writing?kind=note` / `/writing?kind=deep_dive` / `/writing` (all) — plain `link_to` query-
string links with an active-state class (matching the header's own existing `current_page?`-
style pattern), whitelisted server-side via `Post.by_kind` (see
[R2](#r2--post-model-additions)) so a garbage/unknown `params[:kind]` value safely falls back
to "all," never a 500 or a silently-empty result set. This keeps the entire feature
request/view-spec-testable, per the issue's own explicit testing-strategy note: "system specs
... ONLY if there's real client-side JS (e.g. a JS kind filter)" — there is none here, so no
new Cuprite/system spec is required by this issue.

---

## Requirements

### R1 — Schema: `kind` and `excerpt`
- Add to `Post`'s `declare_schema` block (mirroring [D3](#d3--kind-declare_schema-string-column-with-a-db-level-default-mirroring-projectstatus)/
  [D4](#d4--excerpt-real-column--a-testable-idempotent-backfill-method-not-raw-migration-sql)):
  ```ruby
  string :kind,    limit: 20,  null: false, default: 'deep_dive',
                   validates: { presence: true, inclusion: { in: Post::KINDS } }
  string :excerpt, limit: 280, null: false, default: '', validates: { presence: true }
  ```
- Run `bundle exec rails generate declare_schema:migration` (interactive; supply e.g.
  `add_kind_and_excerpt_to_posts`); confirm the generated migration adds exactly these two
  columns; hand-add one line to the generated migration's `self.up` (after both `add_column`
  calls): `Post.backfill_excerpt_from_description!`.
- `bundle exec rails db:migrate`; regenerate `db/schema.rb`; confirm `declare_schema:migration
  --pretend` reports "Database and models match -- nothing to change."
- No changes to `featured`/`tags`/any other existing `Post` column.

### R2 — `Post` model additions
```ruby
KINDS = %w[note deep_dive].freeze
KIND_LABELS = { "note" => "Note", "deep_dive" => "Deep Dive" }.freeze

scope :by_kind, ->(kind) { KINDS.include?(kind) ? where(kind: kind) : all }

def kind_label
  KIND_LABELS.fetch(kind, kind)
end

def reading_time
  [(content.split.size / WORDS_PER_MINUTE.to_f).ceil, 1].max
end

def self.backfill_excerpt_from_description!
  where(excerpt: '').find_each { |post| post.update_column(:excerpt, post.description.truncate(280)) }
end
```
`Post.by_kind(nil)` / `Post.by_kind("")` / `Post.by_kind("garbage")` all return `all`
(unfiltered) — never raise, never silently return an empty relation for bad input.
`Post.featured` / `Post.for_home` (#1181, already shipped) are **untouched** — `kind` is
orthogonal to curation; a Note is exactly as eligible for `featured: true` / `for_home` as a
Deep Dive. No change to either method's behavior or tests.

### R3 — Route + controller + view rename
- `config/routes.rb`: per [D1](#d1--route-rename-is-path-only-helper-names-are-untouched).
- `app/controllers/blog_controller.rb` → `app/controllers/writing_controller.rb`,
  `BlogController` → `WritingController`, action shape unchanged (`index; end`; `show` does
  `Post.find_by!(slug: params.expect(:slug).downcase)`, unchanged — matches
  `web-presentation.md`'s "controllers stay thin" invariant; the `kind` filter's validity
  check lives in the model scope, per [D10](#d10--kind-filter-is-server-rendered-no-js), not
  the controller).
- `app/views/blog/index.html.erb`, `index.rss.builder`, `show.html.erb` → `app/views/writing/`
  (same three filenames), content rewritten per [R6](#r6--writing-index-page) (index +
  RSS copy) and [R5](#r5--writing-article-page) (show).

### R4 — Nav + RSS copy rename
Per [D8](#d8--nav-copy-rename-blog--writing): `_header.html.erb` and `_footer.html.erb`'s
"Blog" label text, the footer RSS link's visible text + `title` attribute, and
`writing/index.rss.builder`'s `<title>`/`<image><title>` copy — all become "Writing".
Route helpers/hrefs/`data-nav-target` values are already correct today and are not touched.

### R5 — `/writing` article page (`writing/show.html.erb`)
- `<h1 class="font-mono text-3xl font-bold mb-4">` (adds `font-mono`, matching every other
  page's heading convention — today's `blog/show.html.erb` h1 lacks it).
- A metadata row, in this order: kind badge (`components/pill`, `variant: :kind`, `label:
  post.kind`, displayed via `post.kind_label`), tag pills (`components/pill`, `variant: :tag`,
  one per `post.tags` entry — already-present data, not yet rendered through the shared
  component; today's `show.html.erb` renders tags with a hardcoded `badge-accent` span
  instead), published date (unchanged format, `strftime("%B %d, %Y")`), and `"#{post.reading_
  time} min read"`.
- `post.excerpt` rendered once, visually distinct from the date/reading-time line (a
  `text-lg`/`text-base-content/80`-style lede, implementer/visual-QA call within existing
  tokens) — above the markdown body.
- Markdown body render (`render_markdown(@post.content)`) is **unchanged** — see
  [Out of Scope](#out-of-scope)'s `Blog::Renderer` note.
- No `components/card`/`components/section` wrapper — a show/detail page is not a teaser
  card, and there is no existing "detail page uses P1.1 components" precedent to reuse (both
  `blog/show.html.erb` and `projects/show.html.erb` are pre-P1.1 today); this issue's article
  page is the first to establish one, using `pill`/`cta_button` where they genuinely fit
  (badges) and plain, token-only markup for page-level structure otherwise.

### R6 — `/writing` index page (`writing/index.html.erb`)
- `<h1 class="font-mono text-3xl mb-4">Writing</h1>` (title text an implementer call; "Recent
  Blog Posts" is retired along with the old route name).
- Kind filter: three plain links — "All", "Notes", "Deep Dives" — to `writing_path`,
  `writing_path(kind: "note")`, `writing_path(kind: "deep_dive")` respectively (note:
  `writing_path`/`writing_url` do **not** exist as route helper names — the existing
  `posts_path`/`posts_url` helpers are reused with a `kind:` query param, e.g. `posts_path(kind:
  "note")` — see [D1](#d1--route-rename-is-path-only-helper-names-are-untouched); "writing_path"
  above is descriptive shorthand for "the `/writing` index route," not a literal helper name),
  active-state styling matching the header's existing `current_page?`-driven pattern (exact
  DaisyUI classes, e.g. `tabs`/`tab-active` vs. a simple `link`/`text-primary` treatment, an
  implementer/visual-QA call).
- Post list, `Post.published.by_kind(params[:kind]).order(published_at: :desc)`, called
  directly in the view (per this repo's established "controllers stay thin, views query
  directly" convention — see `web-presentation.md`'s own Key Invariants, and 1181's R2 "Where
  the query lives" precedent). One `components/card` per post: `href: post_url(slug:
  post.slug), image_url: post.image`; body = `<h2 class="card-title font-mono text-xl">post.
  title</h2>`, kind badge (`variant: :kind`), tag pills (`variant: :tag`, one per `post.tags`
  entry), `post.excerpt`, published date, `"#{post.reading_time} min read"`, and a
  `cta_button` (`style: :primary`, label "Read Post", `href:` the same `post_url`) inside
  `card-actions relative z-10` — same composition contract `projects/index.html.erb`
  established, extended with the two new pill variants and the reading-time/excerpt text.
- Editorial guidelines section — design doc §5's table + heuristic sentence, reproduced
  verbatim:

  | | Note | Deep Dive |
  |---|---|---|
  | Length | Short (~< 500 words) | Long-form (~1,000+ words) |
  | Purpose | A single thought, reaction, TIL, or link + commentary | A worked-through system, argument, or lesson that teaches a reusable mental model |
  | Cadence | Frequent, low ceremony | Infrequent, high polish |
  | Artifacts | Optional | Usually code, diagrams, or worked examples |
  | Role | Keeps the site alive, shows personality | The credibility engine for fractional work |

  > **Heuristic:** *If it teaches a reusable mental model or walks through a system, it's a
  > Deep Dive. If it's a thought, reaction, or TIL, it's a Note.* When in doubt, it's a Note —
  > Notes can graduate into Deep Dives.

  Per [D9](#d9--editorial-guidelines-live-on-the-writing-index-no-new-route), rendered as a
  section on this same page (partial vs. inline markup: implementer call).
- No filter option renders when the corresponding kind has zero published posts — an
  implementer/visual-QA call whether to hide empty filter links entirely or show them disabled
  (either is acceptable; not a functional gap, since `Post.by_kind` on an empty result set
  just renders an empty (but not broken) list either way).

### R7 — Home Latest-Writing consistency (1181 follow-through)
`welcome/index.html.erb`'s Latest Writing card body — currently `<p class='mb-0'><%= post.
description %></p>` (1181's own Out of Scope: *"`description` stands in for the not-yet-added
`excerpt`... not itself changed or renamed"*) — becomes `<%= post.excerpt %></p>` now that
`excerpt` exists. Verified safe: `spec/requests/welcome_spec.rb` has no assertion on the
literal card-body text content today (only section presence, grid classes, and pill absence
are asserted — see [Current State](#current-state-verified)), so this is a zero-test-breakage
change; add one new assertion locking in the intended behavior (a post with distinct
`description`/`excerpt` values renders the excerpt text, not the description text, in the
Latest Writing card).

### R8 — Pill component amendment
Per [D7](#d7--pill-component-amendment-variant-kind): add the `variant: :kind` branch to
`app/views/components/_pill.html.erb`. No other partial changes.

### R9 — Reconcile #1187's search-index tests
Per [D6](#d6--search_index_controller-simplify-the-nowalwaystrue-fallback), in
`app/controllers/search_index_controller.rb#serialize_post`: replace the `has_attribute?`
branch with a direct `post.excerpt` read. In `spec/requests/search_index_spec.rb`:
- **Supersede** `"confirms Post has no excerpt column yet, so the fallback branch is genuinely
  exercised"` (now false — the column always exists) — remove it, not leave it red.
- **Update** `"serializes the post's item shape exactly, falling back to description for
  excerpt (R9)"` — the `let!(:post)` factory call needs an explicit, *distinct* `excerpt:`
  value (something other than the `description:` value already given), and the expected JSON
  `'excerpt'` value changes from the description string to that excerpt string. Rename the
  example to describe the new behavior (e.g. "serializes the post's item shape exactly,
  preferring excerpt over description").
- **Update** the file's own top-of-file comment (lines 6-12), which currently describes "Post
  has no `excerpt` column... the fallback branch this spec exercises" — rewrite to describe
  the shipped state (excerpt always present and preferred; description is the meta-tag/SEO
  field, a separate concern).
- The Project-side assertions (truncated description, `tags: []`) are untouched — `Project`
  has no `excerpt` equivalent and is out of scope here.

---

## Dependencies / Coordination

- **Blocked by P1.1 (#1180) — satisfied**, merged to `main`; verified directly against shipped
  code (see [Current State](#current-state-verified)), not 1180's proposal.
- **Consumes P1.2 (#1181)'s `featured`/`for_home` — satisfied**, merged; this issue adds no
  new coupling to it beyond the one, low-risk `excerpt`-for-`description` swap in
  [R7](#r7--home-latest-writing-consistency-1181-follow-through), verified zero-test-breakage.
- **Reconciles P1.8 (#1187)'s search-index tests** — [R9](#r9--reconcile-1187s-search-index-tests),
  a direct, foreseen (per #1187's own comment) consequence of this issue shipping `Post#
  excerpt`; not a regression, a planned hand-off.
- **No coupling to P1.3 (#1182)**, in progress elsewhere. This issue does not touch
  `projects_controller.rb`, `projects/*.html.erb`, or `Project`. The one file P1.3 *might*
  also want to touch — `lib/blog/renderer.rb`/`app/helpers/blog_helper.rb` (shared markdown
  rendering, used by both `Post#content` and `Project#content`) — is explicitly **not**
  touched by this issue (see [Out of Scope](#out-of-scope)), to avoid a foreseeable merge
  conflict with P1.3's own in-flight work.
- **No coupling to P1.6 (#1185)**, not started. `medium_url`/`canonical_url` stay entirely out
  of this issue's `Post` schema addition — see [Out of Scope](#out-of-scope).
- **Coordination note for any future issue touching `public/blog/`:** per
  [D2](#d2--publicblog-storage-path-is-unchanged), this issue deliberately leaves that
  directory named `blog`, not `writing`. A future rename is a self-contained, purely
  mechanical follow-up (see D2's closing note) — not bundled here, and not blocked by
  anything this issue ships.

## Architecture Doc Updates

### `docs/architecture/sub-systems/content-domain.md`
- **Anchor Files**: `app/models/post.rb`'s description gains "kind (note/deep_dive),
  computed reading_time, excerpt" — no new file.
- **Public Contract — Exports**: add `Post::KINDS`, `Post.by_kind`, `Post#kind_label`,
  `Post#reading_time`, `Post#excerpt` next to the existing `Post.published`/`Post.featured`
  entries.
- **Key Invariants**: add a bullet for the `kind` default-backfill mechanism ([D3](#d3--kind-declare_schema-string-column-with-a-db-level-default-mirroring-projectstatus))
  and one for `reading_time` being computed-not-stored, with the staleness rationale
  ([D5](#d5--readingtime-is-computed-not-stored)).
- **State Owned**: no new table; two additive columns on `posts`.
- **Known Limitations**: note that `excerpt`'s presence validation means any new markdown
  post's front matter must include an `excerpt:` key (enforced at `db:seed` time).

### `docs/architecture/sub-systems/web-presentation.md`
- **Purpose**/**HTTP routes**: `/blog`, `/blog/:slug` → `/writing`, `/writing/:slug`.
- **Anchor Files**: `blog_controller.rb` → `writing_controller.rb`.
- **Component partials** bullet: note the new `components/_pill` `variant: :kind` option
  alongside the existing `:status`/`:tag` mention.
- **Known Limitations**: the existing `ProjectsController#show` vs. blog's `find_by!`
  inconsistency bullet — rename "blog" reference to "writing" (`WritingController#show` now).

### `docs/architecture/overview.md`
Update the file catalog: `app/controllers/blog_controller.rb` →
`app/controllers/writing_controller.rb`; `app/views/blog/index.html.erb` /
`index.rss.builder` / `show.html.erb` → the equivalent three `app/views/writing/*` paths.
File **count** is unchanged (a pure rename, no new/deleted files at the `app`/`lib` catalog
level — `docs/specs/` additions don't count toward this catalog).

---

## Testing Strategy

Per the issue's own instruction: this is entirely server-rendered (no new client-side JS),
so **request specs (and the model specs below) suffice** — no new Capybara/Cuprite system
spec is required by this issue's own scope (the existing Cuprite infra from #1187 is reused
only to the extent that its *existing* specs need the small text-only updates named below).

### Model specs (`spec/models/post_spec.rb`)
- Schema/validation additions to the existing `describe 'schema and validations'` block
  (mirrors the file's existing style exactly):
  `have_db_column(:kind).of_type(:string).with_options(limit: 20, null: false, default:
  'deep_dive')`; `validate_inclusion_of(:kind).in_array(%w[note deep_dive])`;
  `have_db_column(:excerpt).of_type(:string).with_options(limit: 280, null: false, default:
  '')`; `validate_presence_of(:excerpt)`.
- `.by_kind` — returns only matching-kind posts for `"note"`/`"deep_dive"`; returns **all**
  posts (unfiltered) for `nil`, `""`, and an unrecognized string like `"garbage"` — four
  explicit cases, not just the happy path.
- `#reading_time` — unit-test the exact word-count → minute boundary (e.g. a fixture post
  whose real on-disk content is exactly 200 words → `1`; 201 words → `2`; a very short/empty
  content → `1`, never `0`). Needs a real `file_path`/on-disk fixture (same convention
  `spec/system/keyboard_nav_*_spec.rb` already uses — `file_path:
  "2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3.md"`) or a small dedicated fixture file, not
  the factory's default nonexistent path.
- `.backfill_excerpt_from_description!` — a post created with a blank `excerpt` gets it set to
  (a truncated copy of) its `description`; a post created with a real, distinct `excerpt`
  already set is left untouched by a second invocation (idempotency).
- `kind` DB-level backfill-on-migration ([D3](#d3--kind-declare_schema-string-column-with-a-db-level-default-mirroring-projectstatus))
  is a Postgres `ADD COLUMN ... DEFAULT` guarantee, not something a fresh test database (built
  from `schema.rb`, not migration history) can exercise directly — this is the same class of
  "real-environment, not RSpec-provable" item 1181's own Open Questions named for its
  `featured` backfill; verify via a real `bundle exec rails db:migrate` cycle (or a `\d posts`
  check) against a database seeded *before* the migration runs, not an automated spec.

### Request specs (new: `spec/requests/writing_spec.rb`)
Mirror `spec/requests/projects_spec.rb`'s existing style (exercises the real controller/view
stack via `response.parsed_body.css(...)`, per `adlc/methods/code-quality/call-site-wiring-
verification.md`'s convention that file already cites):
- `GET /writing` (no `kind`) — 200; renders one card per **published** post (matches
  `Post.published`, never an unpublished/future post), newest first.
- `GET /writing?kind=note` / `?kind=deep_dive` — only matching-kind posts render; a mixed
  fixture set (2 notes + 1 deep dive) proves both filters and the unfiltered case independently.
- `GET /writing?kind=garbage` — behaves identically to no filter (whitelist fallback, not a
  500, not an empty result).
- Each card exposes: kind badge with the correct `badge-info`/`badge-accent` role per
  [D7](#d7--pill-component-amendment-variant-kind); one tag pill per `post.tags` entry
  (`badge-outline`); excerpt text; published date; `"N min read"` text; a `.btn-primary` CTA
  linking to the post's own `post_path`.
- Editorial guidelines table/heuristic text present on the index page.
- Zero-posts case: 200, empty card list, guidelines section still present (it is static
  content, not data-dependent).
- `GET /writing/:slug` — 200 for a real slug; kind badge, tag pills, excerpt, date, reading
  time all present; `font-mono` class present on the `<h1>`; unknown slug → 404
  (`ActiveRecord::RecordNotFound`, unchanged `find_by!` behavior).

### Updated specs (existing files, per [Current State](#current-state-verified))
- `spec/factories/post.rb` — add `excerpt { "A short teaser for the blog's return." }` (or
  similar; required, presence-validated, no schema default that would satisfy it) and
  `kind { "deep_dive" }` (matches the schema default explicitly, mirroring
  `spec/factories/project.rb`'s own `status { "Beta" }` convention of stating the default
  explicitly rather than relying on it silently).
- `spec/requests/header_nav_spec.rb:33` — `"Blog"` → `"Writing"` in the `nav_texts` array.
- `spec/system/keyboard_nav_no_js_spec.rb:47` — `click_link "Blog"` → `click_link "Writing"`.
- `spec/requests/search_index_spec.rb` — per [R9](#r9--reconcile-1187s-search-index-tests).
- `spec/requests/welcome_spec.rb` — per [R7](#r7--home-latest-writing-consistency-1181-follow-through),
  add the one new excerpt-vs-description assertion; no removals needed (verified no existing
  assertion checks that literal text).

---

## Approach (Implementation Guidance)

Spec-level guidance for the **code** agent — re-verify current `declare_schema`/routes/view
state at implementation time, per this repo's own standing practice.

1. Confirm working in this issue's worktree/branch, based on current `main`
   (P1.1/P1.2/P1.8 already merged in).
2. `app/models/post.rb`: add `kind`/`excerpt` to the `declare_schema` block ([R1](#r1--schema-kind-and-excerpt)),
   `KINDS`/`KIND_LABELS`/`by_kind`/`kind_label`/`reading_time`/`backfill_excerpt_from_
   description!` ([R2](#r2--post-model-additions)). Generate the migration, hand-add the
   backfill call, migrate, regenerate `db/schema.rb`, confirm `--pretend` clean.
3. Rename `blog_controller.rb` → `writing_controller.rb` (class `WritingController`), `app/
   views/blog/` → `app/views/writing/`; update `config/routes.rb` per
   [D1](#d1--route-rename-is-path-only-helper-names-are-untouched).
4. Amend `components/_pill.html.erb` with `variant: :kind` per
   [D7](#d7--pill-component-amendment-variant-kind)/[R8](#r8--pill-component-amendment).
5. Rewrite `writing/index.html.erb` per [R6](#r6--writing-index-page), `writing/show.html.erb`
   per [R5](#r5--writing-article-page), `writing/index.rss.builder`'s copy per
   [D8](#d8--nav-copy-rename-blog--writing).
6. Update `_header.html.erb`/`_footer.html.erb` copy per
   [D8](#d8--nav-copy-rename-blog--writing).
7. `welcome/index.html.erb` — swap `post.description` → `post.excerpt` per
   [R7](#r7--home-latest-writing-consistency-1181-follow-through).
8. `search_index_controller.rb` — simplify per
   [D6](#d6--search_index_controller-simplify-the-nowalwaystrue-fallback)/[R9](#r9--reconcile-1187s-search-index-tests).
9. Update `spec/factories/post.rb`, write the new `spec/requests/writing_spec.rb` and
   `post_spec.rb` additions, update `header_nav_spec.rb`, `keyboard_nav_no_js_spec.rb`,
   `search_index_spec.rb`, `welcome_spec.rb` per [Testing Strategy](#testing-strategy).
10. Update `docs/architecture/sub-systems/content-domain.md`,
    `docs/architecture/sub-systems/web-presentation.md`, `docs/architecture/overview.md`'s
    catalog per [Architecture Doc Updates](#architecture-doc-updates).
11. Verify: `bundle exec rubocop` and `bundle exec rspec` (`ci-gate`) green;
    `declare_schema:migration --pretend` clean; `yarn build:css` unaffected (no new tokens,
    only existing DaisyUI role utilities). Manually verify in-browser: `/writing` across all
    six themes (kind badges/tag pills re-theme correctly, no hardcoded colors); the kind
    filter links; `/writing/:slug` typography; `/blog` returns a plain 404 (no redirect, per
    the issue's explicit instruction); home's Latest Writing cards now show excerpts;
    `/search-index.json` items show real excerpts.

## Acceptance Criteria

- [ ] `Post` has `kind` (`note`/`deep_dive`, default `deep_dive`, validated) and `excerpt`
      (required, backfilled from `description` for all pre-existing rows) via `declare_schema`
      + generated migration; `db/schema.rb` regenerated; `--pretend` reports no drift (R1)
- [ ] All ten pre-existing posts read as `kind: "deep_dive"` after migration (D3's DB-default
      mechanism, or `backfill_excerpt_from_description!`'s equivalent for `excerpt`)
- [ ] `Post.by_kind` filters correctly for `"note"`/`"deep_dive"` and falls back to
      unfiltered for `nil`/blank/unrecognized input (R2)
- [ ] `Post#reading_time` is a computed method (no DB column), returns a minimum of `1` (R2, D5)
- [ ] `Post.featured`/`Post.for_home` (#1181) are unchanged in behavior and un-redeclared
- [ ] `/blog` and `/blog/:slug` no longer resolve (no redirect); `/writing` and
      `/writing/:slug` do, via the renamed `WritingController` (R3)
- [ ] `posts_path`/`posts_url`/`post_path`/`post_url` route helper names are unchanged
      everywhere they're called (header, footer, `welcome/index.html.erb`,
      `search_index_controller.rb`, both RSS builders) (D1)
- [ ] `/writing` renders via `components/section`/`card`/`pill`/`cta_button`, with a working
      `?kind=` filter (all/note/deep_dive), each card showing kind badge, tags, excerpt, date,
      and reading time (R6)
- [ ] `/writing/:slug` shows kind badge, tag pills, excerpt, date, reading time, and a
      `font-mono` `<h1>`; markdown body rendering is unchanged (R5)
- [ ] The Note vs. Deep Dive editorial guidelines table + heuristic render on the `/writing`
      index page (R6, D9)
- [ ] `components/_pill.html.erb` gains exactly one additive `variant: :kind` branch;
      `:status`/`:tag` behavior for existing callers is unchanged (R8, D7)
- [ ] Header/footer/RSS "Blog" copy reads "Writing"; `header_nav_spec.rb` and
      `keyboard_nav_no_js_spec.rb` updated to match (R4, D8)
- [ ] `welcome/index.html.erb`'s Latest Writing card shows `post.excerpt`, not
      `post.description` (R7)
- [ ] `search_index_controller.rb` reads `post.excerpt` directly (no `has_attribute?` branch);
      `search_index_spec.rb`'s two now-superseded assertions are replaced, not left
      red/silently deleted (R9, D6)
- [ ] No change to `Blog::Renderer`/`BlogHelper`, `projects_controller.rb`,
      `projects/*.html.erb`, or any `Project` schema/behavior
- [ ] No change to `public/blog/`'s on-disk path or any embedded `/blog/images/*` URL
- [ ] `docs/architecture/sub-systems/content-domain.md`,
      `.../web-presentation.md`, and `docs/architecture/overview.md`'s catalog reflect every
      change above
- [ ] Existing `ci-gate` (`lint` + `test`) remains green

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns)
and the scribe's own delegation rules:

- **Implementation** (all of R1–R9: schema/model changes, the controller/view rename, the two
  rewritten views, the pill amendment, the nav/RSS copy update, the home/search-index
  follow-throughs, all new/updated specs, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (board status, closing on merge): delegate to the
  **orchestrator** — this spec performs none of those operations itself.
- **Manual in-browser verification** (six-theme re-render of the new badges/filter, `/blog`
  truly 404ing with no redirect): part of the implementer's own pre-PR verification (per the
  `verify` skill).
- **Exact visual-QA calls** left open: filter-link active-state styling, whether empty-kind
  filter options hide or show-disabled, partial-vs-inline editorial-guidelines markup, the
  precise excerpt lede styling on the article page — all implementer/visual-QA judgment within
  the structural contracts already fixed above, not further scribe/user sign-off requirements.

## Open Questions

1. **Hand-written excerpts for the ten existing posts.** [R1](#r1--schema-kind-and-excerpt)'s
   backfill copies `description` into `excerpt` mechanically so nothing is ever blank/invalid
   — but a `description` (written for SEO meta tags) and a good `excerpt` (written to sell a
   reader on clicking through, per design doc §5) are different crafts. Worth James revisiting
   by hand post-merge; not blocking.
2. **Should any existing post actually be reclassified as a Note?** Out of scope per this
   issue's own instruction (design doc + issue both say all existing posts backfill to Deep
   Dive) — flagged only because "Notes start later" (design doc §5) implies the *first* Note
   is a future, separate content-authoring act, not a code change.
3. **`public/blog/` → `public/writing/` rename.** Deliberately deferred, see
   [D2](#d2--publicblog-storage-path-is-unchanged)'s closing note — a self-contained,
   mechanical follow-up whenever it's wanted, not gated on anything here.
4. **Filter-link visual treatment (tabs vs. simple text links) and reading-time rounding
   display ("1 min read" vs "< 1 min read" for very short Notes).** Genuine visual-design
   judgment calls within the fixed structural/behavioral contract above.

## Changelog

### Version 1 - 2026-07-19
**Source Issue:** bitidev/jamesebentier.com#1183
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification for the Notes/Deep Dives content model (`Post.kind`, `Post#excerpt`,
  computed `Post#reading_time`) and the `/blog` → `/writing` clean-refresh route rename
- Verified current app state directly: `Post` has no `kind`/`excerpt`/`reading_time` today but
  already has `featured`/`tags`/`for_home` (shipped by #1181); `/blog`'s views are the last
  two content-facing pages not yet migrated onto the P1.1 component library; the header
  partial's own pre-existing comment already anticipated this exact route rename with zero
  route-helper-name churn; `search_index_controller.rb` (#1187) already ships a
  forward-compatible `excerpt` bridge needing no functional change, only two stale test
  assertions superseded
- Resolved every "decide X" item the issue flagged explicitly: route-helper-name scope
  (path-only, D1), `public/blog` storage-path fate (unchanged, D2, backed by concrete embedded-
  URL evidence), `kind`'s backfill mechanism (DB-level default, mirroring `Project#status`
  and `featured` precedent, D3), `excerpt`'s backfill (a testable, idempotent model method, not
  raw migration SQL, D4, because presence validation would otherwise break `db:seed`),
  `reading_time` stored-vs-computed (computed, to avoid a dual-state staleness bug class, D5),
  and the #1187 search-index consistency question the task explicitly raised (in scope, fully
  resolved via D6/R9 — not deferred to a follow-up)
- Made one additive component-library amendment (`components/_pill` `variant: :kind`, D7),
  matching 1181's own precedent for how a later issue may amend an earlier one's shipped
  component contract without editing that earlier spec's file
- Scoped out everything belonging to sibling issues: `medium_url`/`canonical_url` (P1.6/#1185),
  the Projects grid/filter/triple-links and shared `Blog::Renderer`/`BlogHelper` markdown
  rendering (P1.3/#1182, explicitly left untouched to avoid a foreseeable merge conflict with
  its in-flight work)
- Flagged four open questions, none blocking: hand-written excerpt quality for existing posts,
  whether any existing post should become a Note, the deferred `public/blog` directory rename,
  and two pure visual-QA calls

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the
code agent.
