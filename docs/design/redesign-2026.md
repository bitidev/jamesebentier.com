# jamesebentier.com — Redesign Design Doc (2026)

> **Status:** Draft for review · **Owner:** James Ebentier · **Created:** 2026-07-18
>
> This is the consolidated design reference for the site redesign. It captures the
> positioning, visual direction, information architecture, and a phased build plan.
> Individual pieces become ADLC issues (spec-before-code) driven by the orchestrator.
> This doc is the *why* and the *shape*; per-issue specs are the *how*.

---

## 1. Goals

Re-purpose the personal site into a stronger launching point for **fractional
architect / CTO** work — guiding a company's technical direction temporarily or in
a niche, through mentorship and contract work — **without** a hard consulting pitch.
The site should read as *nerdy but smart and professional*: an engineer who clearly
builds things for fun, and whose thinking is worth paying for.

Three initiatives layered on the current (solid) Rails base:

1. **Visual / brand refresh** — a sleek, modern, hacker-esque but approachable UI.
2. **Content consolidation** — projects + writing presented well; Medium handled via
   syndication so there's a single place to write.
3. **AI Lab identity** — this domain becomes the central login authority (OIDC/OAuth2
   provider) for a set of AI experiment projects.

### Non-goals
- No hard "hire me" / services-with-pricing page. The signal stays subtle (proof over pitch).
- No framework change. Rails 8 + Hotwire + Tailwind 4 + DaisyUI stays.
- No migration of legacy identity (there is none today — greenfield auth).

---

## 2. Positioning

**Fractional architect / CTO.** A real, understood category — no explanation required.
The soft-sell mechanic is *demonstration, not solicitation*: sharp writing, real shipped
projects, visible mentorship, and the AI Lab as living proof of competence. One
understated CTA ("Work with me" / "Let's talk"), no banners.

**Positioning line:**
> "I help engineers get their systems right — a fraction of the time, all of the leverage."

Note the deliberate framing: *engineers* (not startups) and *systems* (not architecture)
keeps the emphasis on craft, mentorship, and helping people grow — the true passion —
while "a fraction of the time" quietly carries the fractional-architect signal.

---

## 3. Visual direction — "Refined terminal, warmed up"

Dark-first and minimal (restraint in the spirit of philipwalton.com), softened toward
approachable (warmth in the spirit of taniarascia.com), with a retained hacker/scrappy
edge.

