// Single source-of-truth theme cycle order (spec R5, architecture plan Decision 4).
// Matches the P1.1 theme-picker <select>'s own option order exactly
// (app/views/layouts/components/_header.html.erb) -- keyboard_nav_controller.js's `t`
// binding and the picker's <select> must never disagree about "next theme."
export const THEME_CYCLE_ORDER = ["light", "dark", "dracula", "nord", "gruvbox", "catppuccin"]

// Pure function, zero DOM access (Decision 1's testability seam): given the current
// theme name, returns the next one in THEME_CYCLE_ORDER, wrapping catppuccin -> light.
// An unrecognized/missing current value (indexOf returns -1) gracefully falls back to
// the first theme in the order, rather than throwing or returning undefined -- the
// same "forgiving on unexpected input" discipline the g-prefix buffer already uses.
export function nextTheme(current) {
  const currentIndex = THEME_CYCLE_ORDER.indexOf(current)
  const nextIndex = (currentIndex + 1) % THEME_CYCLE_ORDER.length

  return THEME_CYCLE_ORDER[nextIndex]
}
