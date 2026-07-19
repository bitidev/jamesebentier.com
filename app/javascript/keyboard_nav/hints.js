// `f` hint-jump's pure label-assignment logic (spec R8, architecture plan Decision 5).
// Zero DOM access (Decision 1's testability seam, mirrors resolveNavTarget's/
// theme_cycle's own pure-function modules) -- `assignHintLabels` never dereferences
// anything on the `elements` it's given beyond pairing each one, positionally, with a
// label; keyboard_nav_controller.js is the only place that ever calls
// getBoundingClientRect()/.click() on the real elements these labels are assigned to.
//
// Spec note: the spec's prose alphabet ("23-character alphabet, excluding the three
// most visually-ambiguous lowercase letters i/l/o") and its literal example string
// (`a s d f g h j k l q w e r t y u p z x c v b n m`) disagree -- that string still
// contains `l` and is 24 characters long, not 23. This module follows the *rationale*
// (drop all three of i/l/o; keep the count at exactly 23, matching "Single characters
// cover the first 23 on-screen links" and the acceptance criterion's "single-to-two-
// character alphabet boundary") over the literal, internally-inconsistent string, and
// removes the stray `l`. Flagged here, and in the Increment 5 PR, as a spec typo, not a
// silent deviation.
export const HINT_ALPHABET = [
  "a", "s", "d", "f", "g", "h", "j", "k", "q", "w", "e", "r", "t", "y", "u", "p", "z", "x", "c", "v", "b", "n", "m",
]

// Single characters cover indices [0, HINT_ALPHABET.length). Beyond that, two-character
// codes are formed the Vimium way named in the spec: first-character prefix + second-
// character suffix, both still drawn from the same alphabet, assigned in the same
// positional (DOM/tab) order the caller already provided -- never visual position. This
// supports up to alphabet.length + alphabet.length**2 elements (23 + 529 = 552) before
// labels would repeat, far beyond any real on-screen link count.
export function hintLabelForIndex(index, alphabet = HINT_ALPHABET) {
  const size = alphabet.length

  if (index < size) return alphabet[index]

  const overflowIndex = index - size
  const firstIndex = Math.floor(overflowIndex / size) % size
  const secondIndex = overflowIndex % size

  return `${alphabet[firstIndex]}${alphabet[secondIndex]}`
}

// Given a positionally-ordered array of arbitrary items (real <a> elements in
// production; plain objects/strings in tests -- this function never looks at what an
// item *is*), returns a same-length, same-order array of `{ element, label }` pairs.
// The caller (keyboard_nav_controller.js) is responsible for collecting the elements in
// genuine DOM/tab order before calling this -- assignHintLabels itself only assigns by
// position, deterministically, so the same input order always yields the same labels.
export function assignHintLabels(elements) {
  return elements.map((element, index) => ({ element, label: hintLabelForIndex(index) }))
}
