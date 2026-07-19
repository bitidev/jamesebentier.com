Architecture Plan: Modal Vim-Style Keyboard Navigation (site-as-terminal)
==========================================================================

- **Issue**: [#1187](https://github.com/bitidev/jamesebentier.com/issues/1187) — P1.8
- **Epic**: Phase 1 (#1179). Design doc: `docs/design/redesign-2026.md` §3.
- **Author**: architect (technical design pass, pre-spec, per product agent's
  recommendation on #1187)
- **Date**: 2026-07-19
- **Status**: Draft — for user review before scribe writes the spec

This is an **architecture pass**, not a spec and not implementation. It settles the eight
open decisions the product agent flagged, so scribe can write a spec without re-litigating
them, and code can build against firm seams. Exact file names, CSS values, and copy are
left to scribe/code except where a name is needed to make a decision concrete.

---

## 1. Overview

The issue expands P1.8 from "command palette + shortcuts" into a full modal
NORMAL/COMMAND/SEARCH navigation layer, styled after neovim and directly inspired by
commitmono.com. It is a pure **web-presentation** subsystem feature: new Stimulus
controller(s), a few small plain-JS helper modules, a handful of new/updated ERB
partials, and (for SEARCH) a small server-side JSON serialization of existing
`Post`/`Project` data. No new subsystem, no new dependency edge — see §9.

Product's collision audit already confirmed there are **no existing document/window-level
key listeners anywhere in the codebase** — this design doesn't need to reconcile any prior
keyboard behavior, only the P1.1 theme-picker `<select>` and ordinary native form-field
focus (Rule 2 below).

---

## 2. Requirements Analysis

From the issue's "ADLC delivers" and "Done when" sections, restated as constraints this
design must satisfy:

1. A mode state machine (NORMAL default / COMMAND `:` / SEARCH `/`) with a visible
   terminal-style indicator and `Esc`-always-to-NORMAL.
2. NORMAL-mode nav: `h/j/k/l`, `j/k` line-scroll, `gg`/`G`, `g h/w/p/l` page jumps, `t`
   theme cycle, `?` guide overlay.
3. COMMAND mode: `:` opens a command input; an extensible registry (nav commands today,
   P1.9 metrics queries later).
4. SEARCH mode: `/` opens content search; `n`/`N` step through results.
5. `f` hint-jump: label every on-screen link, type to activate.
6. Zero regression to native form-field focus anywhere on the site, and zero interference
   with browser/OS shortcuts.
7. Full progressive enhancement: no focus traps, screen-reader friendly,
   `prefers-reduced-motion` respected, 100% of site functionality (nav, links, browser
   find) works with the layer entirely absent.
8. Desktop/hardware-keyboard feature only — graceful, honest no-op on touch.

Two codebase facts materially shape the design (confirmed by direct inspection, not
assumption):

- **No JS unit-test or browser/system-test infrastructure exists today.**
  `docs/architecture/sub-systems/web-presentation.md` already records this as a known
  limitation ("No system tests / Capybara; coverage is request + model specs"). This is
  the single biggest risk to shipping a document-level key dispatcher safely — see §8
  Increment 0 and §10.
- **`/lab` (and `/writing` as a path) do not exist yet.** `config/routes.rb` today only
  defines `/`, `/blog`, `/blog/:slug`, `/projects`, `/projects/:slug`, `/resume`, `/up`.
  The design-doc IA's `/writing` and `/lab` (§4) are aspirational/Phase 2. The page-jump
  and command-registry design (Rules 4, 6 below) must not hardcode a broken `/lab` target
  — see §6.4.

---

## 3. Proposed Architecture

### Decision 1 — Mode state machine: where state lives, entry/exit, indicator

**Resolution: a single top-level Stimulus controller *is* the dispatcher and the state
machine**, not a hand-rolled dispatcher class alongside it. This isn't an either/or once
Stimulus's own idioms are used correctly:

- New controller, e.g. `app/javascript/controllers/keyboard_nav_controller.js`,
  registered as `data-controller="keyboard-nav"`, **mounted once on `<body>`** in
  `app/views/layouts/application.html.erb` (currently `<body>` carries no
  `data-controller` — nothing to conflict with). `<body>` is already the natural
  per-page singleton; Turbo's normal visit lifecycle disconnects/reconnects it on every
  navigation (see the Turbo note under Decision 2), which gives mode-reset-to-NORMAL,
  fresh hint targets, and no leaked listeners *for free* — do **not** mark this element
  `data-turbo-permanent`, which would defeat that reset.
- Mode is a Stimulus **Value** (`static values = { mode: { type: String, default:
  "normal" } }`), not a hand-rolled field. Stimulus's `modeValueChanged()` callback is the
  single place that reacts to a mode change: show/hide the status line, toggle
  `document.body.dataset.keyboardMode` (a CSS hook other elements can key off if needed),
  move focus into/out of the COMMAND/SEARCH input. Using the Value API instead of manual
  state bookkeeping means less code and one canonical place transitions happen.
- The controller stays thin as an *orchestrator*: keydown routing, mode transitions,
  target/action wiring. The logic that doesn't need the DOM — key-sequence parsing,
  hint-label generation/ranking, search-index scoring, "next theme in the cycle,"
  command-registry lookup — is factored into small plain ES modules (e.g. under
  `app/javascript/keyboard_nav/`) that the controller imports and calls. This is the
  testability seam: those modules are pure functions over plain data, callable the moment
  any JS test runner exists in this repo (see §8 Increment 0 and §10), with zero DOM
  mocking required.
- **Entry/exit**:
  - NORMAL is the default and the only mode that has an active key-binding table beyond
    `Esc`.
  - `:` (NORMAL) → COMMAND: focus moves into a real `<input>` in a fixed-position
    terminal-style bar; Enter submits (through the command registry, Decision 6) and
    returns to NORMAL; Esc cancels and returns to NORMAL, restoring focus to whatever had
    it before (save `document.activeElement` on entry, restore on exit — never assume
    `document.body`).
  - `/` (NORMAL) → SEARCH: same input/focus/exit shape as COMMAND, wired to search
    (Decision 3) instead of the command registry.
  - `f` (NORMAL) → a **transient NORMAL sub-state** (hint-jump), not a fourth top-level
    mode — the visible mode indicator keeps showing `NORMAL` (optionally with a `HINT`
    qualifier) while hint badges are overlaid. This matches the issue's own three-mode
    framing and keeps the state machine genuinely three-valued; hint-jump is scoped
    separately in Decision 5.
  - `Esc` always returns to NORMAL from COMMAND, SEARCH, or hint-jump, and always closes
    the `?` guide overlay — see Decision 2 for exactly when it's allowed to act, and §6
    for why it's the one binding safe to leave un-guarded against focus location.
- **Status line**: a small fixed-position (e.g. bottom-right corner), `font-mono`,
  low-contrast-until-active element rendering `-- NORMAL --` / `-- COMMAND --` /
  `-- SEARCH --` (vim's own convention, and consistent with the "refined terminal"
  personality). Default markup state is plain-CSS **hidden** (not JS-added-hidden — there
  is nothing to flash, since this element has no meaning without JS); `connect()` reveals
  it. `aria-live="polite"` on the text node so mode changes are announced without being
  disruptive (`assertive` would interrupt on every keystroke, which is wrong). Hidden
  entirely on touch-primary devices — see Decision 7.

### Decision 2 — Global key dispatch that coexists with native focus, site-wide

**Resolution: one `document`-level `keydown` listener, bubble phase, attached in
`connect()` / removed in `disconnect()`, with a single generic guard clause that both
protects other people's form fields and our own mode-UI inputs — no per-element
special-casing.**

Guard order, evaluated on every keydown before any mode logic runs:

1. **Modifier bail** — if `event.ctrlKey || event.metaKey || event.altKey`, do nothing
   and let the browser handle it. Nothing in this design's binding set uses a modifier
   chord (bare letters, `:`, `/`, `?`, `Esc` only — `Shift` for capitals like `G` doesn't
   count as a modifier here). This is a deliberate, explicit break from the *original*
   §3 text, which floated `Cmd/Ctrl-K` for the command palette — the modal design drops
   modifier-chord invocation entirely so it can never contend with browser/OS shortcuts
   (devtools, print, find, new tab, etc.). Call this out in the §3 amendment (§11).
2. **Editable-target bail** — if `event.target` (equivalently `document.activeElement`)
   matches `input, textarea, select` or has `isContentEditable` (including inside a
   `[contenteditable]` ancestor), do nothing; let the native field and the browser handle
   the key. This single, generic check is what protects:
   - the shipped P1.1 theme-picker `<select id="theme-picker-select">` (native
     select-with-typeahead behavior is untouched),
   - any future native field (e.g. the Phase-1-roadmap newsletter `<input type="email">`,
     item 7 in §7 of the design doc — not yet built, but the guard already covers it with
     zero new code the day it lands), and
   - **our own COMMAND/SEARCH `<input>`** — while either mode's input has focus, this
     same check bails the document-level listener on every keystroke, so ordinary typing
     flows to the browser natively. Enter/Escape for *those* inputs are wired as
     element-scoped Stimulus actions on the input itself (`data-action="keydown.enter->
     keyboard-nav#commit keydown.esc->keyboard-nav#cancel"`), not as document-level
     special cases. One guard clause serves both "don't break the user's form field" and
     "don't break our own UI" — there is no ID- or selector-based skip-list to keep in
     sync.
3. **`Escape`, evaluated before the editable-target bail returns control** — but only
   *acts* if our own layer currently has something open (mode ≠ NORMAL, or hint-jump
   active, or the `?` guide is open); otherwise it's a no-op and falls through to
   whatever the browser/native element would otherwise do with it. This is safe to leave
   unguarded by focus location because `Escape` has no destructive native meaning inside
   a text field (it doesn't submit or clear), so "Esc always closes our overlay, even if
   you're mid-type in some unrelated field" never surprises anyone. This is the one
   documented exception to guard #2.
4. Otherwise, dispatch to the current mode's binding table. In NORMAL, this includes the
   `g`-prefix sequence buffer: on `g`, arm a pending-prefix flag with a short timeout
   (≈600ms, matching the "forgiving, no error on unknown sequence" vim convention);
   `g`+`g`/`h`/`w`/`p`/`l` within the window resolves; anything else, or timeout, silently
   clears the buffer.
5. Only keys we actually act on call `event.preventDefault()` — never inside a bail
   branch, and never for keys outside our binding table, so every unhandled key (Page
   Down, arrow keys outside our bindings, etc.) keeps its native browser behavior.

**Turbo lifecycle note**: standard Turbo Drive visits replace `<body>`'s content, which
disconnects and reconnects the `keyboard-nav` controller on every navigation — this is
the desired reset (fresh mode = NORMAL, fresh hint targets, fresh search-index cache
reference, and critically, no doubled-up listeners). The one way to accidentally defeat
this is marking the root element `[data-turbo-permanent]`, which this design explicitly
avoids. Increment 0 (§8) should include a manual check (e.g. a temporary console counter)
confirming exactly one listener is ever live across several Turbo-driven navigations,
since a regression here would be a site-wide, every-page bug.

### Decision 3 — SEARCH: prebuilt content index vs. DOM-highlight

**Resolution: client-side prebuilt content index, fetched lazily, not DOM text
highlighting.**

Rationale:
- **Scope mismatch**: DOM-highlight is inherently in-page-only. This site's real search
  value is cross-page — finding a Post or Project by title/tag, not finding a word inside
  the article you're already reading (the browser's own Ctrl/Cmd-F already does that
  perfectly, and guard #1 above deliberately never touches modifier chords, so native
  find remains fully available and unconflicted).
- **Complexity/fragility**: a generic DOM TreeWalker highlighter has a large edge-case
  surface (skipping script/style, nested marks, restoring exact original DOM on cancel,
  re-render safety) for a personal content site with a small number of items — that
  complexity buys little here.
- **Bundle size is a non-issue at this site's scale**: a JSON index of `{ title, url,
  excerpt, tags, kind }` per `Post`/`Project` (reusing the `excerpt`/`kind` fields already
  planned in design doc §5 / Phase 1 item 4) is tens of KB at most for a personal blog's
  post/project count — trivial next to the Commit Mono/Inter webfonts already shipped.
  Never render the rendered-HTML body into the index — plain text fields only, both
  because it's all the search needs and to avoid ever injecting rendered HTML into a
  client-side data structure.

Shape:
- A small serialization path in web-presentation (a thin controller action or helper —
  naming left to scribe/code) exposes the index as JSON, sourced from `Post`/`Project`
  (an existing, already-permitted **web-presentation → content-domain** read — no new
  dependency edge; see §9). It is **not** embedded in every page's HTML (that would
  duplicate the same payload on every response); it's fetched once, lazily, the *first*
  time the user actually opens SEARCH (`/`), then cached for the rest of the tab session.
  Visitors who never press `/` pay zero cost.
- `/` opens SEARCH: a bottom terminal-style input, same shape as COMMAND's bar. Typing
  live-filters a results list (title match ranked above tag match above excerpt match —
  simple substring scoring is enough at this scale; no need for a fuzzy-match library).
- **`n`/`N` semantics (resolving an ambiguity in the issue's phrasing)**: `n`/`N` move the
  highlighted selection up/down **within the currently-open SEARCH results list** — they
  are SEARCH-mode-scoped bindings, not a NORMAL-mode global "repeat last search." This
  reads naturally from the issue text ("SEARCH mode ... n/N to step through results") and
  avoids the added complexity of persisting "last query" state across a mode return with
  no on-screen indication a search is still "live." Flag this explicitly to scribe as the
  resolved semantics, since the issue's wording was ambiguous either way.
- Enter navigates (a normal Turbo visit, via `.click()` on the result's rendered link
  or an equivalent programmatic navigation — never construct a URL string by hand; see
  the single-source-of-truth pattern in Decision 6) to the highlighted result and returns
  to NORMAL on the new page.
- Esc cancels, clears the input, no navigation.

### Decision 4 — Theme cycling (`t`) vs. the P1.1 theme-picker `<select>`

**Resolution: `t` drives the *existing* `<select>` and its *existing* `change` handler —
it does not reimplement theme application.**

`theme_picker_controller.js` is already the single writer of
`document.documentElement.dataset.theme` and the `theme` localStorage key (both `STORAGE_KEY`
and `DEFAULT_THEME` are already documented as shared with the layout's render-blocking
inline script). Duplicating that two-line apply+persist logic inside the new keyboard
controller would create two code paths that must be kept in sync — exactly the
duplicate-logic shape the architect is required to reject.

Instead:
- Add a second Stimulus target attribute onto the *same* `<select id="theme-picker-select">`
  element in `_header.html.erb`: `data-keyboard-nav-target="themeSelect"` (Stimulus
  supports one element carrying attributes for multiple controllers — this is the
  idiomatic pattern, not a hack).
- On `t`, the keyboard controller reads the current theme from
  `document.documentElement.dataset.theme` (the same source of truth
  `theme_picker_controller#connect()` already reads), computes the next theme in the
  **same order as the `<select>`'s own `<option>` list** (`light → dark → dracula → nord
  → gruvbox → catppuccin → light`, matching both `_header.html.erb` and
  `application.tailwind.css`'s `@plugin "daisyui"` theme list, so cycling with `t` and
  scrolling the dropdown feel like the same mental model), sets
  `themeSelectTarget.value = next`, and dispatches a native `change` event on it
  (`themeSelectTarget.dispatchEvent(new Event("change", { bubbles: true }))`).
- The existing `data-action="theme-picker#change"` binding fires exactly as if the
  visitor had picked it from the dropdown — same function, same persistence, same
  `<select>` element whose visible value now also flips as `t` cycles (a visible,
  mechanical confirmation that the two entry points are one code path, not two).
- **Consequence**: if `theme_picker_controller.js` ever changes its persistence mechanism,
  `t` inherits the change for free with no separate maintenance. This is the concrete
  single-source-of-truth win the architect principle requires.

### Decision 5 — `f` hint-jump overlay

**Resolution: a Vimium-style, links-only, viewport-scoped, purely additive overlay —
never touches the underlying accessibility tree or tab order.**

- On `f` (NORMAL), collect `<a href>` elements currently within the viewport (v1 scope:
  links only, not buttons/other controls — matches the issue's own wording ["labels
  every link on screen"] and keeps first-cut a11y/complexity risk down; those other
  controls are already Tab-reachable). Off-screen links are out of v1 scope
  (no scroll-to-reveal) — an explicit, named simplification, not an oversight.
- Assign short hint labels deterministically in DOM/tab order (not visual position),
  from a small fixed alphabet (Vimium-style two-character codes once more than the
  single-character alphabet is exhausted).
- Render each hint as a small `aria-hidden="true"`, `pointer-events: none` badge,
  absolutely positioned via `getBoundingClientRect()` at the link's corner, styled with
  the existing `font-mono`/amber-accent tokens. `pointer-events: none` is required so a
  mouse user can still click straight through a badge to the real link underneath at any
  time — the overlay must never block the pointer path that already works with JS off.
- Typing subsequent letters filters to the matching hint(s); on an exact match, activate
  by **calling `.click()` on the real anchor element** — never construct or assign
  `location.href` by hand. `.click()` preserves `target="_blank"`, `rel`, Turbo's own
  link handling, and download attributes for free, exactly as a mouse click would.
- **No focus trap, no tab-order change, ever**: entering hint-jump moves no DOM focus and
  sets no `tabindex` on anything — the underlying links keep their normal position in the
  accessibility tree throughout. Hints are a purely visual, keydown-driven affordance
  layered *on top of*, never *instead of*, the existing accessible link structure — which
  is also why the badges are `aria-hidden`: screen-reader users already have native
  landmark/link-list navigation and must not have hint noise injected into it.
- Esc, or the **first scroll event** while hints are shown, cancels hint-jump and removes
  every injected badge (treat scroll as an implicit cancel rather than recomputing badge
  positions live — an explicit v1 simplification to flag, not a silent gap; live
  reposition-on-scroll is a reasonable follow-up, not a blocker).

### Decision 6 — A single-source-of-truth nav-target lookup (feeds both `g`-jumps and COMMAND)

Not one of the numbered decisions in the issue, but a load-bearing design point that
resolves the "Requirements Analysis" fact that `/lab` doesn't exist yet (§2) and prevents
a second, hardcoded copy of the URL map living in JS:

- `_header.html.erb` already renders the site's canonical nav links using Rails route
  helpers (`root_url`, `posts_url`, `projects_url`, `resume_path`) — this is the *one*
  place URLs are declared, and it's already always correct because Rails generates it.
- Tag those existing anchors with a stable `data-nav-target="home|writing|projects|
  resume"` attribute (and `lab` once `/lab` ships in Phase 2 — simply absent until then).
  A tiny shared lookup helper, e.g. `resolveNavTarget(key)` in
  `app/javascript/keyboard_nav/`, queries `[data-nav-target="${key}"]` and returns the
  element (or `null`).
- **Both** the `g h/w/p/l` sequence handler **and** the COMMAND registry's navigate
  commands (`:projects`, `:writing`, `:home`, `:resume`) call this one function and then
  `.click()` the result — one lookup, two entry points, no duplicated URL strings in JS
  anywhere.
- This makes the `/lab` gap self-resolving rather than something to special-case: `g l`
  and a future `:lab` command simply no-op today because `resolveNavTarget("lab")`
  returns `null` — no hardcoded broken link, no dead command, and zero code changes
  needed the day `/lab` ships (just add the `data-nav-target="lab"` attribute to the new
  header link). It also means a future `/blog` → `/writing` path rename (design doc §4)
  requires **zero** changes to the keyboard layer, since it never held a literal path
  string.
- This lookup is exactly the kind of pure, DOM-adjacent-but-not-stateful helper worth
  keeping in its own small module for the testability reasons in Decision 1/§10.

### Decision 7 — A11y & no-JS fallback

- **Progressive enhancement is structural, not a checklist item bolted on after**: the
  layer only *adds* a document keydown listener and transient overlay DOM; it never
  hides, replaces, or conditionally renders any existing link, nav item, or content.
  Every existing nav/search/link path is already unconditionally rendered server-side —
  there is nothing this design needs to "fall back to," because nothing was moved behind
  JS in the first place. Confirm this with a JS-disabled smoke test as part of Increment
  0's acceptance (per the issue's "Done when").
- **No focus traps** anywhere in the interactive layer itself: COMMAND/SEARCH inputs
  receive focus on entry (an expected, visible move, not a trap) and Esc/Enter always
  return focus to whatever had it before entry (save/restore `document.activeElement`,
  never assume `document.body`). Hint-jump moves no focus at all (Decision 5).
- **One deliberate exception**: the `?` keyboard-guide overlay is the one place a
  conventional modal pattern is appropriate — recommend the native `<dialog>` element
  specifically for it (not for COMMAND/SEARCH), since `<dialog>` gives focus-containment,
  `Esc`-to-close, and `::backdrop` semantics from the browser for free, and a genuine
  full-panel "here are all the bindings" help dialog is exactly the WAI-ARIA APG dialog
  pattern's intended use. COMMAND/SEARCH stay plain, non-trapping, non-blocking bars —
  deliberately lighter-weight than a modal, matching vim's own non-modal command-line
  feel.
- **Screen-reader friendliness**: the status line uses `aria-live="polite"` (not
  `assertive` — mode changes shouldn't interrupt). COMMAND/SEARCH inputs are real,
  `<label class="sr-only">`-labeled `<input>` elements, mirroring the existing
  theme-picker `<select>`'s own accessible-labeling pattern for consistency. Hint badges
  are `aria-hidden="true"` (Decision 5) — this feature is a sighted-power-user affordance
  layered over, never in place of, the existing accessible structure.
- **`prefers-reduced-motion`**: reuse the *exact* media query `motion_controller.js`
  already checks (`window.matchMedia("(prefers-reduced-motion: reduce)").matches`) for
  any transition on the status line, command/search bars, hint badges, or guide overlay —
  do not introduce a second reduced-motion convention. When it matches, elements appear/
  disappear instantly, no transition.

### Decision 8 — Mobile / touch

- Feature-detect via `matchMedia("(hover: hover) and (pointer: fine)")` — the standard
  signal for "primary input is a precise pointer," which correlates with "a hardware
  keyboard is plausibly nearby" far better than UA-sniffing or a viewport-width
  breakpoint.
- When it doesn't match: **skip attaching the document keydown listener entirely** (not
  just hiding the status line) — both a minor efficiency win and an honest mechanical
  fact ("this is a desktop feature") rather than a UI-only convention. No visual
  affordance (status line, any "press `?`" hint) is rendered either, so there is no dead
  affordance implying a feature that isn't there.
- Checked once at `connect()`, matching how `motion_controller.js` checks
  `prefers-reduced-motion` once rather than subscribing to live changes — this session's
  primary pointer type isn't expected to change mid-visit for this audience, and Turbo's
  connect/disconnect cycle re-evaluates it on every navigation anyway.

---

## 4. Implementation Phases (Decomposition & Sequencing)

Ordered by risk and dependency, foundational/riskiest first — matches the product
agent's outline but re-grounded in this design's actual dependency chain:

**Increment 0 — Foundation (highest risk, must be hardened before anything else builds
on it)**
Mode state machine + global dispatch guard (Decisions 1–2) + status line, with the
*narrowest* possible payoff bound to it (`Esc`-to-NORMAL and `?` as a bare toggle are
enough to prove the wiring). This is the highest-risk increment because a bug here
doesn't break one feature — it can make text un-typeable *anywhere on the site*, on every
page, since the guard clause is the only thing standing between a keydown and every
form field that will ever exist. Must be manually verified against every existing page,
the theme-picker `<select>`, and the Turbo connect/disconnect lifecycle (§ Decision 2)
before anything else lands on top of it. The `docs/design/redesign-2026.md` §3 amendment
(§11) is a docs-only change that can land alongside or even ahead of this increment.

**Increment 1 — NORMAL-mode core navigation**
`h/j/k/l` + `j/k` scroll, `gg`/`G`, `g h/w/p/l` page jumps (via the shared
`resolveNavTarget` lookup, Decision 6). Low risk once Increment 0's dispatch is solid —
mostly scroll/navigation logic with no new mode transitions.

**Increment 2 — Theme cycle (`t`)**
Wires into the *existing* theme-picker controller/select (Decision 4). Small, isolated,
and reuses an already-correct persistence path — safe to land right after core nav.

**Increment 3 — COMMAND mode**
`:` + the command registry + a small v1 command set (navigate commands via the same
`resolveNavTarget` lookup; theme-set commands). First increment to exercise "enter a
non-NORMAL mode, move focus into a real input, Esc/Enter return" — keep the registry's
extension contract (name/handler/description shape) explicit and documented, since P1.9's
metrics-query commands plug into it later.

**Increment 4 — SEARCH mode**
`/` + the content-index endpoint/helper (Decision 3) + results list + `n`/`N`. Sequenced
after COMMAND because it reuses the same mode-transition/focus machinery COMMAND just
proved out, adding only the index-fetch concern on top. **Cross-issue dependency to
verify before starting**: `Post.excerpt`/`Post.kind` (design doc §5, Phase 1 item 4) —
confirm those fields have shipped, since the index's ranking depends on them.

**Increment 5 — `f` hint-jump**
The most DOM-invasive, highest-a11y-risk interactive piece (overlay positioning,
viewport/scroll handling, activation semantics) — sequenced last among the interactive
features precisely because it's the most isolated (only depends on Esc-to-NORMAL from
Increment 0) and benefits most from the dispatch/guard foundation being maximally proven
by the time it lands.

