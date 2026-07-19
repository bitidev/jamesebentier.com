import { Controller } from "@hotwired/stimulus"
import { resolveNavTarget } from "../keyboard_nav/resolve_nav_target"
import { nextTheme } from "../keyboard_nav/theme_cycle"

// Milliseconds the `g`-prefix sequence buffer (gg/gh/gw/gp/gl) stays armed after a bare
// `g` keypress before silently clearing -- matches vim's own forgiving,
// no-error-on-unknown-sequence convention (Decision 2, rule 4).
const G_PREFIX_TIMEOUT_MS = 600

// `g` + one of these resolves to a resolveNavTarget() key (architecture plan Decision 6,
// spec R3/R4). Deliberately does NOT include "resume" -- only the four g-jump letters
// the spec names (h/w/p/l) are wired here; :resume (a later COMMAND-mode increment) is
// the other resolveNavTarget("resume") entry point.
const G_PREFIX_NAV_KEYS = { h: "home", w: "writing", p: "projects", l: "lab" }

// Pixels moved per NORMAL-mode line-scroll keypress (j/k vertical, h/l horizontal).
const LINE_SCROLL_PX = 100

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
// Foundation (mode Value + status line, the document-level dispatch guard, Esc-to-
// NORMAL, `?` as a bare guide-dialog toggle) shipped first; a later increment added
// NORMAL-mode navigation: h/j/k/l scroll, gg/G top/bottom, and the g-prefixed page
// jumps via resolveNavTarget (spec R3/R4, "Increment 1"). This increment adds the `t`
// theme cycle (spec R5, "Increment 2"), reusing the existing P1.1 theme-picker
// controller/<select> as the single source of truth -- no parallel theme-apply/persist
// logic. See docs/specs/1187-modal-vim-keyboard-navigation.md.
//
// Turbo lifecycle note: standard (non-permanent) Turbo Drive visits replace <body>'s
// content, disconnecting and reconnecting this controller on every navigation -- that
// is the desired reset (mode back to "normal", no leaked listeners), not a bug. Do not
// mark <body> data-turbo-permanent.
export default class extends Controller {
  static values = { mode: { type: String, default: "normal" } }
  static targets = ["statusLine", "statusLineText", "guideDialog", "themeSelect"]

  connect() {
    // Desktop/hardware-keyboard feature only (R12) -- checked once here, matching
    // motion_controller.js's own one-time prefers-reduced-motion check precedent. On
    // touch/no-precise-pointer devices, skip attaching the listener entirely (not just
    // hiding the UI) and never reveal the status line -- an honest "this is a desktop
    // feature" no-op, not a dead affordance.
    this.hasPointerSupport = window.matchMedia("(hover: hover) and (pointer: fine)").matches

    if (!this.hasPointerSupport) return

    this.pendingGPrefix = false
    this.gPrefixTimeoutId = null

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

    this.clearGPrefixTimeout()
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

  // NORMAL-mode binding table (spec R3). The `g`-prefix sequence (gg/gh/gw/gp/gl) is
  // handled first, unconditionally consuming whatever key follows an armed `g` --
  // recognized or not -- so e.g. "gj" never *also* falls through to a j-scroll (spec
  // Decision 2, rule 4: "anything else, or timeout, silently clears the buffer").
  dispatchNormalMode(event) {
    if (this.modeValue !== "normal") return

    if (this.pendingGPrefix) {
      this.resolvePendingGPrefix(event)
      return
    }

    switch (event.key) {
      case "?":
        event.preventDefault()
        this.guideDialogTarget.showModal()
        return
      case "g":
        event.preventDefault()
        this.armGPrefix()
        return
      case "G":
        event.preventDefault()
        this.scrollToBottom()
        return
      case "j":
        event.preventDefault()
        this.scrollByLines(1)
        return
      case "k":
        event.preventDefault()
        this.scrollByLines(-1)
        return
      case "h":
        event.preventDefault()
        this.scrollHorizontally(-1)
        return
      case "l":
        event.preventDefault()
        this.scrollHorizontally(1)
        return
      case "t":
        event.preventDefault()
        this.cycleTheme()
        return
    }
  }

  resolvePendingGPrefix(event) {
    this.clearGPrefix()

    const { key } = event

    if (key === "g") {
      event.preventDefault()
      this.scrollToTop()
      return
    }

    const navKey = G_PREFIX_NAV_KEYS[key]
    if (!navKey) return // unrecognized g-sequence -- silently clear, no error (vim convention)

    event.preventDefault()
    this.navigateTo(navKey)
  }

  armGPrefix() {
    this.pendingGPrefix = true
    this.clearGPrefixTimeout()
    this.gPrefixTimeoutId = setTimeout(() => {
      this.pendingGPrefix = false
    }, G_PREFIX_TIMEOUT_MS)
  }

  clearGPrefix() {
    this.pendingGPrefix = false
    this.clearGPrefixTimeout()
  }

  clearGPrefixTimeout() {
    if (!this.gPrefixTimeoutId) return

    clearTimeout(this.gPrefixTimeoutId)
    this.gPrefixTimeoutId = null
  }

  // Single-source-of-truth page jump (Decision 6): resolveNavTarget() reads the actual,
  // Rails-rendered header anchor -- never a hardcoded path literal. A key with no
  // matching data-nav-target (e.g. "lab", no /lab route yet) resolves to null and this
  // is a documented no-op.
  navigateTo(target) {
    const element = resolveNavTarget(target)
    if (element) element.click()
  }

  // Instant, not animated: R11's prefers-reduced-motion bullet scopes "any transition"
  // to the status line/command-search bars/hint badges/guide overlay -- page-scroll
  // triggered by hjkl/gg/G is a functional jump, not a decorative transition, so there's
  // no separate reduced-motion branch to maintain here.
  scrollByLines(direction) {
    window.scrollBy({ top: direction * LINE_SCROLL_PX })
  }

  scrollHorizontally(direction) {
    window.scrollBy({ left: direction * LINE_SCROLL_PX })
  }

  scrollToTop() {
    window.scrollTo({ top: 0 })
  }

  scrollToBottom() {
    window.scrollTo({ top: document.documentElement.scrollHeight })
  }

  // `t` theme cycle (spec R5, Decision 4). Deliberately does NOT touch
  // document.documentElement.dataset.theme or localStorage directly -- this drives the
  // *same* P1.1 theme-picker <select> a manual dropdown change would, via a real
  // `change` event, so theme_picker_controller.js#change is the one and only code path
  // that ever applies/persists a theme. themeSelectTarget is a second controller's
  // target on the same <select> element theme-picker already owns (standard Stimulus
  // multi-controller pattern), not a duplicate control.
  cycleTheme() {
    if (!this.hasThemeSelectTarget) return

    const current = document.documentElement.dataset.theme
    this.themeSelectTarget.value = nextTheme(current)
    this.themeSelectTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
