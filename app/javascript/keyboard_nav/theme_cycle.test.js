import { describe, expect, it } from "vitest"
import { nextTheme, THEME_CYCLE_ORDER } from "./theme_cycle"

describe("nextTheme", () => {
  it("advances to the following theme for every theme except the last", () => {
    for (let i = 0; i < THEME_CYCLE_ORDER.length - 1; i += 1) {
      expect(nextTheme(THEME_CYCLE_ORDER[i])).toBe(THEME_CYCLE_ORDER[i + 1])
    }
  })

  it("wraps catppuccin back to light", () => {
    expect(nextTheme("catppuccin")).toBe("light")
  })

  it("falls back to the first theme in the order for an unrecognized current value", () => {
    expect(nextTheme("not-a-real-theme")).toBe("light")
    expect(nextTheme(undefined)).toBe("light")
  })
})
