<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1180 -->
<!-- Last Updated: 2026-07-18T00:00:00+02:00 -->
<!-- Description Hash: 5fad786a9669 -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# P1.1 — Design System Pass (Refined-Terminal Visual Foundation)

**Issue:** [bitidev/jamesebentier.com#1180](https://github.com/bitidev/jamesebentier.com/issues/1180)
**Parent epic:** [#1179 — 2026 Site Redesign, Phase 1](https://github.com/bitidev/jamesebentier.com/issues/1179)
**Branch:** `personal/jebentier/issue-1180-p11-design-system-pass-refined-terminal-visual`
**Board:** org `bitidev` project — Status: In Progress; Assignee: `jebentier`
**Design:** [`docs/design/redesign-2026.md`](../design/redesign-2026.md) §3 (Visual direction), §8 (Open questions), §9 (Decision log)
**Blocks:** P1.2 (Hero + home redesign), P1.3 (Projects page redesign), P1.4 (Writing redesign), P1.8 (SEO/meta polish)

## Overview

This is the foundational visual-language issue for the 2026 redesign. It has no product
feature of its own — it establishes the Tailwind 4 `@theme` tokens (palette, type scale,
font families), the DaisyUI 5 theme set (light, dark, plus a curated set of developer color
schemes), four shared ERB partials (section wrapper, card, tag/status pill, CTA button), a
theme-picker Stimulus controller with persisted choice, and a restrained motion controller —
so that every later Phase-1 page (P1.2–P1.4, P1.8) builds against one documented token +
component API instead of re-inventing markup per page, the way `app/views/projects/index.html.erb`
and `app/views/blog/index.html.erb` currently do independently of each other.

Per the design doc, two details were explicitly left open at §8 for this issue to resolve:
the final bundled developer-theme list, and the body-sans pairing for Commit Mono. Both are
resolved as explicit decisions in [Design Decisions](#design-decisions-resolving-8) below,
and both changes are mirrored back into `docs/design/redesign-2026.md` (§3, §8, §9) as part
of this issue's deliverable, per the issue's own "Done when."

## Goal

A developer implementing P1.2–P1.4 can open this spec (or the updated design doc) and know,
without guessing: which `@theme` tokens exist and what they resolve to; which of the four
shared partials to render and with which locals; how to add a page to the fade/slide/hover-lift
motion system; and that the theme picker "just works" (switches, persists, no flash of the
wrong theme on reload) without them touching its internals. One existing page is fully
migrated to prove the API holds up against real content, not just a style-guide page.

## In Scope

- `app/assets/stylesheets/application.tailwind.css`: `@theme` tokens for the type scale (base
  18px / Major Third 1.250), font families (Commit Mono + the chosen body sans), and the
  palette structure needed to express "near-black canvas, soft off-white text, one amber
  signature accent" per §3.
- Self-hosted webfont files (Commit Mono + the chosen body sans) and their `@font-face`
  declarations — no third-party font CDN request, consistent with the site's existing
  drift away from third-party trackers (§6.5).
- DaisyUI 5 theme configuration (`@plugin "daisyui" { themes: … }` in
  `application.tailwind.css`) for `light` (default), `dark`, and the curated developer-scheme
  set decided in [Design Decisions](#design-decisions-resolving-8).
- Four new shared ERB partials under `app/views/components/`: section wrapper, card,
  tag/status pill, CTA button — each with a documented locals/block contract (see
  [Component API](#component-api)).
- A `theme-picker` Stimulus controller (switch + persist via `localStorage`) plus the small
  render-blocking inline script needed to avoid a flash-of-wrong-theme on load (see
  [R6](#r6--theme-picker-controller--no-flash-of-wrong-theme)).
- A `motion` Stimulus controller (scroll-triggered fade/slide-in) plus CSS hover-lift
  utilities, both honoring `prefers-reduced-motion`.
- Migrating `app/views/projects/index.html.erb` to the new components as the required
  "at least one existing page" proof (chosen because it is the only current page that
  naturally exercises all four components — see [R9](#r9--migrate-appviewsprojectsindexhtmlerb-as-proof)).
- A narrow, token-only pass over `app/views/welcome/index.html.erb`'s hero to retire the
  multi-color accent scheme (green/purple/orange/pink/yellow/fuchsia) in favor of the
  disciplined base + single amber accent, per §3's own "Palette" bullet — copy and layout
  are untouched (that is P1.2's job).
- Updating `docs/design/redesign-2026.md` (§3, §8, §9) and
  `docs/architecture/sub-systems/web-presentation.md` (Public Contract, Key Invariants,
  Anchor Files) to reflect the new tokens/components/controllers, per the scribe's
  architecture-doc ownership rule.
- Fixing the amber-on-light-background contrast defect discovered in
  [Current State](#current-state-verified) as part of defining the amber token (see
  [R2](#r2--palette-tokens-and-the-amber-contrast-fix)).

## Out of Scope

- **New copy, layout, or IA for any page.** P1.2 (hero positioning copy, featured
  projects, latest writing), P1.3 (projects grid, triple-link cards, filters), P1.4
  (Notes/Deep Dives split, article typography) are separate, already-filed issues and must
  not be pulled forward here. This issue only swaps markup/classes on
  `projects/index.html.erb` and the hero's color utilities — no new fields, no new sections,
  no new content.
- **`Project`'s triple-link fields (read/demo/source)** — explicitly P1.3's job per the
  design doc's roadmap (§7, item 3). The migrated `projects/index.html.erb` keeps today's
  single `project.url` link, just restyled as the new CTA button.
- **The keyboard command layer / command palette** (`Cmd/Ctrl-K`, single-key shortcuts,
  `?` guide overlay) — §3's "Signature interaction" section and roadmap item 10, a distinct,
  larger issue that depends on this one but is not part of it. The theme picker built here
  is a standalone terminal-styled widget; wiring a `t` keyboard shortcut to it is that
  issue's job.
- **Header/footer content or layout redesign.** The header partial is touched only to add
  the theme-picker trigger element and to replace its hardcoded `#fab73a` hex literals with
  the new token (both directly required by work in this issue); nav structure, logo
  treatment, and footer link/social layout are unchanged.
- **Adding Capybara/system-test infrastructure.** This repo has no JS-capable test driver
  today (`spec/` has only `factories/helpers/lib/models/requests/support` — see
  [Current State](#current-state-verified)). Adding one is a real, separate decision (choice
  of driver, CI runtime cost) and is not bundled into a design-system issue. JS-behavioral
  acceptance (theme persistence across reload, reduced-motion honored) is verified manually
  in-browser per [Acceptance Criteria](#acceptance-criteria), not via new automated system
  specs.
- **First-party analytics, GA/Metricool removal** — §6.5, a separate issue (roadmap item 11).
- **Any OIDC/identity work** — Phase 2 entirely.
- **Visitor-facing terminal metrics queries** — depends on both the command layer and
  analytics issues, neither of which exist yet.

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch
`jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC
contribution.

## Current State (Verified)

Verified directly against the repo (`main` @ `dc7c863`) as of 2026-07-18:

### Build toolchain
- Tailwind **4.3.3** + DaisyUI **5.6.18** + `@tailwindcss/typography` **0.5.20**, driven by
  `cssbundling-rails`/`jsbundling-rails` (not Propshaft/importmap) — `yarn build:css` runs
  `tailwindcss -i app/assets/stylesheets/application.tailwind.css -o app/assets/builds/application.css`.
  `Procfile.dev` runs `css`/`js`/`web` watchers in parallel.
- `app/assets/stylesheets/application.tailwind.css` today is 38 lines: `@plugin "daisyui" {
  themes: light --default, dark; }` (DaisyUI's stock `light`/`dark` definitions, unmodified),
  one `@theme` block defining only `--font-sans-serif: Montserrat, sans-serif` and
  `--font-resume` (the print/resume typeface stack), plus `.prose img` layout rules for blog
  post images.
- **`--font-sans-serif: Montserrat` is never actually loaded** — no `<link>` to Google Fonts,
  no self-hosted `@font-face`, nowhere in `app/views/layouts/application.html.erb` or
  anywhere else in the repo. It silently falls back to the browser's default sans-serif.
  This is exactly the latent gap §3's "(Montserrat, or revisit)" parenthetical is flagging,
  and it's why this spec revisits it rather than just wiring up Montserrat as-is (see
  [D2](#d2--body-sans-pairing-inter-not-montserrat)).
- No `app/assets/fonts/` or equivalent directory exists; no font is self-hosted anywhere in
  the app today.
- DaisyUI 5's CSS-first custom-theme syntax (confirmed by reading the installed package at
  `node_modules/daisyui/themes.css`, v5.6.18, matching this repo's `package.json` pin) uses
  `@plugin "daisyui/theme" { name: "…"; color-scheme: dark; --color-base-100: …; --color-primary:
  …; --color-primary-content: …; … }` with the semantic role set: `base-100/200/300(+content)`,
  `primary/secondary/accent/neutral(+content)`, `info/success/warning/error(+content)`,
  `--radius-selector/-field/-box`, `--size-selector/-field`, `--border`, `--depth`, `--noise`.
  **`dracula` and `nord` are built into DaisyUI 5.6.18 out of the box** (confirmed by grepping
  `data-theme=` selectors in `node_modules/daisyui/themes.css`); `gruvbox`, `catppuccin`,
  `solarized`, and `tokyonight` are **not** — those require full custom `@plugin
  "daisyui/theme"` blocks.

### Layout / theme wiring today
- `app/views/layouts/application.html.erb:2` hardcodes `<html data-theme='light'>` — there is
  no mechanism today to switch themes at all; this issue introduces the first one.
- Content is wrapped in `<div class="max-w-screen-lg m-auto font-sans-serif">` — the
  `font-sans-serif` class currently resolves to the unloaded Montserrat fallback above.

### The amber accent's existing (broken) usage
- `app/views/layouts/components/_header.html.erb` hardcodes `text-[#fab73a]` as the "current
  page" nav-link color, on **top of a page that defaults to the `light` theme** (near-white
  `base-100`). `#fab73a` (`rgb(250,183,58)`) against white has a contrast ratio of **~1.8:1**
  — this fails WCAG AA for text (needs 4.5:1) by a wide margin. This is a real, currently-shipping
  accessibility defect, not a hypothetical one; it is why this spec defines two amber tokens
  rather than one literal hex (see [R2](#r2--palette-tokens-and-the-amber-contrast-fix)).
  Against the new dark canvas, `#fab73a` contrasts at **~10:1** — excellent, no change needed
  there.

### Existing "component-shaped" markup this issue's partials replace
- `projects/index.html.erb` and `blog/index.html.erb` each hand-roll an almost-identical card
  row (`flex flex-row … border … rounded bg-white shadow … text-black`, hardcoded to a light
  background regardless of active theme) — independently, with copy-pasted structure and no
  shared partial. `projects/index.html.erb` prints `Status: <%= project.status %>` as plain
  text (`Project#status` is a validated enum: `Pre-Launch`, `Beta`, `Live`, default `Beta` —
  `app/models/project.rb`) — exactly the data the tag/status pill component is for.
- `welcome/index.html.erb` (12 lines) is the multi-color hero §3 names for retirement:
  `text-green-500`, `text-purple-500`, `text-orange-500`, `text-pink-500`, `text-yellow-600`,
  `text-fuchsia-500` on six different `<strong>` spans.
- No `app/views/components/` (or `shared/`) directory exists yet. The only existing "shared
  partial" precedent is `app/views/layouts/components/_header.html.erb` /
  `_footer.html.erb` (layout-scoped, not general-purpose).
- No ViewComponent/Phlex/Cells gem is installed — `app/views/components/` partials are plain
  ERB, called via `render`.

### Stimulus / JS today
- `app/javascript/controllers/`: `application.js` (bootstraps `Application.start()`,
  `debug = false`), `index.js` (manifest, auto-generated by
  `bin/rails stimulus:manifest:update`), `collapse_controller.js` (`data-controller="collapse"`,
  toggle a `hidden` class + swap a Font Awesome caret icon — used on the resume page),
  `hello_controller.js` (unused Stimulus scaffold, already flagged as a known limitation in
  `docs/architecture/sub-systems/web-presentation.md`). No motion/animation controller and no
  theme controller exist today.

### Test infrastructure
- `spec/` has `factories/`, `helpers/`, `lib/`, `models/`, `requests/`, `support/` — RSpec +
  `rspec-rails` only. **No Capybara, no Selenium/Cuprite/Playwright gem in `Gemfile`, no
  `spec/system/`.** JS-driven behavior (theme persistence, reduced-motion handling) cannot be
  asserted by an automated spec in this repo today without adding new test infrastructure,
  which is out of scope here (see [Out of Scope](#out-of-scope)).

### Architecture doc currently on record
- `docs/architecture/sub-systems/web-presentation.md` already lists as a **Key Invariant**:
  "Layout uses DaisyUI `data-theme='light'` and a centered `max-w-screen-lg` content column."
  This issue directly changes that invariant (theme becomes dynamic + persisted) — the doc
  must be updated in the same PR per [R11](#r11--update-web-presentation-architecture-doc).

## Design Decisions (Resolving §8)

The design doc's §8 leaves two details open for this issue; both are resolved here and
mirrored into `docs/design/redesign-2026.md` §3/§8/§9 by [R12](#r12--update-the-design-doc).

### D1 — Curated developer-theme set: Dracula, Nord, Gruvbox (Dark), Catppuccin (Mocha)

Candidates named in the issue: Dracula, Solarized, Gruvbox, Nord, Tokyo Night, Catppuccin.
**Decision: ship four, not six** — "curated," not exhaustive, per the issue's own wording
("a curated set of developer schemes"). Full picker list: **Light, Dark, Dracula, Nord,
Gruvbox, Catppuccin** (6 entries total).

Rationale:
- **Dracula** — arguably the single most cross-editor-recognized dark scheme in developer
  culture; ships free in DaisyUI 5 (no custom palette work); high, unambiguous contrast.
- **Nord** — extremely popular, and visually distinct from Dracula (cool arctic
  blues/greens vs. purple/pink) rather than redundant with it; also ships free in DaisyUI 5.
- **Gruvbox (Dark variant only)** — a *warm*-toned retro palette, popular in the vim/terminal
  community, and a genuine thematic complement to the rest of the redesign: §3's own framing
  is "refined terminal, **warmed up**," and Gruvbox is literally a warm scheme — it's the one
  candidate that reinforces the site's own stated aesthetic thesis rather than just being
  popular. (Only the dark variant ships; Gruvbox Light is not part of this issue's picker —
  the site already has a `light` theme for that mode.)
- **Catppuccin (Mocha variant only)** — the newest and currently most-adopted scheme in the
  terminal/editor theming ecosystem (2023–2026), softer/pastel character that gives the
  picker a fourth, genuinely distinct visual register (cool-pastel vs. Dracula's
  purple-neon, Nord's arctic-cool, Gruvbox's warm-retro).

Explicitly **not** bundled, with rationale (revisit later if there's demand — this is a
"handful," not a ceiling):
- **Solarized** — its signature move is a deliberately low-contrast, desaturated base
  (`base03`/`base3`) that is idiosyncratic to theme cleanly against DaisyUI's semantic roles
  without either diluting its own identity or clashing with the site's own amber signature
  accent; it also ships in two variants (Dark/Light) that would need separate palette work
  for one slot.
- **Tokyo Night** — popular, but sits in the same cool blue/purple register as Dracula and
  Nord; adding it would add a fourth theme in that same color family rather than a fourth
  *distinct* one, which is what "curated" is meant to avoid.

Every custom (non-built-in) theme — Gruvbox, Catppuccin — must meet **WCAG AA (4.5:1)**
`base-content`-on-`base-100` and `primary-content`-on-`primary` contrast before merge; this
is a hard acceptance-criteria gate ([Acceptance Criteria](#acceptance-criteria)), not
optional polish, precisely because the palette bug found in
[Current State](#current-state-verified) shows this project doesn't yet have a habit of
checking it.

### D2 — Body-sans pairing: Inter, not Montserrat

**Decision: the body sans is Inter** (self-hosted, OFL-1.1 licensed, via
`@fontsource-variable/inter` or an equivalent vendored variable woff2 — see
[R3](#r3--self-hosted-webfonts)), replacing the never-actually-loaded Montserrat reference.

Rationale:
- §3 itself hedges — "(Montserrat, or revisit)" — flagging this as unsettled, and
  [Current State](#current-state-verified) confirms Montserrat was never wired up at all
  (dead CSS variable, no `@font-face`, no font request). There's no working baseline to
  preserve by keeping it.
- Montserrat is a **geometric** sans (display/branding-oriented letterforms) — a reasonable
  pick for a wordmark or short headline, but §3's stated goal for the body sans is
  specifically **long-form reading comfort** ("so Deep Dives stay comfortable" — 1,000+ word
  articles per §5's Deep Dive definition). Geometric sans faces are generally judged less
  comfortable than **humanist/grotesk** faces for extended body text at typical screen sizes.
- **Inter** is purpose-built for UI and on-screen reading comfort (extensive x-height tuning,
  hinting, and a variable-weight axis), is free/OFL-1.1 (self-hostable, no licensing
  friction, no third-party font request — consistent with the site's move away from
  third-party requests generally, §6.5), and is one of the most road-tested pairings
  alongside monospace/technical display faces — directly matching commitmono.com's own
  reference aesthetic, which §3 names as "a direct design touchstone."
- Headings/nav/metadata/labels/code stay Commit Mono exactly as §3 already specifies — D2
  only resolves the *body* half of the pairing.

## Component API

Four partials under `app/views/components/` (new directory — no ViewComponent/Phlex gem is
installed, so these are plain ERB, consistent with how `layouts/components/_header.html.erb`
/ `_footer.html.erb` already work). Two are simple locals-only partials; two take block
content via Rails' `render(layout: …) { … }` idiom (a partial rendered as a "layout" calls
`yield` where the block goes — the standard vanilla-ERB way to give a partial a content slot
without a component gem).

| Partial | Call shape | Locals | Block? |
|---|---|---|---|
| `components/_section.html.erb` | `render layout: "components/section", locals: { eyebrow: nil, title: nil }` | `eyebrow:` (optional, small Commit Mono label above title), `title:` (optional heading) | Yes — section body |
| `components/_card.html.erb` | `render layout: "components/card", locals: { href:, image_url: nil }` | `href:` (required, wraps card in a link), `image_url:` (optional) | Yes — card body (title/meta/description/pill markup composed by the caller) |
| `components/_pill.html.erb` | `render "components/pill", label:, variant: :tag` | `label:` (required, string), `variant:` (`:status` or `:tag`, default `:tag`) | No |
| `components/_cta_button.html.erb` | `render "components/cta_button", label:, href:, style: :primary` | `label:`, `href:`, `style:` (`:primary` default, `:ghost` secondary) | No (text-only label; block-content variant is not needed by this issue's proof page and is left for a future amendment if a page needs it) |

Pill `variant: :status` maps `Project#status` to a DaisyUI badge role — this mapping is the
contract later pages (P1.3) build against:

| `status` value | Badge role |
|---|---|
| `Pre-Launch` | `badge-warning` |
| `Beta` | `badge-info` |
| `Live` | `badge-success` |

`variant: :tag` (used for free-form `Post#tags` entries, exercised by P1.4, not this issue)
renders a neutral/outline badge — no status semantics implied.

CTA button `style: :primary` renders on the DaisyUI `primary` role (which resolves to amber
in `light`/`dark`, per [R2](#r2--palette-tokens-and-the-amber-contrast-fix), and to each
developer scheme's own primary color when one of those is active) — **never** a hardcoded
hex — so the button re-themes correctly across all six bundled themes without any per-theme
special-casing in the partial itself.

## Requirements

### R1 — Type scale `@theme` tokens (18px base, Major Third 1.250)

`application.tailwind.css`'s `@theme` block overrides Tailwind's built-in `--text-*` scale
(rather than changing the root `<html>` font-size) so existing/future `text-base`,
`text-lg`, `text-xl`, `text-2xl`, `text-3xl`, `text-4xl` utility classes automatically carry
the new scale project-wide, and so the page respects the user's browser zoom/font-size
setting (rem-relative to the unmodified 16px browser default) rather than fighting it:

| Token | px (per §3) | rem (÷16) | Suggested line-height |
|---|---|---|---|
| `--text-base` | 18 | `1.125rem` | `1.65` (body copy — generous, for Deep Dive reading comfort) |
| `--text-lg` | 23 | `1.4375rem` | `1.4` |
| `--text-xl` | 28 | `1.75rem` | `1.3` |
| `--text-2xl` | 35 | `2.1875rem` | `1.2` |
| `--text-3xl` | 44 | `2.75rem` | `1.15` |
| `--text-4xl` | 55 | `3.4375rem` | `1.1` |

Each `--text-*` token is paired with its Tailwind-4-expected `--text-*--line-height`
companion token using the values above. Line-heights are starting values (documented,
adjustable during visual QA) — the rem values themselves are not (they are the literal
Major-Third-1.250-off-18px sequence §3 specifies and must match exactly).

### R2 — Palette tokens, and the amber contrast fix

Two amber tokens, not one literal hex, to fix the defect in
[Current State](#current-state-verified) while keeping `#fab73a` exactly where it already
reads correctly:

- `--color-primary` (dark theme, and used as button backgrounds in light theme) =
  **`#fab73a`** unchanged — verified ~10:1 against the new near-black canvas.
- A second, deepened amber (e.g. `#8a5a10`, ~5.9:1 against white — same hue family, lower
  lightness) is used anywhere amber renders as **text on the light theme's near-white
  canvas** (e.g. `primary` role text/links in the `light` theme). The exact final shade is
  an implementer/visual-QA call as long as it (a) reads recognizably as the same amber hue
  family and (b) meets the 4.5:1 gate below — this spec fixes the *requirement*, not the
  pixel-exact hex.
- `primary-content` (the color used for text/icons drawn *on top of* a solid `primary`
  background, e.g. the CTA button's label) is a **dark/near-black** color, not white, in
  every theme where `primary` resolves to amber — white-on-amber contrasts at ~1.8:1 and
  must not be used. This is the same underlying defect as the header nav-link issue, just in
  the inverse (background vs. text) position.
- Dark theme base tokens follow §3's "near-black canvas, soft off-white text": `base-100`
  is a near-black, not pure `#000` (matching the restrained-not-harsh direction of the
  philipwalton.com/taniarascia.com references in §3), with `base-200`/`base-300` as
  progressively lighter elevation steps for cards/raised surfaces; `base-content` is a
  warm-neutral off-white (not pure `#fff`, consistent with "warmed up"), contrasting ≥7:1
  against `base-100`.
- Hard gate, all six bundled themes: `base-content`-on-`base-100` and
  `primary-content`-on-`primary` both meet **WCAG AA (4.5:1)** minimum. This is checked as
  part of [Acceptance Criteria](#acceptance-criteria), not left to a future pass.
- `light` theme keeps DaisyUI's stock `base-*`/`neutral`/`info`/`success`/`warning`/`error`
  roles (§3: "keep the existing light theme for the print/resume path") — only `primary`/
  `accent` are repointed to the amber pair above, so the CTA button and links read
  consistently branded in both `light` and `dark`.

### R3 — Self-hosted webfonts

Commit Mono (headings/nav/metadata/labels/code — already decided in §3) and Inter (body —
[D2](#d2--body-sans-pairing-inter-not-montserrat)) are both self-hosted, not loaded from a
third-party CDN/Google Fonts request:

- New `app/assets/fonts/` directory (or equivalent under `app/assets/`), holding woff2 files
  for both faces, `@font-face`-declared in `application.tailwind.css` with `font-display:
  swap`.
- Commit Mono: vendor the OFL-licensed static/variable woff2 release from the font's
  upstream distribution (commitmono.com / its GitHub releases) — not available via a
  Fontsource-style npm package at time of writing, so this is a manual vendor step, not a
  `yarn add`.
- Inter: `@fontsource-variable/inter` (or equivalent) added as a yarn dependency, or manually
  vendored the same way as Commit Mono — either satisfies this requirement; picking the
  npm-package route is simpler to keep updated and is the suggested default.
- `--font-mono` / a new mono token resolves to `"Commit Mono", ui-monospace, ... ` (system-mono
  fallback stack); the existing `--font-sans-serif` token is repointed from `Montserrat` to
  `"Inter", ui-sans-serif, ...` (rename to `--font-sans` is acceptable and arguably clearer,
  but is a call for the implementer — either name is fine as long as it's documented).
- `--font-resume` is untouched (print/resume path is explicitly out of the "refined terminal"
  redesign per §3).

### R4 — DaisyUI theme configuration

`application.tailwind.css`'s `@plugin "daisyui" { themes: … }` line lists, in order:
`light --default, dark, dracula, nord, gruvbox, catppuccin`.

- `dracula` and `nord`: DaisyUI 5.6.18 ships both out of the box (confirmed in
  [Current State](#current-state-verified)) — listing the name is sufficient; using their
  stock definitions unmodified is acceptable (their own iconic colors are the point of
  including them — do **not** repoint their `primary`/`accent` to the site's amber, which
  would defeat the "personality moment" §3 describes).
- `gruvbox` and `catppuccin`: not built in — each needs a full custom `@plugin
  "daisyui/theme" { name: "…"; color-scheme: dark; --color-base-100: …; … }` block. Starting
  palettes (sourced from each scheme's official published colors; adjustable during
  implementation as long as the R2-style 4.5:1 gate passes):

  **Gruvbox (Dark, "hard" contrast variant):** `base-100 #282828`, `base-200 #3c3836`,
  `base-300 #504945`, `base-content #ebdbb2`, `primary #fabd2f` (bright yellow — nicely
  reinforces the "warmed up" narrative per [D1](#d1--curated-developer-theme-set-dracula-nord-gruvbox-dark-catppuccin-mocha)),
  `secondary #83a598` (bright blue), `accent #fe8019` (bright orange), `neutral #504945`,
  `info #83a598`, `success #b8bb26`, `warning #fabd2f`, `error #fb4934`.

  **Catppuccin (Mocha):** `base-100 #1e1e2e`, `base-200 #181825` (mantle), `base-300
  #11111b` (crust), `base-content #cdd6f4`, `primary #cba6f7` (mauve), `secondary #89b4fa`
  (blue), `accent #fab387` (peach), `neutral #313244` (surface0), `info #89dceb` (sky),
  `success #a6e3a1`, `warning #f9e2af`, `error #f38ba8`.

- All six themes share the same `--radius-box`/`--radius-field`/`--radius-selector` values
  (visual consistency of card/button rounding across theme switches is more important than
  per-theme radius fidelity) — pick one rounded-but-restrained value consistent with §3's
  "Rounded cards, comfortable spacing" and apply it uniformly.

### R5 — Shared component partials

Implement the four partials in [Component API](#component-api) exactly to that contract
(partial path, locals, block-or-not, pill variant→badge-role mapping). This table is the
API surface P1.2/P1.3/P1.4/P1.8 build against — changing it later is a breaking change to
those issues' assumptions, not a free amendment.

### R6 — Theme-picker controller + no flash-of-wrong-theme

- A Stimulus `theme-picker` controller (`app/javascript/controllers/theme_picker_controller.js`)
  renders/drives a small terminal-styled control (§3: "the switcher itself should feel like a
  tiny terminal") listing all six themes from R4. On selection, it sets
  `document.documentElement.dataset.theme = value` and writes the value to
  `localStorage` under a single documented key (e.g. `theme`).
- **`localStorage`, not a cookie** — this is a purely client-side UI preference with no
  server-side rendering dependency (Rails never needs to know the active theme), so a cookie
  round-trip adds nothing; it also sidesteps the cookie-consent question the design doc is
  already tightening elsewhere (§6.5's cookieless-analytics push, §8's GDPR/TTDSG note) —
  strictly-necessary local UI-preference storage doesn't carry the same consent-banner
  question a cookie would.
- **Flash-of-wrong-theme fix**: because `application.html.erb:2` currently hardcodes
  `data-theme='light'` server-side and the Stimulus controller only runs after Turbo/JS
  boot, a returning visitor with a stored dark/dev-scheme preference would see a flash of
  the wrong theme on every full page load. Fix: a tiny, synchronous, render-blocking
  `<script>` (no `type="module"`, no `defer`/`async`) placed in `<head>` **before** the
  stylesheet link, that reads `localStorage` and sets `document.documentElement.dataset.theme`
  immediately, before first paint. This script is separate from (and runs before) the
  Stimulus-loaded `application.js` bundle. The `theme-picker` controller, on `connect()`,
  only needs to read the already-applied value to set its own UI's selected state — it does
  not need to be the thing that prevents the flash.
- Falls back to `light` (today's default) when no stored value exists, matching current
  behavior for first-time visitors.

### R7 — Motion controller

- A Stimulus `motion` controller (`app/javascript/controllers/motion_controller.js`) drives
  scroll-triggered fade/slide-in via `IntersectionObserver`: elements marked
  `data-controller="motion"` start hidden/offset and transition to visible when they enter
  the viewport.
- On `connect()`, the controller checks
  `window.matchMedia('(prefers-reduced-motion: reduce)').matches` — when true, it skips the
  observer entirely and the element renders in its final (visible, non-offset) state
  immediately, no delayed appearance.
- Hover-lift (card hover) is implemented as **CSS only** (Tailwind `transition` +
  `hover:-translate-y-*` utilities), not JS — simpler and more robust than gating hover via
  the Stimulus controller — but is itself wrapped in a
  `@media (prefers-reduced-motion: no-preference)` block so it's inert when the user has
  requested reduced motion, matching the JS controller's behavior for the scroll case.

### R8 — Amber token cleanup in the header

`app/views/layouts/components/_header.html.erb`'s three hardcoded `text-[#fab73a]` literals
are replaced with a reference to the new `primary` token (e.g. `text-primary`), both because
leaving them hardcoded alongside a brand-new token system is inconsistent, and because it is
the direct fix for the contrast defect in [Current State](#current-state-verified) (the
token resolves to the light-theme-safe deepened amber from R2 when `light` is active, and to
`#fab73a` unchanged when `dark`/a dev scheme is active). No other header markup changes.

### R9 — Migrate `app/views/projects/index.html.erb` as proof

Chosen over `blog/index.html.erb` or `welcome/index.html.erb` alone because it is the one
page that naturally exercises all four components in [Component API](#component-api) at
once: wrap the listing in the `section` partial; render each `Project` via the `card`
partial (`href: project_url(slug: project.slug)`, `image_url: project.image`); render
`Project#status` via the `pill` partial (`variant: :status`); replace the current
whole-card-as-link with an explicit `cta_button` partial inside each card
(`style: :primary`, `href:` the same `project_url`, label e.g. "View Project") linking to
the existing project-show page — **no** triple-link UI (that's P1.3, see
[Out of Scope](#out-of-scope)). Copy (project titles/descriptions) and the underlying
`Project` model are untouched.

### R10 — Hero palette-only pass on `welcome/index.html.erb`

Replace the six hardcoded rainbow `text-{color}-{shade}` utilities with the new palette (the
single amber `primary` token for the one emphasis that should carry visual weight, default
`base-content` for the rest) per §3's "retire the multi-color accent hero … plus one
signature accent: amber." No copy changes, no layout changes, no new sections — this is a
token swap only, explicitly not a hero redesign (P1.2 owns that).

### R11 — Update web-presentation architecture doc

`docs/architecture/sub-systems/web-presentation.md`:
- **Public Contract**: add the two new Stimulus controllers (`data-controller="theme-picker"`,
  `data-controller="motion"`) and the four new component-partial exports
  (`components/section`, `components/card`, `components/pill`, `components/cta_button`).
- **Key Invariants**: replace "Layout uses DaisyUI `data-theme='light'` … " with the new
  invariant — theme is client-driven (inline FOUC-prevention script + `theme-picker`
  controller + `localStorage`), defaulting to `light` for first-time visitors; content
  column (`max-w-screen-lg`) invariant is unchanged.
- **Anchor Files**: add `app/assets/stylesheets/application.tailwind.css` (theme/token
  source of truth) and `app/views/components/` to the anchor list.
- No new subsystem, no dependency-graph change, no `overview.md` one-line purpose change —
  only the file-catalog entries under "web-presentation" gain the new files.

### R12 — Update the design doc

`docs/design/redesign-2026.md`:
- §3: replace "(Montserrat, or revisit)" with "Inter" and record the rationale pointer to
  this spec's [D2](#d2--body-sans-pairing-inter-not-montserrat).
- §3: replace the parenthetical dev-scheme candidate list with the resolved set — Dracula,
  Nord, Gruvbox, Catppuccin — and a one-line pointer to [D1](#d1--curated-developer-theme-set-dracula-nord-gruvbox-dark-catppuccin-mocha)
  for the excluded-candidates rationale.
- §8: remove the two now-resolved open-question bullets ("Terminal theme picker — final list
  of bundled themes" and the body-sans half of the typography bullet, if separately tracked).
- §9 (Decision log): add two rows — "Bundled dev themes" → "Dracula, Nord, Gruvbox,
  Catppuccin" and "Body sans" → "Inter" — each dated 2026-07-18, matching the log's existing
  format.

## Approach (Implementation Guidance)

This section is spec-level guidance for the **code** agent — not a substitute for verifying
current Tailwind 4 / DaisyUI 5 CSS-first theming syntax against the installed package
(`node_modules/daisyui`, confirmed v5.6.18 in this repo) at implementation time.

1. Confirm working in the issue worktree (branch
   `personal/jebentier/issue-1180-p11-design-system-pass-refined-terminal-visual`), branched
   from current `main`.
2. Vendor Commit Mono webfont files (R3) into `app/assets/fonts/commit-mono/`; add
   `@fontsource-variable/inter` via `yarn add` (or vendor Inter the same manual way) for R3's
   body sans. Declare both via `@font-face` (or the fontsource package's own CSS import) in
   `application.tailwind.css`.
3. Rewrite `application.tailwind.css`'s `@theme` block per R1 (type scale) and R3 (font
   family tokens); add the `@plugin "daisyui" { themes: … }` line and the two custom
   `@plugin "daisyui/theme"` blocks per R4.
4. Add the small render-blocking inline `<script>` to `app/views/layouts/application.html.erb`'s
   `<head>` per R6, ahead of the `stylesheet_link_tag`; change the hardcoded
   `<html data-theme='light'>` to a bare `<html>` (the inline script now owns setting the
   attribute) or leave `light` as a static fallback the script overwrites — either is fine as
   long as first paint never shows a mismatched theme for a returning visitor with a stored
   preference.
5. Scaffold `theme_picker_controller.js` and `motion_controller.js` per R6/R7 (`bin/rails
   generate stimulus theme_picker` / `motion` to get manifest registration right, matching
   the existing `collapse`/`hello` pattern in `app/javascript/controllers/index.js`).
6. Build the four `app/views/components/_*.html.erb` partials per
   [Component API](#component-api) and R5.
7. Add the theme-picker's markup (trigger element + option list) somewhere in
   `layouts/components/_header.html.erb`; apply R8's token cleanup in the same file.
8. Migrate `projects/index.html.erb` per R9; apply the hero token-only pass to
   `welcome/index.html.erb` per R10.
9. Update `docs/architecture/sub-systems/web-presentation.md` (R11) and
   `docs/design/redesign-2026.md` (R12).
10. Verify: `yarn build:css` compiles without error; `bundle exec rubocop` and `bundle exec
    rspec` (existing `ci-gate`) stay green — this issue touches no models/controllers, so
    existing request/model specs should be unaffected; add/update view or request specs that
    assert the migrated `projects#index` renders the new `data-controller`/component markup
    (see [Acceptance Criteria](#acceptance-criteria) for what's asserted automatically vs.
    manually). Manually verify in a browser: switch each of the six themes via the picker,
    reload, confirm no flash and the choice persisted; toggle OS-level
    `prefers-reduced-motion` and confirm scroll-fade and hover-lift both go inert.

## Acceptance Criteria

- [ ] `application.tailwind.css` defines the six `--text-*` tokens at the exact rem values
      in [R1](#r1--type-scale-theme-tokens-18px-base-major-third-1250) (18/23/28/35/44/55px)
- [ ] Commit Mono and Inter are both self-hosted (no third-party font network request in the
      rendered `<head>`) and resolve via documented `--font-*` tokens (R3)
- [ ] `light`, `dark`, `dracula`, `nord`, `gruvbox`, `catppuccin` are all registered DaisyUI
      themes (R4); `dracula`/`nord` use DaisyUI's stock definitions, `gruvbox`/`catppuccin`
      are custom-defined
- [ ] Every bundled theme's `base-content`-on-`base-100` and `primary-content`-on-`primary`
      pair meets WCAG AA 4.5:1 (R2, R4) — spot-checked with a contrast calculator per theme
      before merge
- [ ] `#fab73a` used as text on the `light` theme's near-white canvas is replaced by the
      deepened amber variant (R2); `#fab73a` unchanged where it already contrasts correctly
      (dark canvas, button backgrounds with dark labels)
- [ ] All four partials in [Component API](#component-api) exist at the specified paths with
      the specified locals/block contract (R5)
- [ ] `Project#status` renders via the pill component using the documented
      status→badge-role mapping (R5, R9)
- [ ] Theme picker: selecting a theme updates `document.documentElement.dataset.theme`
      immediately and persists to `localStorage`; a full page reload shows the previously
      selected theme with no visible flash of a different theme first (R6) — verified
      manually in-browser (no system-test infra exists per Out of Scope)
- [ ] With OS/browser `prefers-reduced-motion: reduce` set, scroll-triggered fade/slide-in
      and hover-lift are both inert (elements render in final state immediately, no
      transition) (R7) — verified manually in-browser
- [ ] `app/views/projects/index.html.erb` is migrated per R9 and renders correctly for zero,
      one, and multiple `Project` records (existing request specs updated/added to assert
      the new component markup renders, e.g. presence of the pill/CTA partial output)
- [ ] `app/views/welcome/index.html.erb`'s hero no longer contains any of the six retired
      `text-{color}-{shade}` rainbow utilities (R10)
- [ ] `app/views/layouts/components/_header.html.erb` contains no literal `#fab73a` (R8)
- [ ] `docs/architecture/sub-systems/web-presentation.md`'s Public Contract, Key Invariants,
      and Anchor Files sections reflect the new controllers/components/token source (R11)
- [ ] `docs/design/redesign-2026.md` §3/§8/§9 record the resolved dev-theme list and body-sans
      choice, replacing the open-question language (R12)
- [ ] Existing `ci-gate` (`lint` + `test`) remains green
- [ ] No changes to `Project`/`Post` models, routes, or controllers (this issue is
      styling/component/token/JS-controller only)

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns)
and the scribe's own delegation rules:

- **Implementation** (all of R1–R12: Tailwind/DaisyUI config, font vendoring, the four
  component partials, both Stimulus controllers, the two migrated views, the architecture
  and design-doc updates, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (moving #1180's board status, closing on merge, unblocking
  P1.2/P1.3/P1.4/P1.8 once this merges): delegate to the **orchestrator** — this spec does
  not perform those operations.
- **Manual in-browser verification** of theme persistence and reduced-motion behavior
  (no automated system-test coverage exists — see Out of Scope): part of the implementer's
  own pre-PR verification (per the `verify` skill), not a separate agent.
- **Final exact hex values** for the deepened amber (R2) and the two custom theme palettes
  (R4) beyond the starting values given here: implementer's call within the stated
  4.5:1-contrast and same-hue-family constraints — not a decision requiring scribe/user
  sign-off, since the constraints are already fully specified.

## Open Questions

1. **Header theme-picker placement/visual treatment.** R6 requires the picker to exist and
   work; it does not prescribe exact placement within the header (inline with nav links vs.
   a separate corner element) or its "tiny terminal" visual detailing beyond §3's one-line
   description. Left to implementer/visual-QA judgment — not blocking, since the *behavioral*
   contract (switches, persists, no flash) is fully specified regardless of where it sits.
2. **`components/_cta_button.html.erb` block-content variant.** R5/Component API defines a
   text-only `label:` local. If a later issue (P1.2's "Work with me" CTA, roadmap item 13)
   needs richer content (icon + label, multi-line), that's a spec amendment to this
   component's contract at that time, not something to speculatively build now.
3. **Radius/depth/noise exact values (R4).** This spec requires the six themes share one
   consistent radius value but doesn't pin the exact `rem`/`px` number — left to
   implementer/visual-QA to match "rounded cards, comfortable spacing" (§3) by eye, since
   this is a genuine visual-design judgment call rather than a functional requirement.
4. **Gruvbox/Catppuccin palette refinement post-merge.** The R4 starting palettes are sourced
   from each scheme's official published colors and are expected to need minor visual-QA
   polish (e.g., a badge role that reads muddy against a particular base) once seen live
   against real content — that's expected iteration, not a spec gap, as long as the 4.5:1
   gate holds throughout.

## Changelog

### Version 1 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1180
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification for the design-system foundation: Tailwind 4 `@theme` type-scale
  and font tokens, DaisyUI 5 theme config (light/dark + 4 curated developer schemes), four
  shared ERB component partials, a theme-picker Stimulus controller with
  `localStorage`-persisted choice and flash-of-wrong-theme prevention, and a
  reduced-motion-aware motion controller
- Resolved both §8 open details named in the issue: curated developer-theme set (Dracula,
  Nord, Gruvbox, Catppuccin — 4 of the 6 named candidates, with rationale for the 2
  excluded) and body-sans pairing (Inter, replacing the never-actually-loaded Montserrat
  reference)
- Verified current app state: Montserrat CSS variable exists but no font is ever loaded;
  the header's hardcoded `#fab73a` nav-link color fails WCAG AA (~1.8:1) against the
  current default `light` theme's white canvas — a live accessibility defect this spec
  fixes via a two-token amber approach; DaisyUI 5.6.18 ships `dracula`/`nord` built in but
  not `gruvbox`/`catppuccin`/`solarized`/`tokyonight`; no Capybara/system-test
  infrastructure exists in this repo today
- Chose `app/views/projects/index.html.erb` (not `blog/index.html.erb` or the home hero
  alone) as the required migrated-page proof, since it's the only page that exercises all
  four required components (section, card, pill, CTA) at once; scoped it narrowly to
  exclude P1.3's triple-link-card work
- Scoped a narrow, token-only pass on the home hero to retire its six-color rainbow
  scheme (a §3-named "Palette" decision, not a content/IA decision), explicitly leaving
  copy/layout untouched for P1.2
- Named the exact Public Contract/Key Invariants/Anchor Files updates required in
  `docs/architecture/sub-systems/web-presentation.md`, since this issue changes an
  invariant already on record there (hardcoded `data-theme='light'`)

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by
the code agent.

---
