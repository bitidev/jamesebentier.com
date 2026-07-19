import { describe, expect, it } from "vitest"
import { resolveNavTarget } from "./resolve_nav_target"

// A hand-rolled fake root exposing just the querySelector shape resolveNavTarget needs
// -- no jsdom/DOM environment required (see resolve_nav_target.js's header comment).
function fakeRoot(elementsBySelector) {
  return {
    querySelector: (selector) => elementsBySelector[selector] ?? null,
  }
}

describe("resolveNavTarget", () => {
  it("returns the element matching a known data-nav-target", () => {
    const homeLink = { href: "/", nodeName: "A" }
    const root = fakeRoot({ '[data-nav-target="home"]': homeLink })

    expect(resolveNavTarget("home", root)).toBe(homeLink)
  })

  it("returns null for an unknown data-nav-target (e.g. lab -- no /lab route yet)", () => {
    const root = fakeRoot({})

    expect(resolveNavTarget("lab", root)).toBeNull()
  })

  it("queries a distinct selector per key, never conflating targets", () => {
    const writingLink = { href: "/blog", nodeName: "A" }
    const projectsLink = { href: "/projects", nodeName: "A" }
    const root = fakeRoot({
      '[data-nav-target="writing"]': writingLink,
      '[data-nav-target="projects"]': projectsLink,
    })

    expect(resolveNavTarget("writing", root)).toBe(writingLink)
    expect(resolveNavTarget("projects", root)).toBe(projectsLink)
  })
})