- **Mode:** dark-first. Keep the existing light theme for the print/resume path.
- **Terminal theme picker (playful):** let the viewer pick a theme from a small,
  terminal-style switcher. Defaults are **light** and **dark**; additionally offer a
  curated set of beloved developer color schemes — **Dracula, Nord, Gruvbox,
  Catppuccin** (see spec [#1180 §D1](../specs/1180-design-system-pass-refined-terminal.md#d1--curated-developer-theme-set-dracula-nord-gruvbox-dark-catppuccin-mocha)
  for the excluded-candidates rationale). Persist the choice (localStorage).
  Implemented as DaisyUI themes + a Stimulus controller. This is a personality
  moment — the switcher itself should feel like a tiny terminal.
- **Palette:** retire the multi-color accent hero (green/purple/orange/pink/yellow).
  Move to a disciplined base — near-black canvas, soft off-white text — plus **one
  signature accent: amber `#fab73a`** (already in use), applied consistently to links,
  focus states, and CTAs.
- **Typography:** **Commit Mono** is the signature typeface — used for headings, nav,
  metadata, labels, code, and all "system" cues — paired with **Inter** for long-form
  body so Deep Dives stay comfortable (see spec [#1180 §D2](../specs/1180-design-system-pass-refined-terminal.md#d2--body-sans-pairing-inter-not-montserrat)
  for why Inter over the never-loaded Montserrat reference). Commit Mono is
  free/open, neutral-but-characterful, and [its own site](https://commitmono.com/) is a
  direct design touchstone for us (see the keyboard command layer below).
- **Type scale:** base **18px**, **Major Third (1.250)** → 18 · 23 · 28 · 35 · 44 · 55.
  Editorial enough for Deep Dives, punchy headings. Adjustable; exact `rem` tokens are
  spec'd in the design-system issue.
- **Components (DaisyUI + a thin custom layer):** section wrapper, project card, post
  card, tag/status pill, reusable CTA. Rounded cards, comfortable spacing.
- **Motion:** restrained — fade/slide on scroll, hover lift on cards — via a Stimulus
  controller.
- **Personality:** carried by monospace/terminal touches and opinionated post titles.
  No forced logo gimmick. (Optional, low-priority: a tasteful `½` / fraction-bar glyph
  in the logo lockup as a subtle nod to "fractional" — not a lead element.)

### Signature interaction — the site as a terminal
Inspired directly by commitmono.com's keyboard-driven UI. The site is fully driveable
from the keyboard via a **modal NORMAL/COMMAND/SEARCH navigation layer** — modeled on
neovim's own mode model, not a flat set of global shortcuts — and this is the personality
centerpiece, unifying theming, navigation, search, and (later) analytics into one coherent
nerdy-but-polished idea. Full technical design: architecture plan
[`docs/plans/1187-modal-vim-keyboard-navigation-architecture-plan.md`](../plans/1187-modal-vim-keyboard-navigation-architecture-plan.md);
implementation spec [`docs/specs/1187-modal-vim-keyboard-navigation.md`](../specs/1187-modal-vim-keyboard-navigation.md).

- **Modal state machine** — NORMAL (default) / COMMAND (`:`) / SEARCH (`/`), with a
  visible terminal-style mode indicator (`-- NORMAL --` / `-- COMMAND --` / `-- SEARCH
  --`) and `Esc` always returning to NORMAL. `t`, `g h/w/p/l`, `?`, and `f` (below) are
  all **NORMAL-mode bindings** under this machine, not free-floating shortcuts.
- **COMMAND mode** — `:` (bare, no modifier chord) opens a real terminal-style command
  input; an extensible command registry (nav commands today, §6.4 metrics queries plug in
  later). The original `Cmd/Ctrl-K` framing is dropped: the modal design intentionally
  uses bare `:` only, so it never contends with browser/OS shortcuts.
- **SEARCH mode** — `/` opens in-page/site content search over Posts and Projects,
  `n`/`N` step through results, Enter navigates.
- **NORMAL-mode navigation** — `h/j/k/l` and `j/k` scroll, `gg`/`G` top/bottom, `g h/w/p/l`
  page jumps, `t` cycle theme, `?` toggle the keyboard-guide overlay (à la Commit Mono's
  guide).
- **`f` hint-jump** — a Vimium-style overlay labels every on-screen link with a short hint
  tag; typing the tag activates that link, mouse-through unaffected.
- **Queryable everything** — the COMMAND registry can navigate, switch theme, *and* (once
  §6.4/§6.5 land) query the site's own first-party analytics — e.g. `stats views --last
  7d`, `top posts`. Metrics stay on our infrastructure and become interactive, not hidden.
- **Progressive enhancement + a11y** — the layer never intercepts keys in native form
  fields; `Esc` is always available; nothing traps focus (except the native `<dialog>`
  used for the `?` guide); `prefers-reduced-motion` is respected; full site navigation,
  search, and links work with the layer entirely absent. Built as a Stimulus controller
  with pure-function logic (parsing, ranking, hint generation) factored out for
  unit-testability.

### Design references distilled
- **taniarascia.com** — warmth, a content taxonomy (Blog/Notes/Deep Dives/Projects),
  a human note, personality artifacts, newsletter + RSS.
- **daverupert.com** — personality through specific/opinionated titles; tags; an
  "Active Projects" grid; indie-web social presence.
- **philipwalton.com** — authority through restraint; excerpts under titles; the
  minimalism *is* the flex.
- **jareddillard.com** — hobbies-as-tools; projects are useful things that reveal the
  person (our AI Lab is this).

Shared DNA to adopt: content-first minimalism; **writing feed as the homepage**; a crisp
one-line identity statement; plain text nav; tags + dates + excerpts; and **POSSE**
(Publish on your Own Site, Syndicate Elsewhere) — which is exactly the Medium strategy.

---

## 4. Information architecture

```
/            Hero (positioning) → Featured projects → Latest writing → understated CTA
/writing     Blog index (canonical home for posts); filter by kind (Notes / Deep Dives)
/writing/:slug
/projects    Grid, filterable by status (Pre-Launch / Beta / Live), triple-link cards
/projects/:slug
/lab         AI Lab directory — what it is + list of experiments (public shell in P1)
/lab/*       OIDC-protected experiments (Phase 2)
/about       The fractional-architect story + mentorship — carries the soft signal
/resume      Keep as-is (print-friendly, light theme)
```

- **Clean refresh — no `/blog` → `/writing` redirect.** This is a deliberate reset, not a
  migration; treat it as a new front door.
- Home is the front door for **writing** (per the shared DNA of all four references).

---

## 5. Content model

Stays file-backed markdown + DB metadata (it works). Additions:

### Newsletter (aspirational)
Add a newsletter signup (footer + a tasteful home placement). **Not launched immediately**
— it's a demand signal: collect addresses now, and if enough interest accumulates, stand up
a real newsletter later. Implementation: capture emails to our own DB (a `Subscriber` model)
rather than committing to a provider up front, so there's no vendor lock-in before it's worth
it. Confirm opt-in (double opt-in) and GDPR-compliant storage (see §8, we're Berlin-based).

### `Post`
- `kind` — enum: `note` | `deep_dive`. **All existing posts are Deep Dives**; Notes
  start later. Guidelines below.
- `tags` — already present; surface in UI.
- `excerpt` — one/two-line summary shown under titles in the feed.
- `reading_time` — derived from content.
- `featured` — boolean, drives home-page selection.
- `medium_url` (and optional `canonical_url`) — for the "Also on Medium" link.

### Note vs. Deep Dive — editorial guidelines
So both writer and readers share expectations:

| | **Note** | **Deep Dive** |
|---|---|---|
| Length | Short (~< 500 words) | Long-form (~1,000+ words) |
| Purpose | A single thought, reaction, TIL, or link + commentary | A worked-through system, argument, or lesson that teaches a reusable mental model |
| Cadence | Frequent, low ceremony | Infrequent, high polish |
| Artifacts | Optional | Usually code, diagrams, or worked examples |
| Role | Keeps the site alive, shows personality | The credibility engine for fractional work |

**Heuristic:** *If it teaches a reusable mental model or walks through a system, it's a
Deep Dive. If it's a thought, reaction, or TIL, it's a Note.* When in doubt, it's a Note —
Notes can graduate into Deep Dives.

### `Project`
- `status` — already present (`Pre-Launch` / `Beta` / `Live`); surface as a pill.
- Triple-link fields — **read** (article/details) → **demo** (live URL) → **source**
  (repo). `url` exists; add the others as optional.
- `featured` — boolean, drives home-page selection.

---

## 6. The three hard problems

### 6.1 Identity — AI Lab central login authority
**Decision: self-hosted OIDC via Doorkeeper.** This domain becomes an OAuth2 /
OpenID Connect **provider**; each AI Lab project is an OIDC client (relying party)
that trusts `jamesebentier.com` as its IdP.

- Gems: `doorkeeper` + `doorkeeper-openid_connect`.
- A `User` model + auth (registration, login, session, password reset). MFA later.
- Branded, on-domain **login + consent** screens — the visible "central authority" moment.
- Flow: Authorization Code + **PKCE** for each client.
- Needs an RSA signing key for OIDC ID tokens — managed via **Kamal secrets**.
- New subsystem: **`identity`** in `docs/architecture`, beside `content-domain`.
- Security-sensitive: own spec, careful review pass, rate limiting on auth endpoints,
  token/key rotation, audit logging.
- **Domain strategy — subdomains, not paths.** Each experiment gets its own subdomain
  (e.g. `lab.jamesebentier.com`, `<experiment>.jamesebentier.com`) so experiments can be
  deployed to different machines independently. The IdP lives on the apex/`accounts`
  subdomain. Implication: OIDC redirect URIs and cookie scope are per-subdomain (no shared
  session cookie across subdomains — auth flows through OIDC, which is the correct pattern
  anyway). Plan a wildcard TLS cert (`*.jamesebentier.com`).

*Alternatives considered and declined:* self-hosted Keycloak/Ory (heavier ops); managed
IdP — WorkOS/Auth0/Clerk/Logto (fast, but dilutes the "my domain is the authority"
narrative and adds a vendor).

### 6.2 Medium — content syndication
**Decision: this site is canonical; syndicate *to* Medium (POSSE).**

Reality: Medium's public **posting API is deprecated** (no new integration tokens since
~2023), so true API-driven "publish everywhere" isn't available. Workflow instead:

1. Write markdown here; publish (site = source of truth / canonical).
2. Use Medium's **"Import a story"** tool with your post URL — Medium creates a copy that
   auto-sets `rel=canonical` back to jamesebentier.com (SEO/traffic accrues to your domain).
3. Store the resulting `medium_url` on the `Post` and render an "Also on Medium" link.

Document this as a repeatable **runbook** (`docs/ops/medium-syndication.md`).

### 6.3 Visual redesign
Design-token + component pass, not a rewrite. Lives in `application.tailwind.css` theme
tokens + `web-presentation` views/components. Low-risk; each piece reviewable in one
sitting (fits the strategic-priorities size/ambiguity envelope).

### 6.4 Bardic Labs — the AI Lab, and its rating mechanic
**Name: Bardic Labs** (tabletop-RPG inspired). In tabletop, the **bard** is the support /
mentor class, and **Bardic Inspiration** is the mechanic where the bard hands an ally a die
to add to *their* roll — you make everyone around you succeed better. That's a bullseye for
the brand: mentorship, growing the community, a fractional architect who levels up the team.
It still ties to the dice: Bardic Inspiration *is* a bonus die.

Clearance (as of 2026-07-18): no company trades as "Bardic Labs"; no USPTO `BARDIC` mark in
software/consulting classes (only an unrelated textiles registration); the nearest name,
Bardic Systems, is education-sector consulting in a distinct market. Caveats: "Bardic-" is a
mildly crowded *prefix* (be deliberate about SEO/identity), and there's a faint, fading
"Google Bard" echo in an AI context.

**Hosting: subdomain-first.** Bardic Labs launches at **`bardic-labs.jamesebentier.com`** —
a subdomain of the personal site, no separate domain required. Registering `bardiclabs.com`
is therefore *optional defensive insurance*, not a technical dependency: cheap (~$12/yr) to
reserve and 301-redirect to the subdomain if the brand might ever go standalone; safe to
defer if it stays a personal sub-experiment. (`.dev` is a natural fallback.) Domain ≠
trademark — no TM action warranted for a personal lab.

- **Rating mechanic (unchanged):** every experiment gets a **d20 rating, Nat 1 → Nat 20**,
  by how successful it turned out. Deliberately humble — *every idea is a roll of the dice*;
  most land mid-scale, some crit, some flop. Reinforces the authentic, build-in-public ethos.
- **Rating model:** owner-assigned score to start; **optionally let visitors rank** each
  experiment too (community engagement → ties to the mentorship/community goal). Owner vs.
  visitor scoring — and whether they're shown side by side — is an open detail (§8).
- Surfaces on the `/lab` directory as a d20 badge per experiment; sortable by roll.
- Fits the terminal theme (`roll`-flavored commands are a fun future touch, e.g.
  `lab --sort roll`). Bardic Inspiration could even theme the newsletter/mentorship touch.

### 6.5 Analytics — first-party, and the AI Lab's first experiment
**Decision: remove Google Analytics and Metricool; build our own first-party metrics.**
No visitor data leaves our infrastructure. This is framed as **the AI Lab's inaugural
experiment** — dogfooding the "build it myself" ethos.

- **Collection:** lightweight first-party event capture (page views, referrers, basic
  UTM) stored in our own Postgres — privacy-respecting, no third-party beacons. Cookieless
  where possible (eases the GDPR/consent story; see §8).
- **Queryable via the terminal.** The killer tie-in: metrics are surfaced through the
  site's command layer (§3) — `stats views --last 7d`, `top posts`, `referrers`. Public
  vs. owner-only query scopes TBD (some stats could even be public — "build in public").
- **Removes** the GA (`G-TWP4CV64DK`) and Metricool snippets from the layout.
- Likely its own small subsystem (`analytics`) once it grows past a single table.

---

## 7. Phased roadmap (ADLC-sized issues)

### Phase 1 — Visual refresh + content (ship first)
1. **Design system pass** — Tailwind theme tokens (palette, type scale, mono font),
   DaisyUI theme config, shared components (card / pill / section / CTA), motion Stimulus
   controller.
2. **Hero + home redesign** — positioning copy, featured projects, latest writing, subtle CTA.
3. **Projects page redesign** — card grid, status filter/pill, triple-link cards,
   coming-soon/empty states.
4. **Writing redesign + content types** — `Post.kind` (Notes / Deep Dives), index + filter,
   article typography polish, reading time, tags, excerpts.
5. **About page** — fractional-architect narrative + mentorship (soft consulting signal).
6. **Medium syndication workflow** — `medium_url` field, "Also on Medium" link, runbook doc.
7. **Newsletter signup (aspirational)** — `Subscriber` model, footer + home signup, double
   opt-in, GDPR-compliant storage. No provider/sending yet — demand signal only.
8. **SEO / meta polish** — per-page OG images, JSON-LD `Person` / `Article` structured data.
9. **Legal compliance** — **Impressum + privacy policy** (legally required for a
   Berlin-based site; see §8). Dedicated ticket, not folded into another issue.
10. **Modal keyboard navigation layer (signature)** — NORMAL/COMMAND/SEARCH mode state
    machine, command registry, `f` hint-jump, keyboard-guide overlay, driving nav, theme
    switching, and search. Extensible so §6.4 metrics queries plug into COMMAND mode.
    Depends on the design-system pass (#1). See spec
    [#1187](../specs/1187-modal-vim-keyboard-navigation.md).
11. **First-party analytics** — remove GA + Metricool; add cookieless first-party event
    capture to Postgres; expose queries through the command layer. (AI Lab experiment #1.)
12. **Build-in-public** — a `/changelog` page + a site version in the footer + a
    "Rebuilding this site" **Notes series** documenting the refresh publicly.
13. **Contact CTA** — "Work with me" as a simple `mailto:` link for now; structured so it
    can grow into a form/booking flow later without a redesign.

### Phase 2 — AI Lab identity (login authority)
8. **Doorkeeper OIDC provider** — gems, `User` model + auth, signing key via Kamal secrets.
9. **Login / consent UI** — branded, on-domain.
10. **`/lab` landing (Bardic Labs)** — public directory of the lab + experiments, each with
    a d20 rating badge (Nat 1–Nat 20), sortable by roll. Visitor-ranking is a follow-on.
11. **First OIDC client integration** — wire one lab app end-to-end (auth code + PKCE).
12. **Ops hardening** — key/token rotation, rate limiting, audit logging, secrets management.

---

## 8. Open questions / to refine later
- **Bardic Labs rating scope** — owner-only vs. visitor ranking (and whether both are
  shown); if visitors rank, decide anti-abuse (auth-gated? one-vote?). Name is decided.
- **Optional:** reserve `bardiclabs.com` (or `.dev`) as defensive insurance + redirect to
  the subdomain. Not required — Bardic Labs is subdomain-first (§6.4).
- **Final social links list** — include all (GitHub, LinkedIn, Mastodon, Bluesky, etc.);
  James provides the full set before that section is built.
- **GDPR/consent specifics** — cookieless first-party analytics should minimize the need
  for a consent banner; confirm with the privacy-policy/Impressum work. German **TTDSG** +
  **GDPR** apply.
- **Hero copy** beyond the positioning line.
- **Owner-only vs public** scopes for terminal metrics queries.
- **Newsletter provider** — deferred until demand justifies it (own-DB capture until then).

---

## 9. Decision log
| Decision | Choice | Date |
|---|---|---|
| Identity architecture | Self-hosted OIDC via Doorkeeper | 2026-07-18 |
| Medium strategy | Site canonical, syndicate to Medium (POSSE) | 2026-07-18 |
| Consulting signal | Subtle — proof over pitch | 2026-07-18 |
| Build sequence | Design & content first, then identity | 2026-07-18 |
| Aesthetic | Refined terminal, warmed up | 2026-07-18 |
| Content types | Notes + Deep Dives split | 2026-07-18 |
| Positioning term | Fractional architect / CTO (not "fractal") | 2026-07-18 |
| Positioning line | "I help engineers get their systems right…" | 2026-07-18 |
| Signature typeface | Commit Mono (mono roles) + sans body | 2026-07-18 |
| Body sans | Inter | 2026-07-18 |
| Type scale | 18px base, Major Third (1.250) | 2026-07-18 |
| Theme picker | Playful terminal theme switcher (light/dark + dev schemes) | 2026-07-18 |
| Keyboard layer model | Modal NORMAL/COMMAND/SEARCH state machine (not palette + flat shortcuts); drops `Cmd/Ctrl-K`, adds mode indicator + `f` hint-jump — see spec [#1187](../specs/1187-modal-vim-keyboard-navigation.md) | 2026-07-19 |
| Bundled dev themes | Dracula, Nord, Gruvbox, Catppuccin | 2026-07-18 |
| Keyboard UX | Full keyboard command layer / site-as-terminal | 2026-07-18 |
| Newsletter | Aspirational; own-DB capture, launch on demand | 2026-07-18 |
| Analytics | Drop GA + Metricool; first-party, terminal-queryable | 2026-07-18 |
| AI Lab name | Bardic Labs (bard = mentor class), Nat 1–Nat 20 rating | 2026-07-18 |
| AI Lab domains | Subdomains (multi-machine capable), not paths | 2026-07-18 |
| Contact CTA | `mailto:` link for now, expandable later | 2026-07-18 |
| `/blog` redirect | None — clean refresh, no redirect needed | 2026-07-18 |
| Content backfill | All existing posts = Deep Dives | 2026-07-18 |