**Increment 6 — `?` guide overlay**
Documents everything shipped in Increments 1–5 — a reference surface, not a new
interaction primitive, so it naturally comes last. Uses the native `<dialog>` pattern
(Decision 7).

**Increment 7 — Testing-approach decision (cross-cutting; not a feature slice)**
Not this design's call to make unilaterally, but it must be made explicitly, not
defaulted into: see §10.

---

## 5. Dependencies and Integration Points

- **P1.1 theme system (merged, #1180)** — the theme-picker `<select>`/controller and the
  6-theme token set are read, not modified, by this design (Decision 4).
- **Design doc §5 content model additions (`Post.excerpt`, `Post.kind`)** — SEARCH's
  index (Decision 3) depends on these; verify shipped before Increment 4.
- **`/lab` and `/writing` routes (not yet built)** — handled via the self-resolving
  `resolveNavTarget` lookup (Decision 6), not a blocking dependency.
- **P1.9 (metrics query commands)** — feeds *into* the COMMAND registry built in
  Increment 3; this design's job is to leave that registry's extension contract obvious
  and documented, not to build P1.9's commands now.
- **No new subsystem, no new dependency edge** — see §9.

---

## 6. Risk Assessment

| Risk | Increment | Mitigation |
|---|---|---|
| Document-level listener swallows keys in an unrelated native form field, site-wide | 0 | Single generic editable-target guard (Decision 2, rule 2); manual cross-page check before anything else lands |
| Duplicate/leaked keydown listeners across Turbo navigations | 0 | Controller lifecycle tied to non-permanent `<body>`; explicit manual verification |
| Theme cycle (`t`) drifts out of sync with the dropdown over time | 2 | `t` reuses the existing `change` handler verbatim (Decision 4) — no parallel logic to drift |
| `/lab`/`/writing` targets hardcoded and later broken/stale | 1, 3 | `resolveNavTarget` reads already-correct, Rails-rendered anchors (Decision 6) |
| Hint-jump overlay traps focus or pollutes the accessibility tree | 5 | No focus/tabindex manipulation, `aria-hidden` badges, `.click()` on the real anchor (Decision 5) |
| Feature ships effectively untested against real key events (no JS/browser test infra exists today) | all | Pure-function extraction for unit-testability the moment a runner exists; explicit testing-approach decision required, not assumed (§10) |
| SEARCH index depends on content fields that haven't shipped | 4 | Explicit cross-issue dependency check before starting (§5) |

---

## 7. Success Criteria

Mirrors the issue's "Done when," made concrete per increment:

- Increment 0: `Esc` and `?`-toggle work on every page; no native field anywhere on the
  site loses a single keystroke; no duplicate listeners across Turbo navigation; full
  site functions with JS disabled.
- Increment 1–2: `hjkl`, `gg`/`G`, `g`-jumps, and `t` all work and match the header nav's
  actual (current) URLs with no hardcoded path strings.
- Increment 3–4: COMMAND and SEARCH both enter/exit cleanly, never trap focus, and
  restore focus correctly on exit; SEARCH returns correct, ranked results across the
  whole site, not just the current page.
- Increment 5: hint-jump labels every on-screen link, activates identically to a real
  click, and leaves zero trace (DOM, focus, tab order) after Esc/scroll-cancel.
- Increment 6: `?` documents every binding shipped so far.
- Cross-cutting: `prefers-reduced-motion` respected everywhere motion appears; touch
  devices show zero affordances and attach no listener; WCAG AA / screen-reader checks
  pass on the status line, COMMAND/SEARCH inputs, and the guide dialog.

---

## 8. Subsystem Impact

Per [`docs/architecture/overview.md`](../architecture/overview.md) and
[Universal Rule 8](../../adlc/methods/universal-agent-rules.md):

- **Affected subsystem**: `web-presentation` only. New Stimulus controller(s)
  (`keyboard_nav_controller.js` + a small set of plain-module helpers under
  `app/javascript/keyboard_nav/`), new/updated ERB partials (status line, COMMAND/SEARCH
  bars, `?` guide dialog), a `data-keyboard-nav-target="themeSelect"` attribute added to
  the existing header `<select>`, `data-nav-target="..."` attributes added to the
  existing header nav `<a>` tags, and a small server-side JSON serialization of
  `Post`/`Project` for the search index.
- **Boundary crossings**: SEARCH's index read is **web-presentation → content-domain**
  (`Post`, `Project`) — this edge already exists in the dependency graph
  (`WP --> CD`); this design adds a new *usage* of it (a search-index serializer), not a
  new edge.
- **New subsystems**: none proposed.
- **New dependency edges**: none required.
- Code, when it lands each increment, updates the Source File Catalog in
  `docs/architecture/overview.md` and `web-presentation.md`'s Anchor Files / Public
  Contract / State Owned sections (the new Stimulus identifiers and any new route/action
  belong there) — flagged here so it isn't missed, not performed by this design pass.

---

## 9. Recommended `docs/design/redesign-2026.md` §3 Amendment

The user approved amending §3 ("Signature interaction — the site as a terminal"); scribe
owns the actual doc edit as part of the spec phase. This section specifies *what* it
should say, not the prose itself:

1. **Reframe from "palette + single keys" to the modal model.** State explicitly that
   the site's keyboard layer is a NORMAL/COMMAND/SEARCH mode state machine (default
   NORMAL; `:` → COMMAND; `/` → SEARCH), not a flat set of global shortcuts — and that
   `t`, `g h/w/p/l`, `?`, `Esc` are all **NORMAL-mode bindings** under that machine, not
   free-floating shortcuts.
