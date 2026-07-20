# keyboard-navigation

> Per-subsystem deep-dive doc. One file per subsystem under `docs/architecture/sub-systems/`. Linked from `docs/architecture/overview.md`.

---

## Purpose

Modal, vim/neovim-style keyboard navigation for the public site: a `g`-prefix jump layer
(`gg`/`gh`/`gw`/`gp`/`gl`), `f` hint-jump link labelling, `:` COMMAND mode, `/` SEARCH mode,
and `t` theme cycling — plus the JSON search-index endpoint those modes consume. The subsystem
owns the modal-input state machine and its on-page chrome (command bar, status line, hint
overlay, guide dialog); it renders no site content of its own. Spec:
[`docs/specs/1187-modal-vim-keyboard-navigation.md`](../../specs/1187-modal-vim-keyboard-navigation.md).

---

## Anchor Files

- `app/javascript/controllers/keyboard_nav_controller.js` — the Stimulus controller; the single
  place that touches the real DOM (`getBoundingClientRect`/`.click`) and holds the `g`-prefix
  sequence buffer and mode state. Read this first.
- `app/javascript/keyboard_nav/commands.js` — the COMMAND-mode registry contract (the documented
  extension point for future commands).
- `app/controllers/search_index_controller.rb` — the server side: what SEARCH mode is allowed to
  see.

---

## Public Contract

- **Route**: `GET /search-index.json` (`SearchIndexController#index`) — a JSON array of
  `{ title, url, excerpt, tags, type }` for published Posts + all Projects. Title/description/tags
  only; never rendered-HTML body content.
- **DOM contract**: navigable targets are declared server-side via `data-nav-target` attributes
  (canonical URLs come from Rails route helpers in `_header.html.erb`, never literal path strings
  in JS). `resolveNavTarget` reads these.
- **Layout chrome partials**: `_keyboard_command_bar`, `_keyboard_status_line`,
  `_keyboard_hint_overlay`, `_keyboard_guide_dialog` — rendered by web-presentation's layout.
- **Pure helpers** (DOM-free, unit-tested): `nextTheme`/`THEME_CYCLE_ORDER` (theme_cycle.js),
  `assignHintLabels` (hints.js), `rankSearchResults`/`fetchSearchIndex` (search_index.js),
  `COMMAND_REGISTRY`/`findCommand`/`parseCommand`/`rankCommands` (commands.js).

---

## Key Invariants

- **One DOM owner.** Only `keyboard_nav_controller.js` dereferences real elements
  (`getBoundingClientRect`, `.click`, focus). Every other module is a pure function taking data
  and returning data — the testability seam that lets the unit tests run without jsdom.
- **URLs are declared once, server-side.** No module holds a literal path string; nav targets
  resolve through `data-nav-target`/route helpers. A key with no matching target is a documented
  no-op (`null`), not a broken link.
- **Forgiving on unexpected input.** Unknown `g`-sequences clear silently after
  `G_PREFIX_TIMEOUT_MS` (600ms); an unrecognized theme falls back to the first in the cycle —
  never throw, matching vim's no-error-on-unknown-sequence convention.
- **Theme cycle order is single-source.** `THEME_CYCLE_ORDER` must match the theme-picker
  `<select>` option order in `_header.html.erb` exactly.

## Security Posture

- **Trust boundary**: Public, unauthenticated surface. The search-index endpoint is world-readable
  by design; keyboard input is local to the browser. No privileged action is reachable via any key
  binding.
- **Sensitive data handled**: None. The search index is built only from already-public Post/Project
  fields.
- **Log hygiene**: No custom logging; `SearchIndexController` relies on default Rails request logs
  (no bodies, no PII).
- **Encryption posture**: Served over HTTPS in production like the rest of the site; nothing
  encrypted at rest (all content is public).
- **Known risks**: SEARCH mode deliberately excludes rendered-HTML bodies (Decision 3) — keep it
  that way; do not widen the serialization to include `Post#content`/`Project#content`.

---

## State Owned

- **Modal input state** — current mode (NORMAL/COMMAND/SEARCH/HINT) and the `g`-prefix buffer.
  Held on the controller instance; nothing else maintains a parallel copy.
- **Client-side search index cache** — module-scoped in `search_index.js` (deliberately not
  per-controller-instance, so Turbo Drive's disconnect/reconnect on every navigation does not wipe
  it); cached for the tab session, never re-fetched on a second `/` open.

---

## Dependencies

Must match the dependency graph in `docs/architecture/overview.md`.

- **content-domain** — `SearchIndexController` reads `Post.published` and `Project.all` to build
  the search index.
- **rails-runtime** — `SearchIndexController` inherits `ApplicationController`.
- web-presentation depends on this subsystem (renders the chrome partials in its layout), not the
  reverse.

---

## Known Limitations

- Hint-jump alphabet resolves a spec ambiguity in favour of the rationale (drop i/l/o, keep 23
  chars) rather than the spec's literal 24-char example string — see the note in `hints.js`.
- COMMAND registry ships the navigation/theme commands; the metrics-query commands the extension
  contract anticipates (`stats views`, `top posts`) are not implemented yet.

---

## Last Hardened

_Not yet hardened._

---

## Hardening History

| Date | Commit | Bugs Found | Bugs Fixed | Theatre Tests | Pyramid Migrations | Notes |
|------|--------|------------|------------|---------------|---------------------|-------|
| _none yet_ | | | | | | |
