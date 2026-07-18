<!-- GITHUB ISSUE TRACKING METADATA -->
<!-- Issue Key: bitidev/jamesebentier.com#1158 -->
<!-- Last Updated: 2026-07-18T11:45:00+02:00 -->
<!-- Description Hash: ae9eb1a584f9 -->
<!-- Spec Version: 1 -->
<!-- END METADATA -->

# Upgrade Frontend CSS and Build Toolchain Majors

**Issue:** [bitidev/jamesebentier.com#1158](https://github.com/bitidev/jamesebentier.com/issues/1158)
**Parent epic:** [#1147](https://github.com/bitidev/jamesebentier.com/issues/1147) — Upgrade all dependencies to latest versions (umbrella; **do not close #1147 when this lands — this issue only closes itself**)
**Branch:** `personal/jebentier/issue-1158-upgrade-frontend-css-build-toolchain`
**Board:** `jamesebentier.com Board` (org `bitidev` project #2) — Status: In Progress

## Overview

Three Dependabot PRs are open against `main`, each bumping a core frontend build-toolchain package by a major version — the kind of coupled visual/build change explicitly called out as a deliberate medium/large ADLC exercise, distinct from the mechanical lockfile-only Ruby-gem batches (`#1154`, `#1156`, `#1157`) and the GitHub Actions batch (`#1155`) that already landed:

| PR | Package | From → To | Nature |
|---|---|---|---|
| [#1153](https://github.com/bitidev/jamesebentier.com/pull/1153) | `tailwindcss` | 3.4.17 → 4.3.3 | CSS-first config rewrite (`tailwind.config.js` → `@theme`/`@plugin` directives in CSS); CLI moves to a separate `@tailwindcss/cli` package |
| [#1136](https://github.com/bitidev/jamesebentier.com/pull/1136) | `daisyui` | 4.12.24 → 5.6.18 | Component-library major; theme/plugin config moves from `tailwind.config.js` into the CSS `@plugin "daisyui" { ... }` block; several component class renames |
| [#1128](https://github.com/bitidev/jamesebentier.com/pull/1128) | `webpack-cli` | 5.1.4 → 7.2.1 | Two majors in one Dependabot bump; raises the CLI's own Node floor to `>=20.9.0` |

**Each raw Dependabot PR's own CI already demonstrates why this can't be a mechanical lockfile bump.** Fetched directly from GitHub (`gh run view --log`) as part of this spec's verification:

- **#1153 (`tailwindcss` alone) fails `Test`** with `cssbundling-rails: Command build failed, ensure 'yarn build:css' runs without errors` — the raw major bump breaks the build outright, because Tailwind v4 requires the CSS-first config migration described below.
- **#1136 (`daisyui` alone) passes `Test`** but fails `Lint` with the same **10 pre-existing RuboCop offenses** documented and since fixed by `#1155` — the PR was opened against a `main` commit that predates that fix, so the failure is unrelated to `daisyui` itself.
- **#1128 (`webpack-cli` alone) passes `Test`** but fails `Lint` for the identical pre-existing reason. Its `Test` pass is also useful independent evidence: GitHub's `ubuntu-latest` runner's default Node (via `actions/setup-node@v7.0.0` with no `node-version` input) already satisfies webpack-cli 7's `engines.node: >=20.9.0` floor — see the [Node version finding](#finding-node-version-floor-is-already-satisfied-everywhere) below.

This spec covers consolidating the three bumps onto this issue's branch/PR, the concrete Tailwind v4 + daisyUI v5 CSS-first config migration this app's setup requires, a genuine (and previously silently-broken) `font-awesome` import fix surfaced by the migration, and the visual/API-breakage smoke-test plan across this app's four real pages — closing out the "frontend CSS/build major" slice of the `#1147` umbrella.

## Goal

Move `tailwindcss`, `daisyui`, and `webpack-cli` to their current major versions, completing the CSS-first configuration migration this app's Tailwind/daisyUI setup requires, while keeping the visual theme and every DaisyUI-derived class this app actually uses (`link`/`link-hover`, `badge`/`badge-accent`/`badge-ghost`, `bg-base-200`, `base-content` opacity utilities, `footer-title`, the resume `collapse` block) rendering coherently — and without pulling in any Rails major or unrelated Ruby gem work, per the issue's explicit exclusions.

## In Scope

- Bump `tailwindcss` 3.4.17 → 4.3.3, `daisyui` 4.12.24 → 5.6.18, `webpack-cli` 5.1.4 → 7.2.1 (`package.json`, `yarn.lock`)
- Add `@tailwindcss/cli` (new direct dependency — the `tailwindcss` npm package no longer ships a `bin` in v4; see [Finding](#finding-tailwind-v4-cli-moves-to-a-separate-package))
- Delete `tailwind.config.js`; migrate its entire content into `app/assets/stylesheets/application.tailwind.css` using Tailwind v4's CSS-first `@theme`/`@utility`/`@source` directives and daisyUI v5's `@plugin "daisyui" { themes: ...; }` directive — see [Approach](#approach-implementation-guidance) for the exact target CSS
- Remove the dead `@import "font-awesome";` line from `application.tailwind.css` — verified non-functional today (see [Finding](#finding-the-font-awesome-import-was-already-dead-and-blocks-the-v4-build)); its removal changes zero observable behavior and unblocks the v4 build, which hard-errors on unresolvable imports where v3 silently dropped them
- Update `package.json`'s `build:css` script only if the `@tailwindcss/cli`-provided `tailwindcss` binary needs a different invocation (empirically it does not — same CLI flags work; see [Approach](#approach-implementation-guidance))
- Re-verify the four DaisyUI-derived class families this app actually uses against daisyUI 5's breaking-changes list (`link`/`link-hover`, `badge`/`badge-accent`/`badge-ghost`, `base-content`/`base-200` color utilities, `footer-title`, and the resume page's `collapse` block) — see [Finding](#finding-daisyui-5-breaking-changes-vs-this-apps-actual-class-usage)
- Consolidating all three onto the single branch/PR named above
- Closing or superseding PRs #1153, #1136, #1128 once the consolidated PR merges (orchestrator-owned GitHub operation, see [Delegation](#delegation--handoff))
- Running the full local test suite, RuboCop, both frontend builds (`yarn build:css`, `yarn build`), the full `bundle exec rake assets:precompile` pipeline, and a local-server visual/status-code smoke test across `/`, `/blog` (index + a post detail), `/projects`, `/resume`

## Out of Scope

Per the issue body, explicitly excluded from this batch (remain open work under `#1147`, or already landed separately):

- Ruby gem upgrades of any kind — patches, test/dev tooling, or runtime gems (`#1154`, `#1156`, `#1157` already landed these separately). In particular, **`font-awesome-sass` is not touched** — the [font-awesome finding](#finding-the-font-awesome-import-was-already-dead-and-blocks-the-v4-build) is fixed entirely on the CSS-import side, with zero `Gemfile`/`Gemfile.lock` change
- GitHub Actions workflow dependency bumps (`#1155` already landed these)
- Rails major upgrade (`rails` stays pinned `~> 7.1.3, >= 7.1.3.4`) — `#1159` (Rails 8) stays in Backlog until this issue lands, per product triage
- The `resume/` subdirectory's Docker image build (a separate, non-npm resume-rendering pipeline with no `package.json` of its own — confirmed by direct inspection; entirely unaffected by this work)
- Adding a dark-mode theme toggle or any other new feature. `dark` stays enabled in the daisyUI `themes` list only because it was already enabled pre-upgrade (`daisyui: { themes: ["light", "dark"] }` in the old config) — this spec preserves that exact set, it does not add new theming behavior. The app has no theme-switcher UI in either state (`data-theme='light'` is hardcoded in the layout; no `theme-controller` class or Stimulus controller anywhere in `app/javascript/`)
- The Heroku→Linode/Kamal infrastructure migration tracked elsewhere — unrelated, separate workstream

**Hard quarantine:** this work touches only `bitidev/jamesebentier.com`. Never touch `jb-brown` / `Invoca-ADLC` remotes, and never frame any part of this as an upstream ADLC contribution.

## Current State (Verified)

Verified directly against the repo (worktree branched from `main` tip, which already includes `#1154`, `#1155`, `#1156`, `#1157`, and `#1160` merged) and GitHub as of 2026-07-18.

- **`package.json` shows all three packages still at their pre-upgrade ("From") version**: `tailwindcss": "^3.4.17"`, `"daisyui": "^4.12.24"`, `"webpack-cli": "^5.1.4"` — confirmed by direct inspection.
- **`tailwind.config.js`** uses the v3 JS-config shape: a `content` array (`app/views/**/*.html.erb`, `app/helpers/**/*.rb`, `app/assets/stylesheets/**/*.css`, `app/javascript/**/*.js`), a `theme.extend` block defining two custom `fontFamily` keys (`sans-serif`, `resume`) and one custom `listStyleType` key (`square`), and a `plugins` array loading `@tailwindcss/typography` and `daisyui` with `daisyui: { themes: ["light", "dark"] }`.
- **`app/assets/stylesheets/application.tailwind.css`** uses the v3 `@tailwind base/components/utilities` directive trio, an `@import "font-awesome";` line, and a `.prose` block with native CSS nesting (`&::after`) for blog-post image captions.
- **No `postcss.config.js` exists anywhere in the repo** — `postcss` and `autoprefixer` are listed in `package.json` but are not referenced by any config file; `cssbundling-rails`' `yarn build:css` script invokes the `tailwindcss` CLI binary directly (`tailwindcss -i ... -o ... --minify`), which historically bundled its own internal PostCSS pipeline (including `postcss-import`). Neither package is a hard requirement for the v4 CLI (v4's CLI has its own bundler and built-in vendor-prefixing), and this spec does not require removing them — see [R6](#requirements).
- **`@tailwindcss/typography@0.5.20`'s own `peerDependencies`** already declare `"tailwindcss": ">=3.0.0 || >=4.0.0 || insiders"` (confirmed via `npm view`) — no version bump needed for this package, only its plugin-registration syntax changes (from `require("@tailwindcss/typography")` in the JS `plugins` array to `@plugin "@tailwindcss/typography";` in CSS).
- **`webpack-cli@7.2.1`'s `engines.node` is `>=20.9.0`**, and its `peerDependencies.webpack` is `^5.101.0` — this repo's `webpack` (`^5.108.4`) already satisfies that floor; no `webpack` version change needed.
- **Node version is pinned in two places, both already >= webpack-cli 7's floor**: `.nvmrc` → `lts/iron` (Node 20.x) and the `Dockerfile`'s `ARG NODE_VERSION=20.14.0` — both satisfy `>=20.9.0`. See [Finding](#finding-node-version-floor-is-already-satisfied-everywhere).
- **This app's only actual DaisyUI-derived class usage**, catalogued by grepping every file under `app/views/`, `app/helpers/`, and `lib/blog/renderer.rb` for class attributes: `link`/`link-hover` (nav + resume links), `badge`/`badge-accent`/`badge-ghost` (project status badge, blog post tag/category badges), `bg-base-200` / `border-base-content/10` / `text-base-content/60` / `text-base-content/70` (footer), `footer-title` (footer section headings), and a `collapse` class on the resume's work-experience accordion (paired with a custom Stimulus controller — not daisyUI's own collapse *behavior*, just borrowing the base class name for the initial-collapsed layout). `.prose` (blog post body, `@tailwindcss/typography`) and two custom `theme.extend` keys (`font-sans-serif`, `font-resume`, `list-square`) round out the full set of non-default Tailwind/daisyUI surface this app depends on. No page uses `btn`, `card`, `modal`, `dropdown`, `navbar`, `input`, `select`, `avatar`, `bottom-nav`/`btm-nav`, `form-control`, `menu` item-state classes, or any other daisyUI 5 breaking-change target (see [Finding](#finding-daisyui-5-breaking-changes-vs-this-apps-actual-class-usage)).
- **Direct empirical scratch verification performed for this spec** (a full `yarn add tailwindcss@4.3.3 daisyui@5.6.18 webpack-cli@7.2.1 @tailwindcss/cli@4.3.3` + config migration in this worktree, fully built, tested, boot-checked, and then **fully reverted via `git checkout -- .`** — no trace left in the branch):
  - The raw v4 bump, before any config migration, reproduces the exact same `Error: Can't resolve 'font-awesome'` / `cssbundling-rails: Command build failed` failure #1153's own Dependabot CI already shows.
  - After the CSS-first config migration ([Approach](#approach-implementation-guidance)) and the `font-awesome` import removal: `yarn build:css` succeeds (`≈ tailwindcss v4.3.3` / `🌼 daisyUI 5.6.18`), `yarn build` succeeds (`webpack 5.108.4 compiled successfully`), and a full `RAILS_ENV=test bundle exec rake assets:precompile` succeeds end-to-end with zero errors.
  - The compiled `application.css` was inspected directly and confirmed to contain: working `.font-sans-serif`/`.font-resume` utilities (`font-family:var(--font-sans-serif)` / `var(--font-resume)`), a working `.list-square` utility, both `[data-theme=light]` and `[data-theme=dark]` daisyUI theme blocks, a correctly-generated `.badge-accent` rule (`--badge-color:var(--color-accent)`), 79 occurrences of `base-content`-derived utilities, and the `.prose img::after{...content:attr(alt);...}` nesting rule compiled exactly as before (Tailwind v4 has native nesting support, matching the pre-upgrade v3 output shape).
  - `bundle exec rake spec`: **56 examples, 0 failures, 3 pending** — identical pass/fail shape to pre-upgrade baseline (the two extra passing examples vs. `#1157`'s 34-example baseline are from `#1160`'s Kamal/Postgres work landing since).
  - `bundle exec rubocop`: **58 files inspected, no offenses detected** — clean, matching the post-`#1155` baseline.
  - A local `bin/rails server` boot, hit with `curl`, confirmed `/`, `/blog`, `/projects`, `/resume` **and** a real blog-post detail page all return `200`, that the compiled `<link rel="stylesheet" href="/assets/application-....css">` tag loads (`200`), and that the blog-post detail page's rendered HTML still contains `class="badge badge-accent"` / `class="badge badge-ghost"` exactly as authored. (`/projects` returned `200` with an empty listing in this dev DB — a pre-existing, unrelated data-seeding gap, not a build regression; there is no `/projects/:id` to spot-check without seed data. Confirm project-detail smoke-check separately with real dev data before merging — see [Open Question](#open-questions) Q1.)
  - All scratch changes (`package.json`, `yarn.lock`, `.yarn/install-state.gz`, `tailwind.config.js` deletion, `application.tailwind.css`) were reverted via `git checkout -- .` before this spec was written; the worktree is clean and still on `tailwindcss 3.4.17` / `daisyui 4.12.24` / `webpack-cli 5.1.4` as of this writing.

### Finding: Tailwind v4 CLI Moves to a Separate Package

`tailwindcss@4.3.3`'s own `package.json` has **no `bin` field at all** (confirmed via `npm view tailwindcss@4.3.3 bin`, which returns nothing) — the CLI that `tailwindcss -i ... -o ...` resolves to in v3 no longer exists in the `tailwindcss` package in v4. It moved to a new package, `@tailwindcss/cli`, which declares `tailwindcss` itself as a dependency and provides the `tailwindcss` executable. This is a **required additive `package.json` dependency**, not just a version bump: without adding `@tailwindcss/cli`, `yarn build:css`'s `tailwindcss` binary resolves to nothing and the script fails to even start. Confirmed empirically: `yarn add tailwindcss@4.3.3 daisyui@5.6.18 webpack-cli@7.2.1 @tailwindcss/cli@4.3.3` correctly links `node_modules/.bin/tailwindcss` to `@tailwindcss/cli`'s binary, and the existing `build:css` script (`tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css --minify`) needs **no argument changes** — same flags, same behavior, different package providing the binary. (This project uses the CLI directly, not the PostCSS plugin path — since there is no `postcss.config.js`, `@tailwindcss/postcss` is not needed.)

### Finding: The `font-awesome` Import Was Already Dead — and Blocks the v4 Build

This is the single most important finding in this spec, and the concrete reason the raw Dependabot bump (#1153) fails CI.

`application.tailwind.css` contains `@import "font-awesome";`, intended to pull in the `font-awesome-sass` gem's icon-font CSS (`font-awesome-sass (6.7.2)` in `Gemfile.lock`, providing the classic `.fa-solid`/`.fa-brands` icon-font classes used throughout the app's `<i class="fa-solid fa-...">` markup). **Empirically verified this import has already been non-functional in production for some time, independent of this upgrade**:

- Running the **current, unmodified v3** `RAILS_ENV=test bundle exec rake assets:precompile` and inspecting the final compiled `public/assets/application-*.css` shows **zero occurrences** of `@import`, `.fa-solid`, `.fa-brands`, or any `@font-face` rule. The 52 KB compiled file starts directly with Tailwind's reset layer — the import is silently dropped somewhere in the v3 Tailwind-CLI-then-Sprockets pipeline (neither stage resolves a bare `"font-awesome"` specifier to an actual gem-provided stylesheet path), and no error is raised for it either.
- The gem's own `FontAwesome::Sass::Rails::Engine` unconditionally adds its `.woff2`/`.ttf` font files to `config.assets.precompile` regardless of whether anything imports its CSS — which is why `public/assets/font-awesome/fa-solid-900-*.woff2` etc. **do** get precompiled every time, creating a misleading appearance that the import "does something." It does not: no CSS rule ever references those font files in the compiled output.
- The actual, functioning icon-rendering mechanism in production is the **Font Awesome Kit script** already loaded directly in `app/views/layouts/application.html.erb` (`<script src="https://kit.fontawesome.com/d7b2096eb7.js" ...>`), which client-side-replaces every `<i class="fa-solid fa-...">` with an inline SVG. This is completely independent of the Sass gem's CSS.
- Under **Tailwind v4**, unresolvable `@import` specifiers are a **hard build error** (`Error: Can't resolve 'font-awesome' in '.../app/assets/stylesheets'`) rather than v3's silent drop — this is the exact, reproducible cause of `#1153`'s Dependabot CI failure (`cssbundling-rails: Command build failed, ensure 'yarn build:css' runs without errors`).

**Fix, verified empirically**: delete the `@import "font-awesome";` line from `application.tailwind.css`. This is not a workaround or a scope-creeping feature removal — it removes a statement that was already a no-op, and doing so is the change that unblocks the v4 build. No `Gemfile` change, no icon-rendering behavior change (the Kit script is untouched and remains the sole functioning icon mechanism), no `manifest.js`/layout change needed. (An earlier draft of this scratch verification tried preserving the import via a second, separately-linked Sprockets-only stylesheet — that approach was abandoned once the "already dead" finding above was confirmed, since it would have kept dead code alive through extra plumbing for zero behavioral benefit.)

### Finding: DaisyUI 5 Breaking Changes vs. This App's Actual Class Usage

DaisyUI 5's own upgrade guide lists roughly 15 HTML/class breaking changes. Checked each against this app's real class usage (catalogued in [Current State](#current-state-verified)):

| DaisyUI 5 breaking change | Affects this app? |
|---|---|
| `card-bordered` → `card-border`, `card-compact` → `card-sm` | No — no `card` usage anywhere |
| `form-control` removed (use `fieldset`/`label`) | No — no forms in this app at all |
| `btn-group`/`input-group` removed (use `join`) | No — no `btn` or input-group usage |
| `bottom-nav`/`btm-nav-*` → `dock`/`dock-*` | No — no bottom-nav usage |
| `online`/`offline`/`placeholder` avatar classes renamed | No — no `avatar` usage |
| Menu item state classes (`active`/`disabled`/`focus` → `menu-active`/`menu-disabled`/`menu-focus`) | No — no `menu` usage |
| Inputs/selects/file-inputs now bordered by default (`*-ghost` to remove) | No — no form-input usage |
| Removed `artboard`/`phone-*` sizing classes | No — no usage |
| Automatic `*-content` color calculation removed (theme variables now plain CSS custom properties) | **Potentially relevant to `badge-accent`/`base-content`**, but verified harmless: this app never overrides or reads daisyUI's internal color-calculation output directly — it only *consumes* the resulting utility classes (`badge-accent`, `text-base-content/NN`), which the scratch build confirms still compile to correct, themed values (`--badge-color:var(--color-accent)`, `base-content`-derived utilities present 79× in the built CSS) |
| `themes`/`darkTheme`/`themeRoot` config keys renamed and moved into CSS | **Directly relevant** — handled by the `@plugin "daisyui" { themes: light --default, dark; }` migration in [Approach](#approach-implementation-guidance) |

**Conclusion: no HTML/view-file class renames are required in this app.** The only daisyUI-5-driven change needed is the config migration itself (JS `daisyui: { themes: [...] }` → CSS `@plugin "daisyui" { themes: ...; }`), which the scratch build's compiled-CSS inspection (both `[data-theme=light]` and `[data-theme=dark]` blocks present, `badge-accent` correctly generated) confirms works end-to-end. The resume page's `collapse` class is a plain daisyUI structural/layout class (not driving daisyUI's own JS-free collapse-toggle *behavior*, which this app implements itself via the `collapse_controller.js` Stimulus controller toggling a `hidden` class) — daisyUI 5's changelog does not list `collapse` among its removed/renamed components, and the scratch visual smoke test's blog/resume page checks did not surface any layout regression.

### Finding: Node Version Floor Is Already Satisfied Everywhere

`webpack-cli@7.2.1` declares `"engines": {"node": ">=20.9.0"}`. Three independent places this matters, all already satisfied:

1. **Local dev machine**: `node -v` → `v24.11.0`. Satisfied.
2. **CI**: `.github/workflows/ci.yml`'s `Test` job uses `actions/setup-node@v7.0.0` with **no `node-version` input** — per `actions/setup-node`'s own documentation, this means "the node version from PATH will be used" (i.e., whatever Node ships pre-installed on the `ubuntu-latest` runner image). Rather than treating this as an unverified risk, this spec found **direct empirical proof it's already fine**: `#1128` (the raw `webpack-cli`-only Dependabot PR, already using `webpack-cli@7.2.1` today) shows its own `Test` job **passed** on this exact CI configuration (`gh pr view 1128 --json statusCheckRollup` → `Test: SUCCESS`). No CI change needed.
3. **Deploy targets**: `.nvmrc` (`lts/iron` = Node 20.x) and the `Dockerfile`'s `ARG NODE_VERSION=20.14.0` both satisfy `>=20.9.0` directly.

No Node-version-related change is required anywhere in this PR.

## Requirements

1. **R1 — Dependency bumps land on `main`.** `tailwindcss` reaches `4.3.3`, `daisyui` reaches `5.6.18`, `webpack-cli` reaches `7.2.1` in `package.json`/`yarn.lock`, via one consolidated PR from this issue's branch. `@tailwindcss/cli` is added as a new direct dependency at a matching `4.3.3` (or newer patch within the same major, kept in lockstep with `tailwindcss`).
2. **R2 — CSS-first config migration is complete, not partial.** `tailwind.config.js` is deleted. Every piece of its content (the `content` glob array — now unnecessary, v4 auto-detects; the two `fontFamily` keys; the `listStyleType` key; the `@tailwindcss/typography` and `daisyui` plugin registrations; the `daisyui.themes` array) is represented in `app/assets/stylesheets/application.tailwind.css` using v4's `@theme`, `@utility`, `@source`, and `@plugin` directives, per [Approach](#approach-implementation-guidance). After migration, every utility class this app's views/helpers reference (`font-sans-serif`, `font-resume`, `list-square`, all daisyUI classes catalogued in [Current State](#current-state-verified)) must compile to a real, non-empty CSS rule — verified by grepping the built `application.css`, not just by the build exiting 0.
3. **R3 — The dead `font-awesome` import is removed, not worked around.** Per the [finding](#finding-the-font-awesome-import-was-already-dead-and-blocks-the-v4-build), delete `@import "font-awesome";` from `application.tailwind.css`. Do not introduce a second stylesheet, a `manifest.js` change, or a layout change to "preserve" it — it was already inert, and doing so would add dead-code-adjacent plumbing with zero behavioral benefit, unrelated to this issue's scope.
4. **R4 — Both frontend builds succeed cleanly.** `yarn build:css` (Tailwind v4 CLI, via the new `@tailwindcss/cli` binary) and `yarn build` (webpack via webpack-cli 7) both exit 0 with no errors, and `bundle exec rake assets:precompile` (the exact command CI's `Test` job runs) succeeds end-to-end.
5. **R5 — No scope creep.** The consolidated PR's diff touches only: `package.json`, `yarn.lock`, `.yarn/install-state.gz`, the deletion of `tailwind.config.js`, and `app/assets/stylesheets/application.tailwind.css`. No `Gemfile`/`Gemfile.lock` change, no Rails version change, no unrelated view/controller/model changes, no CI workflow change. (`app/assets/builds/*` and `public/assets/*` are build artifacts regenerated by CI/deploy, not hand-committed as part of this PR, consistent with this repo's existing `cssbundling-rails`/`jsbundling-rails` convention.)
6. **R6 — `postcss`/`autoprefixer` are left untouched.** They are unused today (no `postcss.config.js` exists) and are not required by Tailwind v4's CLI path used here; removing them is a legitimate future cleanup but is out of scope for this PR (would be scope creep beyond the three named packages). Do not remove them as part of this work unless they turn out to actually break the v4 build (not observed in this spec's verification).
7. **R7 — DaisyUI 5 class-usage audit is honored.** Per the [finding](#finding-daisyui-5-breaking-changes-vs-this-apps-actual-class-usage), no view-file class renames are needed. If the code agent's own implementation surfaces daisyUI classes not caught by this spec's grep-based catalogue (e.g., a class embedded in a Ruby string interpolation this spec's static search missed), re-check it against daisyUI 5's [upgrade guide](https://daisyui.com/docs/upgrade/) before proceeding.
8. **R8 — Visual smoke test across all four real pages plus one dynamic detail page.** Boot the app locally (or via a deploy preview) and confirm, with real dev/seed data where possible: `/` (home), `/blog` (index) **and** at least one blog post detail page, `/projects` (index) **and**, if seed data supports it, a project detail page, and `/resume` all render with layout/theme coherent — no missing badge/link/footer styling, no visibly broken daisyUI theme colors. This spec's own scratch verification covered `/`, `/blog`, a blog-post detail page, `/projects` (index only — no seeded project rows in this dev DB), and `/resume`, all `200` with expected classes present in the rendered HTML; a project-detail-page check needs real data (see [Open Question](#open-questions) Q1).
9. **R9 — CI green.** Given the lint-debt baseline is clean as of `#1155` (confirmed: `58 files inspected, no offenses detected` in this spec's own verification pass), the consolidated PR is expected to pass `lint`, `test`, and `ci-gate` without any pre-existing-failure caveat.
10. **R10 — Dependabot PRs consolidated.** Once the consolidated PR merges, #1153, #1136, and #1128 are closed as superseded (orchestrator-owned; see [Delegation](#delegation--handoff)). #1147 remains open; #1158 closes itself.

## Approach (Implementation Guidance)

This section is spec-level guidance for the **code** agent / implementer — not a substitute for their own verification. The exact target CSS below was built and verified in this spec's own scratch pass; it is a strong starting point, not a rubber stamp.

1. Confirm working in the issue worktree (`personal/jebentier/issue-1158-upgrade-frontend-css-build-toolchain`), branched from current `main` (which already includes `#1154`/`#1155`/`#1156`/`#1157`/`#1160`).
2. Add the four packages: `yarn add tailwindcss@4.3.3 daisyui@5.6.18 webpack-cli@7.2.1 @tailwindcss/cli@4.3.3`. Diff `yarn.lock` and confirm the version movement matches [Current State](#current-state-verified) (plus their own transitive dependencies — `@tailwindcss/cli` alone pulls in ~30 new transitive packages: `@tailwindcss/node`, `@tailwindcss/oxide`, `@parcel/watcher`, `enhanced-resolve`, etc. — this is expected and not scope creep).
3. Delete `tailwind.config.js`.
4. Rewrite `app/assets/stylesheets/application.tailwind.css` to:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";
@plugin "daisyui" {
  themes: light --default, dark;
}

@source "../../helpers";

@theme {
  --font-sans-serif: Montserrat, sans-serif;
  --font-resume: "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
}

@utility list-square {
  list-style-type: square;
}

.prose {
  img {
    @apply rounded-lg mx-auto;
    max-width: 50%;
    &::after {
      @apply block text-center text-sm text-gray-500;
      content: attr(alt);
    }
  }

  img[src*='#left'] {
    float: left;
    margin-right: 2rem;
    max-width: 33%;
  }
  img[src*='#right'] {
    float: right;
    margin-left: 2rem;
    max-width: 33%;
  }
}
```

   Notes on each piece, mapped back to the old `tailwind.config.js`:
   - `@import "tailwindcss";` replaces the old `@tailwind base/components/utilities` trio (v4's single-import model).
   - `@plugin "@tailwindcss/typography";` replaces `require("@tailwindcss/typography")` in the old `plugins` array.
   - `@plugin "daisyui" { themes: light --default, dark; }` replaces `require("daisyui")` + `daisyui: { themes: ["light", "dark"] }`. `light --default` preserves the old implicit "first theme in the array is default" behavior explicitly; `dark` stays listed (available via `data-theme="dark"`) purely because it was already in the old array — this app has no theme switcher, so this is a no-behavior-change carryover, not new theming work.
   - The old `content` array is dropped entirely — v4 auto-detects content by scanning the project. The one path from the old array that isn't automatically covered by v4's default heuristics with confidence (`./app/helpers/**/*.rb`, needed for `resume_helper.rb`'s `style_for_level` method, which returns literal Tailwind class strings like `'after:bg-[#59C596] after:w-full'`) is made explicit via `@source "../../helpers";` (path is relative to the CSS file's own directory, `app/assets/stylesheets/`). `lib/blog/renderer.rb`'s literal classes (`text-3xl font-bold mb-4`, etc.) don't need an explicit `@source` — v4's default heuristic scans the whole project (respecting `.gitignore`) starting from the CSS file's directory upward to the project root, so `lib/` is covered without extra configuration; this was not true under the old v3 `content` array (which didn't list `lib/`), but those exact classes happened to already be scanned via identical literal strings elsewhere in `app/views/` — confirmed as a real, if incidental, existing safety net, not a new risk introduced by this migration.
   - `@theme { --font-sans-serif: ...; --font-resume: ...; }` replaces the old `theme.extend.fontFamily` block — v4's `--font-*` namespace generates a `.font-{key}` utility per key, exactly matching the old `fontFamily: { 'sans-serif': [...], 'resume': [...] }` → `.font-sans-serif`/`.font-resume` behavior.
   - `@utility list-square { list-style-type: square; }` replaces the old `theme.extend.listStyleType.square` key (which generated a `.list-square` utility under v3's `listStyleType` theme scale). v4 has no equivalent `listStyleType` theme namespace with a matching JS-config-free CSS-first mapping — the direct custom-utility form (`@utility`) is a spec-level judgment call, verified to compile correctly (`.list-square{list-style-type:square}` present in the built CSS) and used only once in `_work_experience.html.erb`'s `list-square` class.
   - `@import "font-awesome";` is **deleted**, not migrated — per [R3](#requirements).
   - The `.prose` nesting block is otherwise **unchanged** from the current file — v4 has native CSS-nesting support built in, and the scratch verification confirmed the `&::after` rule compiles identically to before.
5. Confirm `package.json`'s `build:css` script needs **no changes** — `tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css --minify` continues to work once `@tailwindcss/cli` provides the `tailwindcss` binary.
6. Run `yarn build:css` and `yarn build`. Both must exit 0. Inspect the built `app/assets/builds/application.css` for the specific class/utility presence checks in [Current State](#current-state-verified) (`.font-sans-serif`, `.font-resume`, `.list-square`, `[data-theme=light]`/`[data-theme=dark]`, `.badge-accent`, `base-content`-derived utilities, `.prose img::after`) before moving on — an exit-0 build with silently-empty/missing utilities is a false-positive success.
7. Run `rm -rf public/assets && RAILS_ENV=test SECRET_KEY_BASE=<any> bundle exec rake assets:precompile` (the exact CI `Test`-job command) and confirm it completes without error.
8. Run `bundle exec rake spec` and `bundle exec rubocop` for before/after parity. Both are expected to pass cleanly (56 examples / 0 failures / 3 pending; 0 RuboCop offenses across 58 files) per [Current State](#current-state-verified) — investigate before proceeding if either regresses.
9. Boot `bin/rails server` (or `bin/dev`, which also starts the `yarn build --watch` / `yarn build:css --watch` processes per `Procfile.dev`) and visually check `/`, `/blog` (index + a post detail page), `/projects`, `/resume`. Confirm the badge/link/footer daisyUI styling and the resume page's theme colors and collapsible work-experience sections all render coherently, matching the pre-upgrade visual baseline. If dev-DB seed data supports it, also check a `/projects/:id` detail page (this spec's own pass had no seeded projects locally — see [Open Question](#open-questions) Q1).
10. Open the consolidated PR against `main` from the issue branch. In the PR description: reference all three superseded Dependabot PRs (`Supersedes #1153, #1136, #1128`) and this issue (`Closes #1158`); reference the parent epic non-destructively (`part of #1147` / `relates to #1147` — **never** `closes`/`fixes`/`resolves #1147`); document the CSS-first config migration and the font-awesome-import removal with links back to this spec's findings so the reviewer has the "why" up front, not just a config diff.
11. Once merged, hand off to the orchestrator for GitHub Issues lifecycle operations (closing #1153, #1136, #1128 as superseded, closing #1158, leaving #1147 open) — the scribe/code agents do not perform these operations directly.

## Acceptance Criteria

Mapped from the issue body, sharpened with this spec's findings:

- [ ] `tailwindcss` reaches `4.3.3`, `daisyui` reaches `5.6.18`, `webpack-cli` reaches `7.2.1` in `package.json`/`yarn.lock` — via one consolidated PR; `@tailwindcss/cli` is added as a new dependency
- [ ] `tailwind.config.js` is deleted; its full content is represented in `application.tailwind.css` via v4 CSS-first directives (R2)
- [ ] `yarn build:css` and `yarn build` both succeed; `bundle exec rake assets:precompile` succeeds end-to-end (matches CI's `Test` job command)
- [ ] The dead `@import "font-awesome";` line is removed, not worked around (R3)
- [ ] `lint`, `test`, and `ci-gate` are all green on the consolidated PR
- [ ] Visual smoke test confirms `/`, `/blog` (index + a post detail page), `/projects`, `/resume` all render with coherent layout/theme — DaisyUI class/API breakage addressed (no view-file class renames were found to be needed per the [daisyUI 5 finding](#finding-daisyui-5-breaking-changes-vs-this-apps-actual-class-usage), but the rendered pages must still be visually confirmed, not just status-code-checked)
- [ ] Tailwind v4 migration steps (config → CSS, CLI package split, `@source` for helper-file class strings) are completed per this repo's actual setup, not a generic migration-guide checklist
- [ ] No Rails major or unrelated Ruby gem major present in this PR's diff; `Gemfile`/`Gemfile.lock` are untouched
- [ ] #1153, #1136, #1128 are closed/superseded once the consolidated PR merges; #1147 remains open (referenced non-destructively only); #1158 closes itself

## Delegation / Handoff

Per [universal-agent-rules.md Rule 10](../../adlc/methods/universal-agent-rules.md#rule-10-delegation-patterns) and the scribe's own delegation rules:

- **Implementation** (running `yarn add`, the CSS-first config migration, both frontend builds, the asset-precompile/test/rubocop verification passes, the visual smoke test, opening the PR): delegate to the **code** agent.
- **GitHub Issues lifecycle** (closing #1153/#1136/#1128 as superseded, transitioning #1158, leaving #1147 open, board status): delegate to the **orchestrator** — this spec does not perform those operations. See [delegating-github-issues-to-orchestrator.md](../../adlc/methods/universal/delegating-github-issues-to-orchestrator.md).
- **The Q1 project-detail-page seed-data judgment call**: a decision for the orchestrator/user, not the scribe — see [Open Questions](#open-questions).

## Open Questions

1. **Does `/projects/:id` need a real, seeded-data visual check before this PR merges, or is the index-page-only check (`/projects` returns `200` with an empty list) sufficient?** This spec's own scratch verification found the local dev database has no seeded `Project` rows, so no project detail page could be smoke-tested end-to-end — this is a pre-existing dev-data gap, unrelated to this upgrade, not a regression it introduces. `/projects/show.html.erb`'s only daisyUI-derived class (`badge badge-accent`) is already confirmed working elsewhere (the blog post detail page uses the identical `badge`/`badge-accent` pattern and rendered correctly in this spec's live boot check). This spec recommends treating the blog-post-detail-page confirmation as sufficient proof that `badge`/`badge-accent` survives the upgrade, with a full `/projects/:id` check performed opportunistically (e.g., against a review-app or staging deploy with real data) rather than as a hard pre-merge blocking gate — but does not decide this unilaterally; confirm with the user/orchestrator if a stricter pre-merge check is wanted.
2. **Should `postcss`/`autoprefixer` be removed from `package.json` as a fast-follow cleanup, now that this spec has confirmed neither is referenced by any config file and Tailwind v4's CLI path doesn't need them?** [R6](#requirements) explicitly keeps this out of scope for this PR to avoid scope creep beyond the three named packages, but flags it here as a natural, low-risk follow-up once this PR lands — worth a quick confirmation with the user on whether to fold it into this PR anyway (it's a 2-line, zero-risk removal) or track it as a separate tiny issue.
3. **Is the `@utility list-square { list-style-type: square; }` custom-utility form the intended long-term pattern for this app's remaining `theme.extend`-style customizations, or would the user prefer defining it as a plain, non-Tailwind CSS rule directly in the same file (since it's used in exactly one place, `_work_experience.html.erb`)?** Both are empirically equivalent in output; this spec chose the `@utility` form to preserve the old config's intent (a reusable, Tailwind-namespaced utility class) rather than a one-off inline style, but it's a judgment call worth surfacing rather than assuming silently, since v4's CSS-first model offers both options where v3's JS config effectively forced the utility form.

## Changelog

### Version 1 - 2026-07-18
**Source Issue:** bitidev/jamesebentier.com#1158
**Change Type:** Major (initial specification)

**Changes:**
- Initial specification created for consolidating Dependabot PRs #1153 (tailwindcss), #1136 (daisyui), #1128 (webpack-cli) into one coupled visual/build major-bump PR
- Performed direct empirical verification (scratch `yarn add` + full CSS-first config migration in this worktree, fully reverted before writing this spec) of all three packages against this app's actual views, helpers, and build pipeline — not just Dependabot's own CI history
- Pulled and analyzed the raw Dependabot PRs' own CI failure logs directly from GitHub, confirming `#1153`'s `Test` failure is caused by exactly the `font-awesome` import issue this spec documents, and that `#1136`/`#1128`'s `Lint` failures are unrelated pre-existing lint debt (already fixed by `#1155` on current `main`)
- Discovered and documented the most significant finding of this migration: the `@import "font-awesome";` line in `application.tailwind.css` was already fully non-functional under v3 (verified via direct inspection of the current compiled `application.css`, which contains zero trace of it), and Tailwind v4's stricter import resolution turns that pre-existing dead code into a hard build failure — resolved by deleting the line, not by preserving it through extra plumbing
- Verified `@tailwindcss/cli` must be added as a new direct dependency, since `tailwindcss@4.3.3` itself ships no CLI binary
- Catalogued every DaisyUI-derived class this app actually uses (`link`/`link-hover`, `badge`/`badge-accent`/`badge-ghost`, `base-content`/`base-200` utilities, `footer-title`, resume `collapse`) against daisyUI 5's full breaking-changes list and confirmed zero view-file class renames are required — the only required daisyUI 5 change is the CSS-first config migration itself
- Verified webpack-cli 7's Node `>=20.9.0` engine floor is already satisfied locally, in CI (via direct evidence from `#1128`'s own passing `Test` job), and in both deploy-target Node pins (`.nvmrc`, `Dockerfile`)
- Built and verified the complete target `application.tailwind.css` (CSS-first `@theme`/`@utility`/`@source`/`@plugin` directives), confirming every migrated utility (`font-sans-serif`, `font-resume`, `list-square`, both daisyUI theme blocks, `badge-accent`, `base-content` utilities, `.prose` nesting) compiles to a real, correct CSS rule in the built output — not just a green build exit code
- Ran the full test suite (56 examples / 0 failures / 3 pending) and RuboCop (0 offenses / 58 files) against the upgraded toolchain, and booted a local server to confirm `/`, `/blog`, a blog-post detail page, `/projects`, and `/resume` all return `200` with expected daisyUI classes intact in the rendered HTML
- Flagged the `/projects/:id` seed-data gap, the `postcss`/`autoprefixer` cleanup opportunity, and the `@utility` vs. inline-CSS judgment call as open questions rather than deciding them unilaterally

**Impact:** No code changes yet; this is the planning artifact ahead of implementation by the code agent.

---