2. **Drop the `Cmd/Ctrl-K` framing.** The current bullet ("Command palette / console —
   `Cmd/Ctrl-K` (and `` ` ``/`:`) opens...") is superseded — the modal design
   intentionally uses bare `:` only, with no modifier chord, specifically so it never
   contends with browser/OS shortcuts. This is a correction, not just an addition.
3. **Add the mode indicator as an explicit, named UI element** (a visible terminal-style
   status line) — §3 doesn't mention one today.
4. **Add `f` hint-jump as its own bullet.** It's entirely absent from §3 currently; it's
   new scope introduced by the issue, not an elaboration of something already there.
5. **Keep "Queryable everything"** (§6.4/§6.5 tie-in) and **"Progressive enhancement +
   a11y"** largely as-is, but tighten the a11y bullet's wording to state the *outcome*
   (never intercepts keys in form fields; `Esc` always available; respects
   `prefers-reduced-motion`; full site works with the layer absent) — keep the *how*
   (capture strategy, guard clauses, index format) out of the design doc; that belongs in
   the spec, consistent with how §3 already treats implementation detail today.
6. **Cross-reference forward** to the spec once scribe creates it (`docs/specs/1187-
   ....md`), matching the existing convention where §3's D1/D2 references point at the
   #1180 spec.

---

## 10. Open Decision Flagged for the Orchestrator/Test Agent (not settled here)

This repo has **zero JS unit-test and zero browser/system-test infrastructure** today
(`web-presentation.md`'s "Known Limitations": *"No system tests / Capybara; coverage is
request + model specs"*). A document-level key dispatcher touching every page and every
form field is exactly the kind of logic that's risky to ship unverified by real
interaction — yet nothing in this repo exercises a real keydown event today, and
`lib/contrast_spec.rb` shows the one precedent for testing frontend concerns here is a
pure-Ruby check over token values, not a browser.

This design deliberately keeps the pure logic (sequence parsing, hint-label generation,
search ranking, `resolveNavTarget`, "next theme") in small plain-function modules
specifically so they're unit-testable the moment a runner exists — but **whether to
introduce one (e.g. Vitest, which pairs easily with the existing webpack/ESM setup) is a
call for the test agent/orchestrator to make explicitly before or alongside Increment 0**,
not something this design assumes away. Absent that decision, verification falls back to
manual QA plus RSpec view/request specs asserting the right markup/ARIA scaffolding is
server-rendered (data-nav-target attributes present, status line/dialog markup present,
labels correct) — which is useful but does not exercise a single real keystroke.

---

## 11. Handoff

- **To scribe**: write the spec from Decisions 1–8 above plus the §3 amendment (§9).
  Pin exact file names, CSS/z-index values, the command registry's precise shape, and the
  hint-label alphabet — all left open here as spec-level detail.
- **To orchestrator/test**: resolve §10 (testing-approach decision) before or alongside
  Increment 0.
- **To code**: build in the increment order in §4; do not start Increment N+1 before
  Increment N is reviewed, given Increment 0's site-wide blast radius if wrong.
