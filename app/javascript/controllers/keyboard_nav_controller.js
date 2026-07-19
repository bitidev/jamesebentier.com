import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="keyboard-nav" -- mounted once on <body> in
// app/views/layouts/application.html.erb.
//
// The modal NORMAL/COMMAND/SEARCH keyboard-navigation layer (site-as-terminal). This
// controller *is* the mode state machine and the dispatcher (Stimulus's own idioms --
// a Value for mode, modeValueChanged() as the single place transitions are reacted to
// -- rather than a hand-rolled class alongside it); pure key-sequence/ranking/lookup
// logic that doesn't need the DOM lives in plain ES modules under
// app/javascript/keyboard_nav/ as later increments add it.
//
// This increment ships only the foundation: the mode Value + status line, the single
// document-level dispatch guard every later increment's bindings plug into, Esc-to-
// NORMAL, and `?` as a bare guide-dialog toggle (the full bindings reference table is
// a later increment). See docs/specs/1187-modal-vim-keyboard-navigation.md
// (Requirements R1, R2 -- "Increment 0" in that spec's own numbering).
//
// Turbo lifecycle note: standard (non-permanent) Turbo Drive visits replace <body>'s
// content, disconnecting and reconnecting this controller on every navigation -- that
// is the desired reset (mode back to "normal", no leaked listeners), not a bug. Do not
// mark <body> data-turbo-permanent.
export default class extends Controller {
  static values = { mode: { type: String, default: "normal" } }
  static targets = ["statusLine", "statusLineText", "guideDialog"]

  connect() {
    // Desktop/hardware-keyboard feature only (R12) -- checked once here, matching
    // motion_controller.js's own one-time prefers-reduced-motion check precedent. On
    // touch/no-precise-pointer devices, skip attaching the listener entirely (not just
    // hiding the UI) and never reveal the status line -- an honest "this is a desktop
    // feature" no-op, not a dead affordance.
    this.hasPointerSupport = window.matchMedia("(hover: hover) and (pointer: fine)").matches

    if (!this.hasPointerSupport) return

    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)

    if (this.hasStatusLineTarget) {
      this.statusLineTarget.classList.remove("hidden")
    }
  }

  disconnect() {
    if (this.boundHandleKeydown) {
      document.removeEventListener("keydown", this.boundHandleKeydown)
      this.boundHandleKeydown = null
    }
  }

  modeValueChanged() {
    if (!this.hasStatusLineTextTarget) return

    const label = { normal: "NORMAL", command: "COMMAND", search: "SEARCH" }[this.modeValue] || "NORMAL"
    this.statusLineTextTarget.textContent = `-- ${label} --`
    document.body.dataset.keyboardMode = this.modeValue
  }

  // Single document-level, bubble-phase keydown listener (Decision 2). Guard order is
  // load-bearing and must not be reordered without re-reading the spec:
  //   1. Modifier bail -- nothing in this feature's binding set uses a modifier chord.
  //   2. Escape -- evaluated *before* the editable-target bail returns control, since
  //      Esc must still close our own COMMAND/SEARCH <input> (which is itself an
  //      editable target) or the guide dialog even while it has focus. Escape has no
  //      destructive native meaning in a text field, so this is safe to leave unguarded
  //      by focus location -- the one documented exception to guard #3.
  //   3. Editable-target bail -- protects every native <input>/<textarea>/<select>/
  //      [contenteditable] on the site (present or future) and our own mode-UI inputs,
  //      via one generic check, never an ID-/selector-based skip-list.
  //   4. Guide-dialog-open bail -- while the native <dialog> is showing modally, it
  //      owns its own keyboard handling; we don't dispatch mode bindings underneath it.
  //   5. Mode dispatch -- only keys we act on call preventDefault(), never in a bail
  //      branch, so every unhandled key keeps its native browser behavior.
  handleKeydown(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) return

    if (event.key === "Escape") {
      this.handleEscape(event)
      return
    }

    if (this.isEditableTarget(event.target)) return
    if (this.hasGuideDialogTarget && this.guideDialogTarget.open) return

    this.dispatchNormalMode(event)
  }

  isEditableTarget(target) {
    if (!target) return false

    // .closest(), not .matches(): a keydown while a native <select>'s own dropdown
    // popup is open can target an internal descendant (e.g. the highlighted <option>)
    // rather than the <select> itself -- still squarely "typing in a native field," so
    // the guard must bail for the whole ancestor chain, not just an exact-tag match.
    if (typeof target.closest === "function" && target.closest("input, textarea, select")) return true

    return Boolean(target.isContentEditable)
  }

  handleEscape(event) {
    const guideOpen = this.hasGuideDialogTarget && this.guideDialogTarget.open
    const somethingOpen = this.modeValue !== "normal" || guideOpen

    if (!somethingOpen) return

    event.preventDefault()
    this.modeValue = "normal"
    if (guideOpen) this.guideDialogTarget.close()
  }

  dispatchNormalMode(event) {
    if (this.modeValue !== "normal") return

    if (event.key === "?") {
      event.preventDefault()
      this.guideDialogTarget.showModal()
    }
  }
}
