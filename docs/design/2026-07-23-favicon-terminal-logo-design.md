# Favicon + app-icon refresh to the `❯` terminal mark — design (#1235)

## Problem

The 2026 terminal-identity redesign (epic #1179) made the site's mark the `❯` chevron
prompt (`❯ james@ebentier`), but the browser/app icon set in `public/` was never
regenerated — the favicon, PWA, and home-screen icons still show the **old** pre-redesign
logo. Two of the assets are outright broken: `apple-touch-icon.png` and
`apple-touch-icon-precomposed.png` are **0 bytes**. On top of that the layout's
`apple-touch-icon` link points at `/logo192.png`, so the intended `apple-touch-icon.png`
file isn't even referenced.

Result: browser tab, bookmarks, and installed-PWA / iOS home-screen icons are off-brand or
missing entirely.

## Chosen approach

Add a **reproducible icon generator**, modelled on the existing OG-image generator
(`lib/og_image/generator.rb` + `rake og:image`), that renders the `❯` terminal mark to
every required size, plus a rake task as its sole intended caller. The committed binaries in
`public/` become build artifacts of the task — never hand-edited — exactly as
`public/og-default.png` already is.

Three load-bearing decisions:

1. **Draw the chevron as an inline SVG path, not a Unicode glyph.** The OG card renders the
   `❯` ornament (`&#10095;`, U+276F) from the system monospace font. That glyph's coverage
   varies across machines/fonts (Liberation Mono on CI may render tofu), which is
   unacceptable for a tiny 16px favicon. Drawing the chevron as an SVG `<path>` (amber
   stroke, round line caps/joins) on the dark base makes the render **deterministic on any
   machine** — the same reproducibility property the OG generator explicitly aims for.
2. **Reuse Ferrum (headless Chrome), add no new gem.** Ferrum is already a dependency
   (Cuprite driver + OG generator). It rasterizes the SVG at each exact target pixel size.
   No ImageMagick / rsvg / vips is installed, so we stay within what's already here.
3. **Assemble `favicon.ico` with ImageMagick via `mini_magick`** (operator's call,
   2026-07-23). Ferrum renders the 16/32/48 PNGs (repo's established, already-tested pattern);
   ImageMagick combines them into the multi-size `.ico` — the one step only a real image tool
   does cleanly. This adds `mini_magick` (gem) + ImageMagick as a **build-time-only**
   dependency: added to the Dockerfile build stage and setup docs, and installed locally to
   regenerate. It is **not** needed in CI or production — see the testing note below.

### Why the build tool doesn't reach CI or prod

Following the OG generator's two-layer test model (`spec/lib/og_image/generator_spec.rb`):
the committed binaries (`public/*.png|ico`) are asserted against **their own bytes** (PNG
IHDR dimensions; ICO `ICONDIR` header + entry count/sizes) with no image gem, and the
generator's wiring is exercised with **Ferrum and ImageMagick stubbed** — so the suite never
launches Chrome or shells out to `magick` in CI. The assets are committed like
`og-default.png`; production serves the static files and never regenerates them. ImageMagick
is thus required only on the machine that runs `rake favicon:generate`.

Palette matches the OG card exactly: base `#0d1117`, chevron amber `#fab73a`. The mark is a
centered chevron sized with padding so it survives iOS rounding and PWA maskable safe-zone
cropping; the dark base fills the full square (good maskable behavior).

### Assets regenerated (all to the `❯` mark)

| File | Size | Consumer |
|---|---|---|
| `favicon.ico` | 16/32/48 multi | `<link rel="shortcut icon">` |
| `favicon-16x16.png` | 16 | `<link rel="icon">` |
| `favicon-32x32.png` | 32 | `<link rel="icon">` |
| `apple-touch-icon.png` | 180 | iOS home screen (currently 0 B) |
| `apple-touch-icon-precomposed.png` | 180 | iOS home screen (currently 0 B) |
| `logo192.png` | 192 | manifest PWA icon |
| `logo512.png` | 512 | manifest PWA icon |
| `logo.png` | 512 | RSS channel image + schema.org logo |

### Wiring fixes (small, in-scope)

- Point the `apple-touch-icon` link at `/apple-touch-icon.png` (180×180), not `/logo192.png`.
- Align `manifest.json` `theme_color` / `background_color` to the terminal palette
  (`#0d1117`) so the PWA splash/chrome matches — the manifest is already being touched for
  icons.

## Acceptance criteria

- Browser tab, bookmark, apple-touch, and PWA-manifest icons all show the `❯` terminal mark.
- `apple-touch-icon.png` and `apple-touch-icon-precomposed.png` are no longer 0 bytes.
- The icon set validates cleanly in a favicon checker (no missing/broken/mismatched entries).
- `rake favicon:generate` reproducibly rewrites every asset from source; binaries are not
  hand-edited.

## Resolved (operator, 2026-07-23)

- **`logo.png` size → 512×512** (general-purpose, safe for both RSS `image` and schema.org
  `logo`).
- **ICO assembly → ImageMagick + `mini_magick`** (build-time-only tool; see decision 3 and
  the CI/prod note above).
