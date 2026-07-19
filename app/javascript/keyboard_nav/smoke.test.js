import { describe, expect, it } from "vitest"

// Increment 0 smoke test: proves the Vitest unit-test infrastructure runs
// (ESM-native, zero config beyond vitest.config.js). Superseded by real
// coverage of app/javascript/keyboard_nav/*.js as each later increment lands
// its pure-function modules (resolveNavTarget, commands, hints, search_index,
// theme_cycle -- see docs/specs/1187-modal-vim-keyboard-navigation.md).
describe("vitest infrastructure", () => {
  it("runs a trivial assertion", () => {
    expect(1 + 1).toBe(2)
  })
})
