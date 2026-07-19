<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1187 -->
<!-- Last Updated: 2026-07-19T00:00:00+02:00 -->
<!-- Description Hash: 5b2b7b2bf5b9 -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# P1.8 — Modal Vim-Style Keyboard Navigation (Site-as-Terminal)

**Issue:** [bitidev/jamesebentier.com#1187](https://github.com/bitidev/jamesebentier.com/issues/1187)
**Parent epic:** [#1179 — 2026 Site Redesign, Phase 1](https://github.com/bitidev/jamesebentier.com/issues/1179)
**Branch:** `personal/jebentier/issue-1187-p18-modal-vim-keyboard-navigation`
**Board:** org `bitidev` project — Status: In Progress; Assignee: `jebentier`
**Design:** [`docs/design/redesign-2026.md`](../design/redesign-2026.md) §3 ("Signature interaction — the site as a terminal", amended by this spec — see [Design Doc Amendment](#design-doc-amendment))
**Architecture plan:** [`docs/plans/1187-modal-vim-keyboard-navigation-architecture-plan.md`](../plans/1187-modal-vim-keyboard-navigation-architecture-plan.md) — the approved technical design this spec implements; every Decision (1–8) referenced below is that plan's, restated here as concrete, buildable requirements
**Depends on:** P1.1 (#1180, merged) — theme tokens, `theme-picker` Stimulus controller, DaisyUI 6-theme set
**Feeds:** P1.9 (metrics query commands plug into COMMAND mode's registry)

## Overview

P1.1 shipped the visual foundation; this issue ships the redesign's **personality
centerpiece** — a modal, neovim-style keyboard layer that drives the whole site the way
neovim drives an editor, directly inspired by commitmono.com. Default **NORMAL** mode
supports `hjkl`/`gg`/`G` scrolling and navigation, `g h/w/p/l` page jumps, `t` theme
cycling, `?` for a bindings guide, and `f` for a Vimium-style link hint-jump overlay.
Bare `:` opens **COMMAND** mode (an extensible command registry); bare `/` opens
**SEARCH** mode (site-wide content search over Posts/Projects). A visible terminal-style
status line shows the active mode at all times.

This is a pure **web-presentation** subsystem feature (per the architecture plan §8): one
new Stimulus controller, a handful of pure ES-module helpers, a few new/updated ERB
partials, a small JSON search-index endpoint reading existing `Post`/`Project` data
(already-permitted `web-presentation → content-domain` edge), and a `data-nav-target`
attribute added to the existing header nav links. No new subsystem, no new dependency
edge.

**This issue also stands up this repo's first JS/browser test infrastructure** —
Capybara + Cuprite for browser-driven system specs, and Vitest for ES-module unit
tests — as in-scope work, not a follow-on. See [Testing Strategy](#testing-strategy).

## Goal

A visitor with a hardware keyboard can navigate, search, and re-theme the entire site
without touching the mouse, and always knows which mode they're in from the status line.
A developer extending COMMAND mode later (P1.9) has a documented registry contract to
plug into. Nothing already on the site — native form fields, the P1.1 theme `<select>`,
browser/OS shortcuts, screen readers, JS-disabled visitors, touch visitors — regresses by
one keystroke.

## In Scope

- **Mode state machine**: NORMAL (default) / COMMAND (`:`) / SEARCH (`/`), a visible
  `aria-live="polite"` terminal-style status line, `Esc`-always-to-NORMAL. Implemented as
  a single Stimulus controller mounted once on `<body>` (architecture plan Decision 1).
- **Global key dispatch** that coexists with native focus site-wide: one `document`-level
  bubble-phase `keydown` listener with a generic editable-target guard (Decision 2) — no
  per-field special-casing, no regression to any native `<input>`/`<textarea>`/`<select>`/
  `[contenteditable]` anywhere on the site, now or in the future.
- **NORMAL-mode navigation**: `h/j/k/l`, `j/k` line-scroll, `gg`/`G` top/bottom, `g` +
  `h/w/p/l` page jumps via a single-source-of-truth `resolveNavTarget` lookup (Decision 6).
- **`t` theme cycle**, wired into the *existing* P1.1 `theme-picker` controller/`<select>`
  — no parallel theme-apply/persist logic (Decision 4).
- **COMMAND mode** (`:`): a terminal-style input, an extensible command registry with a
  documented extension contract (name/aliases/description/handler), a v1 command set
  (nav + theme-set), pure `parseCommand`/`rankCommands` helpers.
- **SEARCH mode** (`/`): a client-side, lazily-fetched JSON content index over
  Posts/Projects, live-filtered results (title > tag > excerpt substring ranking),
  `n`/`N` step through results (SEARCH-scoped, not a global "repeat search"), Enter
  navigates via `.click()` on the real result link (Decision 3).
- **`f` hint-jump**: a links-only, viewport-scoped, `aria-hidden`/`pointer-events: none`
  overlay; deterministic DOM-order hint labels; activation via `.click()` on the real
  anchor; Esc or first-scroll cancels (Decision 5).
- **`?` keyboard-guide overlay**: a native `<dialog>`, documenting every binding shipped
  in this issue and the command registry's extension contract for P1.9.
- **A11y & no-JS progressive enhancement**: no focus traps anywhere but the `?` dialog
  (which uses `<dialog>`'s own native focus containment); `prefers-reduced-motion`
  respected via the exact media query `motion_controller.js` already uses; 100% of site
  navigation/search/links function with the layer entirely absent.
- **Touch/mobile no-op**: feature-detected via `matchMedia("(hover: hover) and
  (pointer: fine)")`; when it doesn't match, no listener is attached and no affordance is
  rendered (Decision 8).
- **Standing up JS/browser test infrastructure** (Capybara + Cuprite; Vitest) as part of
  this issue's delivery — see [Testing Strategy](#testing-strategy).
- **The `docs/design/redesign-2026.md` §3 amendment** — see
  [Design Doc Amendment](#design-doc-amendment).
- Updating `docs/architecture/sub-systems/web-presentation.md` (Anchor Files, Public
  Contract, Key Invariants) for the new controller/modules/route, per the scribe's
  architecture-doc ownership rule.

## Out of Scope

- **P1.9's metrics-query commands** (`stats views --last 7d`, `top posts`, §6.4). This
  issue builds the COMMAND registry's extension contract and leaves it documented and
  obviously pluggable; it does not build any analytics command itself.
- **`/lab` and `/writing` routes.** Neither exists yet (`config/routes.rb` today only
  defines `/`, `/blog`, `/blog/:slug`, `/projects`, `/projects/:slug`, `/resume`, `/up`).
  `resolveNavTarget("lab")` / `:lab` self-resolve to a no-op today (Decision 6) — building
  those routes is Phase 2 (`/lab`) and a future IA rename (`/writing`), not this issue.
- **`Post.excerpt`/`Post.kind` (design doc §5 / Phase 1 item 4, P1.4).** Verified not yet
  shipped in this repo (`app/models/post.rb` has no `excerpt` or `kind` column today).
  SEARCH's index does **not** block on P1.4 landing — see
  [R9](#r9--search-content-index-endpoint) for the fallback this spec defines.
- **New design tokens, colors, or visual restyling.** This issue consumes P1.1's existing
  `font-mono`/amber-accent/theme tokens as-is; it introduces no new palette work.
- **Fuzzy-match search** (a matching library, typo-tolerance). Substring ranking only —
  sufficient at this site's content scale per Decision 3.
- **Off-screen hint-jump (scroll-to-reveal)** and **live badge reposition on scroll**.
  Both explicit v1 simplifications per Decision 5 (scroll cancels hint-jump instead).
  Reasonable follow-ups, not blockers.
- **An on-screen/virtual vim keyboard for touch devices.** Touch is a graceful, honest
  no-op (Decision 8), not a reduced-affordance mobile UI.
- **Any OIDC/identity, analytics-capture, or Bardic Labs work.** Phase 2 / separate
  issues entirely.

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch
`jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC
contribution.

## Current State (Verified)

Verified directly against this worktree (branched from `main` @ `9687463`, P1.1 merged)
as of 2026-07-19:

### Keyboard / JS today
- **No document/window-level `keydown` listener exists anywhere in the codebase**
  (confirmed by the architecture plan's collision audit) — there is no prior keyboard
  behavior to reconcile, only the P1.1 theme `<select>` and ordinary native form focus.
- `app/javascript/controllers/`: `application.js`, `index.js` (manifest),
  `collapse_controller.js` (resume page toggle), `hello_controller.js` (unused scaffold,
  already flagged in `web-presentation.md`'s Known Limitations), `theme_picker_controller.js`
  (P1.1), `motion_controller.js` (P1.1). No keyboard/nav controller exists yet.
- `theme_picker_controller.js` is the sole reader/writer of
  `document.documentElement.dataset.theme` and the `theme` `localStorage` key; its
  `<select id="theme-picker-select">` lives in
  `app/views/layouts/components/_header.html.erb` with options in the order `light, dark,
  dracula, nord, gruvbox, catppuccin` — this is the exact cycle order `t` must reuse.
- `app/views/layouts/application.html.erb`'s `<body>` carries no `data-controller` today
  — nothing to conflict with mounting `keyboard-nav` there. Standard (non-permanent)
  Turbo Drive visits replace `<body>`'s content on navigation.
- Build: `jsbundling-rails` + webpack 5 (`webpack.config.js`, single `application`
  entrypoint, ES modules via `import`), not esbuild/Vite/importmap.

### Routes today
`config/routes.rb`: `root`, `blog` (`posts_url`)/`blog/:slug`, `projects`/`projects/:slug`,
`resume`, `up`. No `/lab`, no `/writing` (confirms [Out of Scope](#out-of-scope)).

### Header nav today
`_header.html.erb` renders four nav links via Rails route helpers (`root_url`,
`posts_url`, `projects_url`, `resume_path`) plus the P1.1 theme `<select>` — no
`data-nav-target` or `data-keyboard-nav-target` attributes exist yet.

### Content model today
- `Post` (`app/models/post.rb`): `slug`, `title`, `description`, `keywords`, `image`,
  `file_path`, `tags` (json array), `published_at`. **No `excerpt`, no `kind` column** —
  confirms the architecture plan's flagged cross-issue dependency is genuinely unmet
  today (P1.4 has not shipped in this worktree's history).
- `Project` (`app/models/project.rb`): `slug`, `title`, `status` (enum: `Pre-Launch`,
  `Beta`, `Live`), `url`, `image`, `description`.

### Test infrastructure today
- **Ruby-only.** `Gemfile`'s `:test` group: `rspec`, `rspec-rails`,
  `database_cleaner-active_record`, `factory_bot_rails`, `faker`, `shoulda-matchers`,
  `simplecov`, `timecop`, `webmock`. **No Capybara, no Selenium/Cuprite/Playwright gem, no
  `spec/system/` directory.** `spec/` has only `factories/helpers/lib/models/requests/support`.
- **No JS test runner.** `package.json` has no `vitest`/`jest`/test script; only
  `build`/`build:css`.
- `.github/workflows/ci.yml`'s `test` job: checks out, sets up Ruby + Node, runs `yarn
  install --frozen-lockfile`, `bundle exec rake assets:precompile`, `bundle exec rake
  db:prepare`, `bundle exec rake spec` — this is the one job [Testing Strategy](#testing-strategy)
  extends, not replaces.
- `docs/architecture/sub-systems/web-presentation.md`'s Known Limitations already records
  "No system tests / Capybara; coverage is request + model specs" — this issue is what
  retires that limitation.

## Design Doc Amendment

Per the architecture plan §9 (user-approved) and this issue's own "Recommended next
steps," `docs/design/redesign-2026.md` §3's "Signature interaction" subsection is amended
as part of this spec (docs-only change, made in this same worktree/PR):

1. Reframe from "command palette + single-key shortcuts" to the modal
   NORMAL/COMMAND/SEARCH model — `t`, `g h/w/p/l`, `?`, `Esc`, `f` are NORMAL-mode
   bindings under one state machine, not free-floating shortcuts.
2. Drop the `Cmd/Ctrl-K` framing — the modal design uses bare `:` only, deliberately with
   no modifier chord, so it never contends with browser/OS shortcuts.
3. Add the terminal-style mode indicator as a named, explicit UI element.
4. Add `f` hint-jump as its own bullet (previously entirely absent from §3).
5. Tighten the progressive-enhancement/a11y bullet to state outcomes, not mechanism (the
   *how* belongs in this spec).
6. Cross-reference this spec and the architecture plan, matching the existing convention
   where §3 already points at the #1180 spec for D1/D2.

§7's Phase-1 roadmap item 10 and §9's decision log are updated to match (item 10's wording
now says "modal navigation layer" instead of "command palette + single-key shortcuts";
a new decision-log row records the 2026-07-19 reframing, dated and referenced against this
spec, matching the log's existing format).

**Status: done.** The edit is applied to `docs/design/redesign-2026.md` in this same
worktree as part of writing this spec (see the diff accompanying this PR).

## Design Decisions (Restating the Architecture Plan as Buildable Contracts)

The architecture plan's Decisions 1–8 are settled and not re-litigated here; this section
pins the exact names/shapes the plan explicitly left to scribe.

### File/module layout

| Path | Role |
|---|---|
| `app/javascript/controllers/keyboard_nav_controller.js` | The dispatcher/state-machine Stimulus controller (`data-controller="keyboard-nav"`), mounted once on `<body>` in `application.html.erb` |
| `app/javascript/keyboard_nav/resolve_nav_target.js` | `resolveNavTarget(key)` — Decision 6 |
| `app/javascript/keyboard_nav/commands.js` | Command registry + `parseCommand(input)` + `rankCommands(query, registry)` |
| `app/javascript/keyboard_nav/hints.js` | Hint-label alphabet/assignment — `assignHintLabels(elements)` |
| `app/javascript/keyboard_nav/search_index.js` | `rankSearchResults(query, index)` + a thin fetch/cache wrapper |
| `app/javascript/keyboard_nav/theme_cycle.js` | `nextTheme(current)` — the fixed 6-theme cycle order |
| `app/views/layouts/components/_keyboard_status_line.html.erb` | Mode indicator (`aria-live="polite"`) |
| `app/views/layouts/components/_keyboard_command_bar.html.erb` | Shared COMMAND/SEARCH terminal-style input bar (one partial, a `mode:` local selects the placeholder/submit behavior wired by the controller) |
| `app/views/layouts/components/_keyboard_guide_dialog.html.erb` | `?` overlay, native `<dialog>` |
| `app/controllers/search_index_controller.rb` | `GET /search-index.json` — SEARCH's content index (see [R9](#r9--search-content-index-endpoint)) |

All plain-function modules under `app/javascript/keyboard_nav/` take/return plain data —
zero DOM access, zero mocking required, per Decision 1's testability seam and this issue's
[Testing Strategy](#testing-strategy).

### Mode indicator & dispatch guard

Exactly as Decisions 1–2 specify: `mode` is a Stimulus Value (`normal`/`command`/`search`,
default `normal`); status line text is `-- NORMAL --` / `-- COMMAND --` / `-- SEARCH --`;
guard order on every `keydown` is (1) modifier bail, (2) editable-target bail
(`input, textarea, select`, `isContentEditable`), (3) `Escape` special case (acts only if
our layer has something open), (4) mode dispatch (including the `g`-prefix ~600ms buffer),
(5) `preventDefault()` only on keys we act on. `f` hint-jump is a NORMAL sub-state, not a
fourth mode value (status line may append a `HINT` qualifier while active).

### Command registry contract (for P1.9 to extend)

```js
// app/javascript/keyboard_nav/commands.js
{
  name: "projects",       // canonical invocation, typed after ":"
  aliases: ["p"],         // optional shorthand(s)
  description: "Go to the projects page",
  run: (args, context) => { /* ... */ },
}
```

`parseCommand(input)` → `{ name, args }` (first whitespace-delimited token is the name,
remainder is the raw args string — command handlers parse their own args). `rankCommands
(query, registry)` ranks exact name > alias > name-prefix > substring, for live-filtering
as the visitor types (mirrors SEARCH's own ranking discipline). v1 registry: `:home`,
`:writing`, `:projects`, `:resume` (each calls `resolveNavTarget` + `.click()`, Decision
6), `:theme <name>` (validates `<name>` against the 6 registered DaisyUI themes, then
drives the theme `<select>` exactly as `t` does), `:help` (opens the same `?` dialog).
P1.9's metrics commands are added entries in this same array — no registry shape change
required.

### SEARCH index item shape

```json
{ "title": "...", "url": "...", "excerpt": "...", "tags": ["..."], "type": "post" }
```

`type` is `"post" | "project"` — a content-type discriminator for the index, **deliberately
renamed from the architecture plan's `kind`** to avoid collision with `Post`'s own,
unrelated `kind` column (Notes vs. Deep Dives, design doc §5, not yet shipped — see
[R9](#r9--search-content-index-endpoint)). When `Post.kind` ships, it can be added as an
additional facet field (e.g. `"post_kind"`) without changing this shape.

### Hint-jump alphabet

23-character alphabet, excluding the three most visually-ambiguous lowercase letters
(`i`/`l`/`o`, easily confused with `1`/`0` and each other in a small monospace badge):
`a s d f g h j k l q w e r t y u p z x c v b n m` (order = typing-ease priority, home row
first). Single characters cover the first 23 on-screen links; beyond that, two-character
codes are formed the Vimium way (first-character prefix + second-character suffix),
assigned in DOM/tab order, never visual position.

## Requirements

### R1 — Mode state machine + status line (Decision 1)

`keyboard_nav_controller.js`, mounted on `<body>`, owns `mode` as a Stimulus Value;
`modeValueChanged()` is the single place mode transitions are reacted to (show/hide status
line, toggle `document.body.dataset.keyboardMode`, move focus into/out of the
COMMAND/SEARCH bar). Status line markup is plain-CSS hidden by default (nothing to flash
without JS); `connect()` reveals it, unless touch/no-pointer (R8).

### R2 — Global key dispatch guard (Decision 2)

One `document`-level bubble-phase `keydown` listener, attached in `connect()`/removed in
`disconnect()`. Guard order exactly as specified in [Design Decisions](#mode-indicator--dispatch-guard).
Zero ID-/selector-based skip-lists — the single editable-target check protects the P1.1
`<select>`, our own COMMAND/SEARCH `<input>`s, and any future native field uniformly.
Turbo's default `<body>`-replacement lifecycle (not marked `data-turbo-permanent`) resets
mode/listeners/hint state on every navigation — verified by [Increment 0](#increment-0--foundation--test-infrastructure-highest-risk).

### R3 — NORMAL-mode navigation (Decision 1, Decision 6)

`h/j/k/l` scroll (left/down/up/right or the vim line-scroll convention — `j`/`k` line
scroll is the literal ask; `h`/`l` may be a no-op or horizontal scroll depending on page
layout, implementer's call since the site has no horizontal-scroll content today). `gg`
(double-tap within the `g`-prefix window) scrolls to top; `G` scrolls to bottom. `g` + one
of `h`/`w`/`p`/`l` calls `resolveNavTarget("home"|"writing"|"projects"|"lab")` then
`.click()`s the result (or no-ops if `null`, e.g. `lab` today).

### R4 — `data-nav-target` attributes on the header (Decision 6)

Add `data-nav-target="home"` / `"writing"` / `"projects"` / `"resume"` to the four
existing `_header.html.erb` anchors (no new markup, no URL literals — Rails' own
`root_url`/`posts_url`/`projects_url`/`resume_path` remain the single source of the actual
href). `writing` maps to the `posts_url` link (matching the design doc's target IA name,
not the current `blog` route name) so a future `/blog` → `/writing` path rename requires
zero keyboard-layer changes.

### R5 — Theme cycle `t` (Decision 4)

Add `data-keyboard-nav-target="themeSelect"` to the existing `<select
id="theme-picker-select">` (a second controller's target attribute on the same element —
standard Stimulus multi-controller pattern, not a hack). On `t`: read
`document.documentElement.dataset.theme`, compute `nextTheme(current)` over the fixed
order `light → dark → dracula → nord → gruvbox → catppuccin → light` (matching the
`<select>`'s own option order), set `themeSelectTarget.value = next`, dispatch a native
`change` event (`bubbles: true`) so `theme-picker#change` fires exactly as a manual
selection would — one code path, no parallel persistence logic.

### R6 — COMMAND mode (Decision 2, registry above)

`:` (NORMAL) → COMMAND: save `document.activeElement`, move focus into the shared command
bar partial's `<input>`, live-filter/rank the registry via `rankCommands` as the visitor
types. Enter: `parseCommand(input.value)`, look up by exact name/alias/unambiguous prefix
in the registry, call its `run(args, context)`, return to NORMAL, restore prior focus.
Esc: cancel, clear input, return to NORMAL, restore prior focus. Unknown command name:
input stays open with a visible "not found" state (no error thrown, no page action) —
matches vim's own forgiving-on-unknown-input convention already used for the `g`-prefix
buffer.

### R7 — SEARCH mode (Decision 3)

`/` (NORMAL) → SEARCH: save/restore focus identically to R6. First open in a tab session
triggers a lazy `fetch` of `GET /search-index.json` (R9), cached for the rest of the tab
(never re-fetched on subsequent `/` opens in the same session). Typing live-filters via
`rankSearchResults(query, index)` (title-match > tag-match > excerpt-match substring
scoring). `n`/`N` move the highlighted selection down/up **within the open results
list** — SEARCH-mode-scoped keys, not a global "repeat last search" (this resolves the
issue text's ambiguity explicitly, per Decision 3). Enter: `.click()` the highlighted
result's real rendered link (a normal Turbo visit — never a hand-built URL string),
returns to NORMAL on the new page. Esc: cancel, clear input, no navigation.

### R8 — `f` hint-jump (Decision 5)

`f` (NORMAL) → hint-jump sub-state (status line may show a `HINT` qualifier; mode value
stays `normal`). Collect `<a href>` elements within the current viewport in DOM/tab order;
`assignHintLabels` assigns labels from the alphabet above. Render each as an
`aria-hidden="true"`, `pointer-events: none` badge positioned via
`getBoundingClientRect()`. Typing filters to matching hint(s); exact match calls `.click()`
on the real anchor (preserves `target="_blank"`, `rel`, Turbo handling, download
attributes for free). Esc or the first `scroll` event cancels and removes every badge — no
live reposition-on-scroll (named v1 simplification). No focus move, no `tabindex` change,
ever.

### R9 — SEARCH content-index endpoint

New `SearchIndexController#index` (`app/controllers/search_index_controller.rb`), route
`get "search-index.json" => "search_index#index", as: :search_index"` in
`config/routes.rb`, responding JSON-only. Serializes all `Post.published` and all
`Project` records into the item shape in [Design Decisions](#search-index-item-shape):
`title`, `url` (via `post_url(slug:)` / `project_url(slug:)` route helpers — never a
hand-built path string), `excerpt`, `tags`, `type`.

**`excerpt` fallback (resolves the architecture plan's flagged, and now confirmed unmet,
cross-issue dependency without blocking this issue on P1.4):** `excerpt` sources from
`Post#excerpt` **only if that column exists** at implementation time; otherwise it falls
back to `Post#description` (already present, required, similar purpose — a one-sentence
SEO description). `Project` has no `excerpt` equivalent today; its index item uses
`Project#description` (already present) for the same field, truncated to a short excerpt
length for consistency with the Post side. This is a single `has_attribute?(:excerpt)` (or
equivalent) branch in the serializer, not two code paths to maintain — when P1.4 ships
`Post.excerpt`, the fallback branch simply stops firing, no shape change, no follow-up
issue required. `tags` sources from `Post#tags` (already present); `Project` has no tags
field today, so its index items render `tags: []`.

Never render rendered-HTML body content into the index — plain text fields only
(title/description/tags), per Decision 3's rationale.

### R10 — `?` keyboard-guide overlay (Decision 7)

`_keyboard_guide_dialog.html.erb` — a native `<dialog>` (only place a conventional modal
pattern is used in this feature), opened via `.showModal()` on `?`, documenting every
binding from R3–R8 and the command registry's v1 command list, with a note that the
registry is extensible (for P1.9). Closed by `Esc` (native `<dialog>` behavior) or a
visible close control.

### R11 — A11y & no-JS progressive enhancement (Decision 7)

- No focus traps anywhere except the `?` `<dialog>` (native browser behavior, WAI-ARIA APG
  dialog pattern — the one deliberate exception). COMMAND/SEARCH inputs are real,
  `<label class="sr-only">`-labeled `<input>`s (mirroring the theme `<select>`'s existing
  accessible-labeling pattern), never trap, and always save/restore
  `document.activeElement` on entry/exit.
- Status line: `aria-live="polite"` (never `assertive`).
- Hint badges: `aria-hidden="true"` — sighted-power-user affordance layered over, never
  replacing, the existing accessible link structure.
- `prefers-reduced-motion`: reuse the exact `window.matchMedia("(prefers-reduced-motion:
  reduce)").matches` check `motion_controller.js` already uses — no second convention.
  When true, all transitions (status line, bars, hint badges, dialog) are instant.
- Structural progressive enhancement: the layer only ever *adds* a listener and transient
  overlay DOM; it never hides, replaces, or conditionally renders any existing link, nav
  item, or content. A JS-disabled smoke test across every existing route (`/`, `/blog`,
  `/blog/:slug`, `/projects`, `/projects/:slug`, `/resume`) confirms full functionality
  with the layer entirely absent.

### R12 — Touch/mobile no-op (Decision 8)

`matchMedia("(hover: hover) and (pointer: fine)")`, checked once in `connect()` (not
subscribed to live changes, matching `motion_controller.js`'s own one-time
`prefers-reduced-motion` check precedent). When it doesn't match: the document `keydown`
listener is never attached (not just hidden UI) and no status line / `?`-hint affordance
renders at all — an honest "this is a desktop feature," not a dead affordance.

### R13 — Update `web-presentation` architecture doc

`docs/architecture/sub-systems/web-presentation.md`:
- **Anchor Files**: add `app/javascript/controllers/keyboard_nav_controller.js` and
  `app/javascript/keyboard_nav/`.
- **Public Contract**: add `data-controller="keyboard-nav"`; add the `GET
  /search-index.json` route/action; add the three new component partials
  (`components/keyboard_status_line`, `components/keyboard_command_bar`,
  `components/keyboard_guide_dialog` — actual partial directory left to code, consistent
  with where `_header.html.erb`/`_footer.html.erb` already live under
  `layouts/components/`).
- **Key Invariants**: add — "The keyboard-nav layer never intercepts keys in native form
  fields or its own COMMAND/SEARCH inputs (single generic editable-target guard); `Esc`
  always returns to NORMAL; the layer attaches no listener on touch/no-hover-precise-
  pointer devices."
- **Known Limitations**: remove "No system tests / Capybara; coverage is request + model
  specs" (retired by this issue) and replace with whatever residual gap remains after
  [Testing Strategy](#testing-strategy) lands (expected: none for this feature's own
  coverage; note any deferred cross-cutting gap, e.g. CI browser availability, if one
  remains at merge time).

## Testing Strategy

This repo is **Ruby-only + manual today** (see [Current State](#test-infrastructure-today)).
A document-level key dispatcher that intercepts keys on every page and must never swallow
a keystroke in any native form field is exactly the kind of logic that should not ship
verified only by hand. Per the user's decision, **standing up new JS/browser test
infrastructure is in scope for P1.8**, not deferred to a later issue.

### Stack decision

**Browser/system tests: Capybara + Cuprite** (headless Chrome via the Chrome DevTools
Protocol, no Selenium server).

The architecture plan explicitly left this choice open (§10: "a call for the test
agent/orchestrator to make explicitly"). Recommendation and rationale, made explicit here
per the user's instruction:

- This repo's entire test culture today is RSpec (`rspec-rails`, request + model specs,
  `factory_bot`, `shoulda-matchers`). Capybara system specs are RSpec specs
  (`spec/system/*_spec.rb`) — zero new test *language*, zero new assertion library, zero
  new CI job shape. A Ruby-fluent reviewer reads a Capybara spec exactly like every other
  spec in this repo.
- Cuprite (over Selenium+`selenium-webdriver`, or `capybara-webkit`) drives headless
  Chrome directly via CDP: no Selenium server/grid to run or version-pin, no separate
  ChromeDriver binary to keep in sync with the installed Chrome version (a common source
  of CI flakiness with the Selenium route), and it's the actively-maintained, modern
  choice for Rails system specs as of 2026.
- **Playwright was considered and rejected for this issue's scope.** Playwright is a
  capable choice, but it is its own JS-native test runner (`@playwright/test`) with its
  own config, its own assertion library, and its own CI job — a second, parallel test
  toolchain alongside RSpec, for a personal site whose entire test culture is Ruby today.
  That's proportionate for a team already running mixed-language test suites; it is not
  proportionate here, where "stand up JS/browser test infra" should mean "the smallest
  coherent new capability," not "adopt a second test framework." If a future issue's needs
  outgrow Capybara (e.g., true cross-browser matrix testing), that's a re-evaluation for
  that issue, not a reason to pay the cost now.
- GitHub's `ubuntu-latest` Actions runners ship Chrome/Chromium preinstalled, which Ferrum
  (Cuprite's underlying driver) auto-detects with no extra runner setup in the common
  case — **verify this holds at implementation time**; if it doesn't, add a
  `browser-actions/setup-chrome` step to `.github/workflows/ci.yml`'s `test` job rather
  than assuming it away.

**JS unit tests: Vitest.**

The architecture plan itself names this as the natural fit (§10: "pairs easily with the
existing webpack/ESM setup"). All of this feature's pure logic — `resolveNavTarget`,
`parseCommand`/`rankCommands`, `assignHintLabels`, `rankSearchResults`, `nextTheme` — is
deliberately factored into plain ES modules with no DOM access (Decision 1's testability
seam), so Vitest exercises them with zero mocking, zero jsdom setup required for the
majority of cases. Vitest is fast, ESM-native (no Babel/webpack transform step needed for
these modules, since they're already plain `import`/`export`), and has no meaningful
alternative-consideration cost here — it's the standard, current choice for this shape of
problem and the plan already named it.

### Wiring required (in scope for this issue)

- **Gemfile** (`:test` group): add `gem "capybara"`, `gem "cuprite"`.
- **`spec/support/capybara.rb`** (new): register the Cuprite driver
  (`Capybara.register_driver(:cuprite) { |app| Capybara::Cuprite::Driver.new(app,
  headless: true, ...) }`), set `Capybara.javascript_driver = :cuprite` and
  `Capybara.default_driver` appropriately for `type: :system` specs (Rails' own
  `spec/rails_helper.rb` convention — `Capybara.javascript_driver` for `js: true`/system
  specs).
- **`spec/system/`** (new directory) — this issue's own specs (below) are the first
  occupants; it exists for future issues too.
- **`package.json`**: add `vitest` as a devDependency; add a `"test:js": "vitest run"`
  script.
- **`vitest.config.js`** (new, minimal) — points at `app/javascript/keyboard_nav/**/*.test.js`
  (or colocated `__tests__/` directories, implementer's call).
- **`.github/workflows/ci.yml`**: extend the existing `test` job (do not add a new job or
  change `ci-gate`'s `needs` list) with one additional step running `yarn test:js` (fast,
  no Rails boot needed — run it before the Ruby `rspec` step so cheap failures surface
  first). If Chrome isn't already available on `ubuntu-latest` per the note above, add the
  setup step ahead of `bundle exec rake spec` (Cuprite specs run inside the same `rspec`
  invocation as everything else — `bundle exec rake spec` already covers `spec/system/`
  once Capybara is configured, no separate CI step required for those).
- **`bundle exec rake assets:precompile`** (already a CI step) must produce a real,
  working JS bundle + compiled CSS for Cuprite-driven pages to load — this already runs
  before `rake spec` in the existing job, so no reordering needed, but confirm it still
  passes with the new controller/modules added to the webpack entrypoint.

### What gets tested at each layer

- **Vitest (unit, pure logic)**: `resolveNavTarget` (returns element for a known
  `data-nav-target`, `null` for an unknown one, e.g. `lab`); `parseCommand`/`rankCommands`
  (name/alias/prefix/substring ranking, empty-query behavior, unknown-command handling);
  `assignHintLabels` (deterministic single- then two-character assignment across
  alphabet-length boundaries); `rankSearchResults` (title > tag > excerpt ordering,
  empty-query/no-match behavior); `nextTheme` (wraps `catppuccin → light`, handles an
  unrecognized current value gracefully).
- **Capybara/Cuprite (system, real browser)**:
  - Mode switches: `:`/`/`/`Esc` transition the status line text and `document.body`'s
    `data-keyboard-mode` correctly from a real page.
  - Input-focus guards: typing into an existing native field (e.g. the theme `<select>`'s
    typeahead, or a future text field) is completely unaffected by the layer — the
    canonical regression this feature must never introduce; assert on every route in
    [R11](#r11--a11y--no-js-progressive-enhancement)'s smoke-test list, not just one page.
  - `/` search: opens the bar, live-filters, Enter performs a real Turbo navigation to the
    expected page.
  - `f` hint-jump: badges render over real on-screen links, typing a hint label performs
    the same navigation a real click would, Esc/scroll removes all badges.
  - Theme-cycle via `t`: pressing `t` updates the *same* `<select>`'s value and
    `localStorage`, identically to a manual dropdown selection (proves the single-code-path
    claim in R5, not just that some theme changed).
  - Turbo-navigation listener hygiene: a manual/scripted check (per the architecture
    plan's suggested temporary console counter, or an equivalent assertion) that exactly
    one `keydown` listener is ever live across several Turbo-driven navigations —
    Increment 0's highest-risk item.
  - No-JS / layer-off smoke test remains a **manual** browser check (Capybara/Cuprite
    always runs JS — it cannot assert a JS-disabled page load); this one item stays
    documented as manual verification per increment, not a gap in the new infra.
- **RSpec request spec**: `SearchIndexController#index` returns the documented JSON shape
  (R9), including the `excerpt` fallback behavior when `Post.excerpt` is absent.
- **Manual, still (not automatable meaningfully with Cuprite at this issue's scope)**:
  `prefers-reduced-motion` visual behavior (matches existing manual-only precedent for
  `motion_controller.js`) and a full WCAG AA contrast/screen-reader pass on new UI
  (status line, bars, dialog) across all 6 themes — spot-checked per theme before merge,
  same discipline as P1.1's contrast gate.

## Implementation Increments

Sequencing preserves the architecture plan's foundation-first order (§4), folding the
now-resolved testing-infrastructure question into Increment 0 rather than leaving it as a
separate, undecided slice (superseding the plan's placeholder "Increment 7" open-decision
step — the decision above resolves it, so infra stands up alongside the first shippable
increment instead of blocking behind a later, separate decision point).

### Increment 0 — Foundation + test infrastructure (highest risk)

Mode state machine + global dispatch guard (R1–R2) + status line, with the narrowest
possible payoff bound to it (`Esc`-to-NORMAL and `?` as a bare toggle). Stand up Capybara +
Cuprite and Vitest, wired into CI, in this same increment (per [Testing Strategy](#testing-strategy))
— every later increment's automated coverage depends on this existing first.

**Acceptance criteria:**
- [ ] `Esc` returns to NORMAL and `?` toggles the guide dialog on every existing route.
- [ ] Typing in the P1.1 theme `<select>` and any other native field on every existing
      route is completely unaffected — verified by an automated Capybara spec covering
      every route in R11's list, not just manual spot-checks.
- [ ] No duplicate `keydown` listeners across repeated Turbo-driven navigations (verified
      per [Testing Strategy](#testing-strategy)).
- [ ] Full site functions with JavaScript disabled (manual smoke test, all routes).
- [ ] `yarn test:js` (Vitest) and the Capybara/Cuprite system specs both run green
      locally and in CI (`.github/workflows/ci.yml`'s `test` job).
- [ ] The `docs/design/redesign-2026.md` §3 amendment is merged (may land in this
      increment's PR or ahead of it — docs-only, no code dependency).

### Increment 1 — NORMAL-mode core navigation

`h/j/k/l` + `j/k` scroll, `gg`/`G`, `g` + `h/w/p/l` page jumps via `resolveNavTarget` (R3–R4).

**Acceptance criteria:**
- [ ] `gg`/`G` scroll to top/bottom on a long page (e.g. a Deep Dive post).
- [ ] Each `g`-jump navigates to the header nav link's *actual, current* URL — no
      hardcoded path literal anywhere in the JS (`resolveNavTarget` unit-tested per
      [Testing Strategy](#testing-strategy)).
- [ ] `g l` (lab) is a documented no-op today (`resolveNavTarget("lab")` returns `null`).

### Increment 2 — Theme cycle (`t`)

Wires into the existing theme-picker controller/select (R5).

**Acceptance criteria:**
- [ ] `t` advances through all 6 themes in the `<select>`'s own order, wrapping
      `catppuccin → light`.
- [ ] After `t`, the `<select>`'s visible value and `localStorage["theme"]` both reflect
      the new theme — identical outcome to a manual dropdown change (Capybara-verified).
- [ ] `nextTheme` unit-tested for the wrap case and an unrecognized-current-value case.

### Increment 3 — COMMAND mode

`:` + the registry + a v1 command set (R6).

**Acceptance criteria:**
- [ ] `:` opens the bar, moves focus into it, and the status line reads `-- COMMAND --`.
- [ ] `:home`, `:writing`, `:projects`, `:resume` each navigate to the correct page via
      `resolveNavTarget`; `:theme <name>` sets the theme identically to R5's `t` path.
- [ ] Esc/Enter both return to NORMAL and restore focus to whatever had it before entry
      (not assumed to be `document.body`).
- [ ] An unrecognized command name leaves the bar open with a visible "not found" state,
      no thrown error, no page action.
- [ ] `parseCommand`/`rankCommands` unit-tested (ranking order, unknown input).

### Increment 4 — SEARCH mode

`/` + the content-index endpoint (R9) + results list + `n`/`N` (R7).

**Acceptance criteria:**
- [ ] `GET /search-index.json` returns the documented shape for both `Post.published` and
      `Project` records; `excerpt` fallback verified when `Post.excerpt` is absent
      (RSpec request spec).
- [ ] `/` opens SEARCH, fetches the index lazily on first open, live-filters as the
      visitor types, and does not re-fetch on a second `/` open in the same tab session.
- [ ] `n`/`N` move the highlighted selection within the open results list only (not a
      global repeat-search) — this scoping is asserted, not left implicit.
- [ ] Enter performs a real navigation (via `.click()` on the rendered result link) to the
      highlighted result.
- [ ] `rankSearchResults` unit-tested (title/tag/excerpt ordering).
- [ ] **Cross-issue dependency check performed and documented at implementation time**:
      confirm whether `Post.excerpt`/`Post.kind` (P1.4) have shipped; if not, the fallback
      in R9 is exercised and this is noted in the PR, not silently worked around.

### Increment 5 — `f` hint-jump

Overlay positioning, activation, and cancel semantics (R8).

**Acceptance criteria:**
- [ ] `f` labels every on-screen `<a href>` in DOM/tab order using the documented
      alphabet, single- then two-character as needed.
- [ ] Typing an exact hint label activates that link identically to a real click
      (including `target="_blank"`/`rel`/Turbo handling).
- [ ] Esc and the first `scroll` event both cancel and remove every badge, with zero
      leftover focus/tabindex/DOM trace afterward.
- [ ] `assignHintLabels` unit-tested across the single-to-two-character alphabet
      boundary.

### Increment 6 — `?` guide overlay

Documents everything shipped in Increments 1–5 (R10).

**Acceptance criteria:**
- [ ] `?` opens a native `<dialog>` listing every binding shipped so far and the command
      registry's v1 command list, with a note that it's extensible (for P1.9).
- [ ] `Esc` closes it via `<dialog>`'s native behavior; a visible close control also
      works.
- [ ] Opening/closing the dialog is covered by a Capybara system spec.

### Cross-cutting (verified across all increments, not a separate slice)

- [ ] `prefers-reduced-motion` respected everywhere motion appears (manual verification,
      per [Testing Strategy](#testing-strategy)).
- [ ] Touch/no-precise-pointer devices attach no listener and render no affordance
      (R12) — verified manually at minimum; automated Cuprite touch/pointer emulation is
      a bonus if the implementer finds it straightforward, not a gate.
- [ ] WCAG AA contrast spot-check on the status line, command/search bars, and guide
      dialog across all 6 bundled themes.

## Acceptance Criteria

Consolidated view of the per-increment criteria above, plus issue-level gates:

- [ ] All per-increment acceptance criteria in
      [Implementation Increments](#implementation-increments) pass.
- [ ] `docs/design/redesign-2026.md` §3/§7/§9 reflect the [Design Doc Amendment](#design-doc-amendment).
- [ ] `docs/architecture/sub-systems/web-presentation.md` reflects R13.
- [ ] Existing `ci-gate` (`lint` + `test`) stays green, now including `yarn test:js` and
      the new Capybara/Cuprite system specs within the same `test` job.
- [ ] No regression to any native form field's typing behavior anywhere on the site
      (the single hardest requirement this feature must never violate).
- [ ] Full site functions with the keyboard layer entirely absent (JS-disabled smoke
      test, manual).

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns)
and the scribe's own delegation rules:

- **Implementation** (all of R1–R13: the Stimulus controller, pure ES modules, ERB
  partials, `SearchIndexController`, header attribute additions, standing up
  Capybara/Cuprite + Vitest + CI wiring, the increment sequence, and the architecture-doc
  update): delegate to the **code** agent, building in the increment order above — per the
  architecture plan's own handoff note, do not start increment N+1 before increment N is
  reviewed, given Increment 0's site-wide blast radius if its guard clause is wrong.
- **Test authorship** (the Vitest unit specs and Capybara/Cuprite system specs named in
  [Testing Strategy](#testing-strategy)): per this repo's test-ownership convention, the
  **test** agent is the sole owner of test code — code agent implements the feature and
  the infra wiring (Gemfile, CI config, `vitest.config.js`), test agent writes the actual
  spec files against it.
- **GitHub Issues lifecycle** (board status, closing on merge, unblocking P1.9): delegate
  to the **orchestrator** — this spec does not perform those operations.
- **Manual verification** (JS-disabled smoke test, `prefers-reduced-motion` visual check,
  per-theme contrast spot-check): part of the implementer's own pre-PR verification (the
  `verify` skill), not a separate agent.
- **Exact CSS/z-index/spacing values** for the status line, command/search bars, and hint
  badges beyond what's specified here: implementer/visual-QA call within the stated
  a11y/contrast constraints, consistent with how the P1.1 spec left analogous visual
  details open.

## Open Questions

1. **`h`/`l` behavior where there's no horizontal scroll to speak of.** R3 leaves this to
   the implementer (no-op vs. a horizontal-scroll no-op-by-construction) since no page on
   the site currently has horizontally-scrollable content — not a blocking ambiguity,
   since either choice is behaviorally identical today.
2. **Whether GitHub's `ubuntu-latest` runner needs an explicit Chrome/Chromium setup
   step for Cuprite.** Flagged in [Testing Strategy](#testing-strategy) as "verify at
   implementation time" rather than assumed — a small, contained CI-config decision, not
   a spec-blocking one.
3. **Exact partial directory for the three new component partials** (R13 leaves
   `layouts/components/` as the strong precedent but doesn't hard-require it over
   `app/views/components/`, which P1.1 also established for shared, non-layout-specific
   partials). Either is consistent with existing conventions; implementer's call,
   documented in the architecture-doc update either way.
4. **P1.4 landing before or after this issue.** [R9](#r9--search-content-index-endpoint)'s
   fallback means SEARCH ships correctly either way; if P1.4 lands first, Increment 4
   simply exercises the `Post.excerpt`/`Post.kind` path instead of the fallback — no spec
   change needed in either order.

## Changelog

### Version 1 - 2026-07-19
**Source Issue:** bitidev/jamesebentier.com#1187
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification for the modal NORMAL/COMMAND/SEARCH keyboard navigation layer,
  built directly from the approved architecture plan's Decisions 1–8: mode state machine
  + status line, global dispatch guard, NORMAL-mode nav, theme-cycle reuse of the P1.1
  theme picker, COMMAND mode + extensible registry, SEARCH mode + content index, `f`
  hint-jump, `?` guide overlay, a11y/no-JS progressive enhancement, touch no-op
- Pinned the exact file/module layout, command registry shape, search-index item shape
  (renaming the architecture plan's `kind` field to `type` to avoid a collision with
  `Post`'s own, unrelated `kind` column), and the 23-character hint-label alphabet — all
  explicitly left to scribe by the architecture plan
- Resolved the architecture plan's flagged, and now-confirmed-unmet, cross-issue
  dependency (`Post.excerpt`/`Post.kind`, P1.4, not yet shipped in this worktree) with an
  explicit, non-blocking fallback in R9 rather than gating Increment 4 on another issue
- Made the testing-strategy decision the architecture plan explicitly deferred (§10):
  Capybara + Cuprite for browser/system specs, Vitest for ES-module unit tests, both
  stood up as in-scope work in Increment 0, with concrete Gemfile/`package.json`/CI wiring
  named; documented why Playwright was considered and not chosen for this issue's scope
- Amended `docs/design/redesign-2026.md` §3 (dropped the `Cmd/Ctrl-K` framing, added the
  mode indicator and `f` hint-jump, reframed "palette + shortcuts" to the modal model),
  §7 roadmap item 10, and §9 decision log, per the architecture plan's user-approved §9
  amendment recommendation
- Kept the architecture plan's foundation-first increment order (0–6), folding test-infra
  stand-up into Increment 0 rather than treating it as a separate, still-open decision
  slice, since the user's decision resolves it ahead of any code landing

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by
the code agent (feature) and test agent (specs), per
[Delegation / Handoff](#delegation--handoff).

---
