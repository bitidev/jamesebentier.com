# About page + Work-with-me CTA — Design (#1184)

> **Status:** Awaiting operator approval · **Issue:** [#1184](https://github.com/bitidev/jamesebentier.com/issues/1184) · **Parent:** Phase 1 epic (#1179), `docs/design/redesign-2026.md` §2 & §4

## Problem

The redesign positions James as a fractional architect / CTO — proof over pitch — but there is
no `/about` page to carry that narrative. P1.1 (#1181) shipped the home-page "Work with me"
CTA as a real `mailto:` link; P1.5 completes the contact surface by adding the about story
and placing the same CTA on `/about` and in the footer, structured so the target can later
swap to a form or booking flow without a layout rewrite.

## Chosen approach

### Route & controller

- Add `GET /about` → `WelcomeController#about` (same controller family as home/resume).
- View: `app/views/welcome/about.html.erb`.

### Shared CTA partial

Extract the home page's "Work with me" block into a reusable partial:

```
app/views/components/_work_with_me_cta.html.erb
```

- Renders the existing pattern: `components/section` wrapper, eyebrow `"Get in touch"`,
  one supporting sentence, `components/cta_button` (`label: "Work with me"`, `style: :primary`).
- `href` sourced from `resume_data[:basics][:email]` (single source of truth in
  `resume/resume.yml`) — same as home today.
- Optional local `supporting_copy:` to override the default sentence on `/about` if the page
  needs context-specific wording; home and footer use the default.

Refactor `welcome/index.html.erb` to render this partial instead of inlining the CTA block.

### About page content & layout

Static ERB narrative composed from P1.1 primitives — no new components, no DB model.

Structure (all sections via `components/section` except the page `<h1>`, mirroring home/projects
patterns):

1. **Hero** — page `<h1>` with the positioning line from §2 (`"I help engineers get their
   systems right — a fraction of the time, all of the leverage."`), plus a short subhead
   (Berlin-based software architect; embeds with teams; mentors engineers).
2. **What I do** — fractional-architect framing: unblock hard technical decisions, improve
   systems and delivery, leave teams stronger than you found them. Tone: demonstration, not
   solicitation.
3. **How I work** — mentorship + community as the through-line (aligns with Bardic Labs /
   "bard as support class" positioning without naming the lab yet — `/lab` is Phase 2).
4. **Proof** — brief pointer to Writing and Projects as evidence; inline links, no case-study
   carousel.
5. **CTA** — render `components/work_with_me_cta` at page bottom (about-specific supporting
   copy if it reads better in context).

Typography: `prose` / existing token classes for body copy; headings in Commit Mono (`font-mono`).

Meta: `set_meta_tags` with a concise title/description suitable for sharing (full OG polish is
P1.10's job — no new meta infrastructure here).

### Navigation & discoverability

- **Header:** add an "About" link (between Projects and Resume), with `data-nav-target="about"`
  for future keyboard-nav parity. No `:about` COMMAND/`g`-jump wiring in this issue — that's
  optional follow-up to #1187.
- **Footer Links column:** add `About` alongside Writing / Projects / Resume.
- **Footer CTA:** render `components/work_with_me_cta` below the link columns (full-width,
  centered — same understated treatment as home, not a banner).
- **Sitemap:** add `about_path` explicitly in `config/sitemap.rb` (the auto-discovery hook
  only picks up `#index` actions).

### Future-proofing the CTA target

The partial is the single swap point. When a contact form or booking URL arrives, change
`href` (and optionally `label`) in one partial — or introduce a `ContactHelper#work_with_me_href`
if the target becomes environment-driven. No route or layout changes required.

## Acceptance criteria

- [ ] `GET /about` returns 200 with the fractional-architect + mentorship narrative.
- [ ] Page uses existing `components/section`, `components/cta_button` — no new design-system
  components.
- [ ] Shared `components/work_with_me_cta` partial exists; home, about, and footer all render
  it.
- [ ] CTA `href` is `mailto:` sourced from `resume/resume.yml` via `resume_data` — opens email
  client when clicked.
- [ ] Header and footer include an About link to `/about`.
- [ ] `/about` appears in the generated sitemap.
- [ ] Request specs cover `/about` (200, meta, CTA mailto), footer CTA presence, and that
  home still renders the shared partial correctly.

## Open questions

1. **Copy review** — the narrative draft above follows §2 positioning; do you want to supply
   exact wording, or is implementer-drafted copy (reviewable in the PR) acceptable?
2. **Header order** — proposed: Home · Writing · Projects · **About** · Resume. Prefer a
   different slot?
3. **Keyboard nav** — defer `:about` COMMAND/`g a` binding to a #1187 follow-up, or include a
   minimal registry + `data-nav-target` wiring in this PR?
4. **Footer CTA placement** — proposed: below the three footer columns. Prefer it inside the
   Links column instead (more compact, less prominent)?
