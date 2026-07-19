import { describe, expect, it } from "vitest"
import { assignHintLabels, HINT_ALPHABET } from "./hints"

// Increment 5 coverage (R8): assignHintLabels' deterministic single- then two-character
// assignment across the alphabet-length boundary. Plain objects stand in for real <a>
// elements -- this module never looks at what an "element" is, only its position, so no
// jsdom/DOM environment is needed (Decision 1's testability seam).
describe("assignHintLabels", () => {
  it("assigns single-character labels, in order, for a count within the alphabet", () => {
    const elements = Array.from({ length: HINT_ALPHABET.length }, (_, index) => ({ index }))

    const assignments = assignHintLabels(elements)

    assignments.forEach((assignment, index) => {
      expect(assignment.label).toBe(HINT_ALPHABET[index])
      expect(assignment.element).toBe(elements[index])
    })
  })

  it("keeps the last element single-character right at the alphabet boundary", () => {
    const elements = Array.from({ length: HINT_ALPHABET.length }, (_, index) => ({ index }))

    const assignments = assignHintLabels(elements)
    const last = assignments[assignments.length - 1]

    expect(last.label).toBe(HINT_ALPHABET[HINT_ALPHABET.length - 1])
    expect(last.label).toHaveLength(1)
  })

  it("switches to a two-character code for the first element past the alphabet boundary", () => {
    const elements = Array.from({ length: HINT_ALPHABET.length + 1 }, (_, index) => ({ index }))

    const assignments = assignHintLabels(elements)
    const firstOverflow = assignments[HINT_ALPHABET.length]

    expect(firstOverflow.label).toHaveLength(2)
    expect(firstOverflow.label).toBe(`${HINT_ALPHABET[0]}${HINT_ALPHABET[0]}`)
  })

  it("produces unique labels across a large set spanning many two-character codes", () => {
    const elements = Array.from({ length: HINT_ALPHABET.length * 3 }, (_, index) => ({ index }))

    const assignments = assignHintLabels(elements)
    const labels = assignments.map((assignment) => assignment.label)

    expect(new Set(labels).size).toBe(labels.length)
  })

  it("preserves the caller's positional order (DOM/tab order, never re-sorted)", () => {
    const elements = ["third-in-dom-order", "first-in-dom-order", "second-in-dom-order"]

    const assignments = assignHintLabels(elements)

    expect(assignments.map((assignment) => assignment.element)).toEqual(elements)
  })

  it("returns an empty array for no elements", () => {
    expect(assignHintLabels([])).toEqual([])
  })
})
