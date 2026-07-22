# Terminal-identity redesign (#1226)

## Problem

A second-pass visual redesign arrived as a Claude Design handoff in the
`design_handoff_personal_site/` directory at the repo root. It is untracked (not committed),
so it lives only in the checkout it was dropped into; obtain it from the original handoff
bundle if it isn't present in your working copy.
It re-lays-out all six pages into a cohesive **terminal-session** aesthetic. The current
site already ships the terminal *theme* (Phase 1, epic #1179) but with conventional
card/grid page layouts. This work replaces the **layouts and chrome** only; it reuses all
existing infrastructure.

Design references (source of truth for exact markup/copy):
- `design_handoff_personal_site/{Home,Writing,Projects,About,Resume,PostDetail}.dc.html`
- `design_handoff_personal_site/screenshots/*.png` (gruvbox renders)
- `design_handoff_personal_site/README.md` (spec prose)

## Chosen approach

Recreate the designs in the existing Rails + Tailwind v4 + DaisyUI 5 stack. **Do not**
copy the prototypes' inline styles or their raw CSS-variable palette — the six themes
already exist as DaisyUI themes in `app/assets/stylesheets/application.tailwind.css`. Map
the handoff's design tokens to the DaisyUI tokens already in use:

| Handoff token | Meaning | Tailwind/DaisyUI utility |
|---|---|---|
| `--b1` | page background | `bg-base-100` |
| `--b2` | surface (cards, statusline, footer) | `bg-base-200` |
| `--b3` | borders / hairlines | `border-base-300` |
| `--fg` | text | `text-base-content` |
| `--fg7` | text 72% | `text-base-content/70` |
| `--fg5` | text 50% | `text-base-content/50` |
| `--p` | primary accent | `text-primary` / `bg-primary` |
| `--pc` | text-on-accent | `text-primary-content` |
| `--ok` | success/green | `text-success` / `bg-success` |
| `--warn` | warning/amber | `text-warning` / `bg-warning` |
| `--err` | error/red | `text-error` / `bg-error` |

Radius: cards/panels `rounded-[10px]`, chips/buttons/inputs `rounded-md` (6px), small
tags `rounded` (4px). Content wrapper: `max-w-[1088px] mx-auto px-8` (→ 1024 content).
Fonts already bundled: `font-mono` (Commit Mono) for chrome/headings/prompts, `font-sans`
(Inter) for prose. **No hardcoded hex / arbitrary-value color utilities** — the site's
existing lint/spec guard (welcome_spec "rainbow utilities") forbids them; use the tokens
above so all six themes work everywhere.

## Decisions (operator-approved)

1. **Positioning: drop "fractional"/"CTO" everywhere.** The handoff's About "what I do"
   paragraph opens "I'm a fractional architect…"; rewrite to drop "fractional" (e.g.
   "I'm an embedded architect: I join a team for a defined stretch…"). The Resume
   subtitle "Fractional Software Architect" is not used — see #2.
2. **Resume uses the real existing data**, `resume/resume.yml` via `ResumeHelper#resume_data`
   (the current `welcome/resume` partials already render it). The handoff's roles/skills/
   education are placeholders — ignore them. Restyle the real content to the terminal look.
3. **Reuse, don't rebuild:** the six DaisyUI themes, self-hosted fonts, the modal vim
   keyboard layer (`keyboard_nav_controller.js` + command bar / guide dialog / hint
   overlay), `theme_picker_controller.js`, content models (Post kind note/deep_dive,
   Project status), newsletter (`components/newsletter_signup`), and first-party analytics
   all stay. This is one combined branch/PR.

## Hard constraints (must not break)

- **Keyboard-layer test contract.** The statusline element MUST keep `id="keyboard-status-line"`,
  `data-keyboard-nav-target="statusLine"`, start with the `hidden` class (JS reveals it on
  connect — that transition is the specs' "connect ran" proxy), and contain
  `data-keyboard-nav-target="statusLineText"` whose text is `-- NORMAL --`
  (`spec/support/keyboard_nav_helpers.rb`, the `keyboard_nav_*` system specs). Restyle the
  element freely, but keep those hooks and that text verbatim.
- **Nav targets.** The header must keep anchors carrying `data-nav-target="home|writing|projects|about|resume"`
  (`resolveNavTarget` + `about_spec` read them). Home's target moves onto the `❯ james@ebentier`
  logo (design drops a separate "Home" nav item). Rails URL helpers stay the single source
  of every href — no path literals.
- **Theme `<select>`.** Keep `#theme-picker-select` with its six options in order
  (light dark dracula nord gruvbox catppuccin), `data-theme-picker-target="select"`,
  `data-keyboard-nav-target="themeSelect"`, `data-action="theme-picker#change"`. Restyle it
  into the `t <theme>` chip; do not replace it with a non-`<select>` control.
- Preserve WCAG AA contrast across all six themes and the existing a11y patterns
  (aria-hidden on decorative glyphs, sr-only labels).

## Shared chrome

### Header (`app/views/layouts/components/_header.html.erb`)
60px tall, `border-b border-base-300`, inner `max-w-[1088px] mx-auto px-8`, `font-mono`.
- Left: logo link to `root_url`, `❯ james@ebentier` — `❯` in `text-primary`, bold, 15px.
  Carries `data-nav-target="home"`.
- Right `nav` (14px, gap-6): `writing`, `projects`, `about`, `resume` → Rails URL helpers,
  each with its `data-nav-target`. Default `text-base-content/70`, hover `text-primary`;
  **active page** = `text-primary font-bold` (no hover change) via `current_page?`.
- Theme chip: bordered pill wrapping the existing `<select>` with a leading `t` in
  `text-primary font-bold`. Restyle, keep all data hooks/id/options.
- `?` help chip: bordered square, opens the guide dialog. Add a small
  `openGuideDialog` action to `keyboard_nav_controller.js` bound via
  `data-action="click->keyboard-nav#openGuideDialog"` (additive; it calls
  `this.guideDialogTarget.showModal()`). Show on `md+`.

### Statusline (`app/views/layouts/components/_keyboard_status_line.html.erb`)
Full-width bar in normal flow (it already renders after the footer in the layout), top
border `border-base-300`, `bg-base-200`, `font-mono text-[13px]`. Keep the hard-constraint
hooks above. Structure: mode badge (the `statusLineText` span, styled
`bg-primary text-primary-content font-bold px-4 py-1.5`, keeps `-- NORMAL --`) · current
path segment (`text-base-content/70`) · right-aligned hint group (`ml-auto`, gap, each hint
`<key>` in `text-primary font-bold` then label, `text-base-content/50`), hidden below `md`.
Path + hints come from a new `StatuslineHelper` keyed on controller/action:
- `welcome#index`→`~/home`; `writing#index`→`~/writing`; `projects#index`→`~/projects`;
  `welcome#about`→`~/about`; `welcome#resume`→`~/resume`; `writing#show`→`~/writing/<slug>.md`;
  `projects#show`→`~/projects/<slug>`; else `~/`.
- Hints: home/about/resume → `: command`, `/ search`, `t theme`, `? help`;
  writing index → `/ search posts`, `j k scroll`, `f jump to link`;
  projects index → `: command`, `/ search`, `f jump to link`;
  post (writing#show) → `j k scroll`, `gg top`, `t theme`.

### Footer (`app/views/layouts/components/_footer.html.erb`) — Home only
The layout renders the footer only on the home page now (add `show_full_footer?`
→ `current_page?(root_path)` and wrap the render in the layout). Interior pages end at the
statusline. 3-column grid (`1.2fr 0.7fr 1.3fr` on `md+`, one column below), gap-12,
`py-12 px-8`, top border, inside the `max-w-[1088px]` wrapper:
1. Identity: `❯ james@ebentier` (mono 15/bold), `© <year> James Ebentier · Berlin` +
   `Impressum · Privacy` links (`text-base-content/50` 13px), then social icons row
   (GitHub, LinkedIn, Twitter, RSS via the existing `social_profile_icon` helper / FA),
   `text-base-content/70` hover primary.
2. Sitemap: `# sitemap` label (mono 13, `/50`), then `/writing /projects /about /resume`
   links (Rails helpers, mono 14).
3. Newsletter: `# newsletter — occasional writing on systems & craft`, then the
   shell-prompt styled `components/newsletter_signup` (see below), consent checkbox
   beneath.
The shared `work_with_me_cta` moves OUT of the footer; each page carries its own CTA block
(Home in-page CTA card, About contact card) — see per-page. Keep a `<footer>` element and a
newsletter form inside it (welcome_spec expects ≥2 newsletter forms on `/`, one in footer).

### Newsletter signup restyle (`app/views/components/_newsletter_signup.html.erb`)
Shell-prompt row: `$ subscribe` (`text-primary`) + transparent email input + `↵` submit
button (bordered primary, hover fills `bg-primary text-primary-content`), inside a bordered
`rounded-md` box. Keep the form action (`newsletters_path`, POST), the `subscriber[email]`
email field, the `subscriber[source]` hidden field, and the `subscriber[consent]` checkbox
linking to `privacy_path` (newsletters_spec + welcome_spec depend on these). Keep it usable
as both the footer form and any inline/home form; a `source` local is already passed.

## Per-page

### Home — `app/views/welcome/index.html.erb` (`Home.dc.html`)
Mono content column `max-w-[1088px] px-8 pt-16`, session-log of command blocks:
1. `james@ebentier:~$ whoami` (`~$` in primary) → H1 (mono 38/bold, max-w 900) — the
   verbatim positioning line, second clause `text-primary`; then sans lead (20px, `/70`,
   max-w 760) — the existing subhead copy verbatim (welcome_spec pins both).
2. `james@ebentier:~$ ls ~/projects --featured` → `Project.for_home(limit: 3)` as rows
   (link to the project's page): `slug/` (w-280, primary/bold) · `● <status>` (w-110,
   status color) · one-line description (sans 15, `/70`, truncate) · `[demo ↗]` (`/50`,
   right). Top hairline per row, hover `bg-base-200`. Omit block if none.
3. `james@ebentier:~$ tail -n 3 ~/writing` → `Post.for_home(limit: 3)` as rows (link to
   post): ISO date (w-110, `/50` 13px) · title (flex, bold, hover primary) · `<min> min`
   (`/50` 13px). Omit block if none. (`Post#reading_minutes` or equivalent — check the model.)
4. `james@ebentier:~$ stats views --last 7d` → static-for-now output: sparkline glyphs
   `▁▂▂▃▅▃▇` (primary, aria-hidden), a views count, muted note "first-party only — no
   third-party trackers…". Real numbers can wire to analytics later; a static teaser is
   fine for v1 (do NOT invent a live query). Keep it clearly labelled.
5. Final prompt `james@ebentier:~$ █` with a blinking block cursor (define a `blink`
   keyframe in the stylesheet or a small utility; respect `prefers-reduced-motion`).
6. In-page CTA card (bordered `bg-base-200 rounded-[10px]`): `# get in touch` +
   "Have a hard technical decision…" + right-aligned CTA button. Reuse
   `components/work_with_me_cta` (must keep an `a.btn-primary` with text "Work with me"
   → `mailto:` from resume.yml; welcome_spec + about_spec pin this) but present it in the
   terminal card styling; the visible label stays "Work with me".

Then the Home-only footer + statusline (chrome).

### Writing — `app/views/writing/index.html.erb` (`Writing.dc.html`)
Prompt `ls ~/writing`, H1 "Writing" (mono 36/bold). Filter row: active `--all` filled
primary pill, inactive `--notes` / `--deep-dives` bordered pills (these map to the existing
Post kind filter — reuse the current filter mechanism/params, restyled). Right meta
`--sort=date ↓ · <N> entries`. Listing: one row per published post, mono, hairlines, hover
`bg-base-200`, link to post: ISO date (w-100, `/50`) · kind glyph (`◆` deep_dive / `◇`
note, primary) · title (flex, 16/bold, hover primary, truncate) · `#<first-tag>` (`/50` 12,
nowrap) · `<min> min` (w-56, right, `/50`). Legend footnote (mono 13, `/50`) explaining the
glyphs. Use the real posts from the DB (all published), not the handoff's sample list.

### Projects — `app/views/projects/index.html.erb` (`Projects.dc.html`)
Prompt `ls ~/projects`, H1 "Projects" (mono 36/bold). Filter row: active `--all`, inactive
`--pre-launch` / `--beta` / `--live` (map to Project status; reuse existing filter if any,
else render all). 2-col grid (`md:grid-cols-2` gap-6) of window cards (`bg-base-200`,
`border-base-300`, `rounded-[10px]`, hover `border-primary`): title bar (traffic-light dots
error/warning/success, `~/projects/<slug>` truncate, right `● <status>` in status color) +
body (name mono 23/bold link hover primary, sans description flex-1, divider, then bracket
"commands" `[demo ↗]` primary + `[read]` + `[source]` `/50` hover primary — wire to the
project's real demo/source/detail URLs; omit a bracket if that URL is absent).

### About — `app/views/welcome/about.html.erb` (`About.dc.html`)
Narrow reading column `max-w-[760px] px-8 pt-16`. `cat about.md` prompt, H1 (mono 34/bold,
positioning line, second clause primary), sans lead. Two `## <label>` section headers
(mono 15/bold primary + flex-grow hairline): **## what I do**, **## how I work** — copy
from the design file, **de-fractionalized** (drop "fractional"). Keep the proof links
"what I've shipped" → projects and "what I've written" → writing, and the "resume" link
(about_spec pins the first two link texts). Contact card (bordered `bg-base-200`): `# get
in touch` + copy + `work_with_me_cta` ("Work with me" btn-primary mailto). Keep the About
meta title; **update the meta description to drop "Fractional"** (the existing about_spec
asserts the old "Fractional software architect…" description — that spec will be updated by
the test agent to the de-fractionalized copy; use "Software architect based in Berlin…").

### Resume — `app/views/welcome/resume.html.erb` + `welcome/resume/_*.html.erb` (`Resume.dc.html`)
Reading column `max-w-[900px] px-8`. Header row: left `cat resume.txt` prompt + name
"James Ebentier" (mono 34/bold) + subtitle "Software Architect · Berlin, DE" (**no
"Fractional"**, no invented "15+ yrs" unless derivable) from resume.yml basics; right
`↓ download.pdf` button (`bg-primary text-primary-content rounded-md`) — wire to the
existing resume PDF/download route if one exists, else the print view. Contact grid (2-col,
mono 14): bordered `bg-base-200` tiles for `email`, `github`, `site`, `status`
(`● available for engagements` in success) — values from resume.yml basics/profiles; labels
in primary. `## summary` (resume.yml basics.summary). `## experience` — vertical list, each
a flex row: date span (w-150, `/50` mono 13) + block (position 19/bold, company primary mono
14, summary sans 16 `/70`) from resume.yml `work`. Two-column band: `## skills` (wrapping
mono 13 bordered pills from resume.yml `skills[].keywords`) + `## education` (degree 17/bold
+ school·span) from resume.yml `education`. Restyle the existing partials rather than
inventing data.

### Post detail — `app/views/writing/show.html.erb` (`PostDetail.dc.html`)
`<article>` reading column `max-w-[740px] px-8`, body `font-sans text-lg leading-[1.7]`.
Back link `cd ../writing ←` (mono 13, `/50`, → posts_path). Meta line (mono 13, `/50`):
`<glyph> <kind> · <ISO date> · <min> min · #tag #tag`. H1 (mono 36/bold), dek (21px, `/70`)
if present. If the post has a `medium_url`, the "originally published / Also on Medium"
callout: mono 13, `/50`, `border-l-2 border-primary pl-3.5`, link out (keep the existing
Medium-syndication behavior/copy from #1185). Body: prose via the existing renderer;
`H2` mono 24/bold, `H3` mono 19/bold; inline code chips (`bg-base-200 border-base-300
rounded px-1.5`); blockquote `border-l-2 border-base-300`. If the post model carries a
sources list, render a `# sources & further reading` block (top border). Inline subscribe
card at the end (bordered `rounded-[10px]`): `# subscribe` + note + the shell-style
`newsletter_signup` (source: "post"). Then statusline (no footer).

## Acceptance criteria

- All six pages render faithfully to the handoff across **all six themes** (spot-check
  light + gruvbox + one light-on-dark like nord) with no hardcoded hex/rainbow utilities.
- The keyboard layer still works end-to-end (statusline reveals, `t`/`:`/`/`/`f`/`gg`
  bindings, guide dialog) — its system specs stay green with only the statusline restyle.
- Rails URL helpers are the only source of hrefs; nav `data-nav-target`s intact.
- "Fractional"/"CTO" appears nowhere in rendered pages or meta.
- Resume reflects the real `resume.yml`.
- `bin/rails` boots, `yarn build`/`build:css` succeed, RuboCop clean.

## Test impact (for the test agent, after implementation)

Many `spec/requests/*` and `spec/views/components/*` specs encode the OLD card/grid
structure and WILL fail — they must be updated to the new contract, not the reverse:
- `welcome_spec`: the ASCII-monogram `pre[aria-hidden]` block, `section`/`h2.text-2xl`
  section titles, `a.absolute` stretched links, `.badge` status pills, `md:grid-cols-3`
  grids, and the footer-CTA expectation all change. Keep/verify: `$ whoami` eyebrow, the
  h1 positioning line, the exact subhead, no-Invoca-in-hero, no-fractional/CTO, theme-picker
  six options, ≥2 newsletter forms + one inside `<footer>` (now Home-only).
- `about_spec`: update the meta-description assertion to the de-fractionalized copy; footer
  assertions now apply on Home only (About has no footer) — move/adjust. Keep header
  `data-nav-target='about'`, "What I do"/"How I work", the two proof-link texts, the
  "Work with me" mailto CTA.
- Component specs (`_card`, `_pill`, `_section`, `_cta_button`) — the redesign may stop
  using `components/card`/`section` on some pages; keep the components (and their specs) if
  still used elsewhere, otherwise the test agent prunes dead specs.
- Add light coverage for the new `StatuslineHelper` and the per-page statusline path/hints.

## Open questions

- Home `stats` block: static teaser now, or wire to `analytics/stats.json`? Defaulting to a
  static, clearly-labelled teaser for v1 (analytics wiring is a follow-up).
- Resume `↓ download.pdf`: confirm whether a PDF/print route exists; if not, link the
  print stylesheet view or omit until a real asset exists.
