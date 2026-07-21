import { Controller } from "@hotwired/stimulus"
import { resolveNavTarget } from "../keyboard_nav/resolve_nav_target"
import { nextTheme } from "../keyboard_nav/theme_cycle"
import { COMMAND_REGISTRY, findCommand, formatCommandInvocation, parseCommand, rankCommands, willCommandApply } from "../keyboard_nav/commands"
import { fetchSearchIndex, rankSearchResults } from "../keyboard_nav/search_index"
import { assignHintLabels } from "../keyboard_nav/hints"

// Milliseconds the `g`-prefix sequence buffer (gg/gh/gw/gp/gl) stays armed after a bare
// `g` keypress before silently clearing -- matches vim's own forgiving,
// no-error-on-unknown-sequence convention (Decision 2, rule 4).
const G_PREFIX_TIMEOUT_MS = 600

// `g` + one of these resolves to a resolveNavTarget() key (architecture plan Decision 6,
// spec R3/R4). Deliberately does NOT include "resume" -- only the four g-jump letters
// the spec names (h/w/p/l) are wired here; `:resume` (COMMAND mode, spec R6) is the
// other resolveNavTarget("resume") entry point.
const G_PREFIX_NAV_KEYS = { h: "home", w: "writing", p: "projects", l: "lab" }

// Pixels moved per NORMAL-mode line-scroll keypress (j/k vertical, h/l horizontal).
const LINE_SCROLL_PX = 100

// The one shared terminal-style bar (app/views/layouts/components/_keyboard_command_bar.html.erb,
// architecture plan file-layout table) is reused for both COMMAND and SEARCH (spec R6/R7)
// -- only the leading glyph, the sr-only label, and the placeholder copy differ per mode,
// set here at entry (enterBarMode) rather than standing up a second bar/input pair.
const COMMAND_BAR_COPY = {
  command: {
    glyph: ":",
    label: "Command",
    placeholder: "home | writing | projects | resume | theme <name> | help",
  },
  search: {
    glyph: "/",
    label: "Search",
    placeholder: "search posts & projects -- n/N steps through results, Enter opens",
  },
}

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
// jumps via resolveNavTarget (spec R3/R4, "Increment 1"). Another increment added the
// `t` theme cycle (spec R5, "Increment 2"), reusing the existing P1.1 theme-picker
// controller/<select> as the single source of truth -- no parallel theme-apply/persist
// logic. Another increment added COMMAND mode (spec R6, "Increment 3"): `:` opens a
// terminal-style input wired to the extensible command registry in
// ../keyboard_nav/commands.js -- nav commands reuse resolveNavTarget exactly as the
// g-prefix jumps do, and `:theme <name>` reuses this same controller's theme-apply path
// (cycleTheme/applyTheme both drive the one P1.1 <select>), so there is still only one
// code path per concern, now with two entry points into each. This increment adds
// SEARCH mode (spec R7, "Increment 4"): `/` reuses the exact same terminal-style bar/
// input COMMAND already stood up (enterBarMode, shared between both modes) rather than
// a second bar, wired instead to ../keyboard_nav/search_index.js's lazily-fetched,
// tab-session-cached content index and its rankSearchResults ranking; `n`/`N` step the
// highlighted result within the open results list (SEARCH-mode-scoped, architecture plan
// Decision 3 -- not a global "repeat search"); Enter activates the highlighted result via
// .click() on its real, rendered <a> (never a hand-built URL string). This increment
// adds `f` hint-jump (spec R8, "Increment 5"): a NORMAL sub-state (the mode Value itself
// stays "normal" -- the status line's "(HINT)" qualifier is set directly, bypassing
// modeValueChanged() for the same focus/visibility-ordering reason enterBarMode/
// exitToNormal already do) that labels every on-screen <a href> via
// ../keyboard_nav/hints.js's assignHintLabels, renders aria-hidden/pointer-events-none
// badges, and activates the typed match via .click() on the real anchor -- the same
// "never build a URL string, never open a second activation path" discipline
// navigateTo/commitSearch already established. Esc and the first scroll event both
// cancel; hint-jump moves no focus and sets no tabindex, ever (R11). This increment (the
// closeout, "Increment 6") replaces the Increment 0 bare `?` toggle with the full
// bindings-reference content (spec R10): a hand-authored NORMAL-mode/mode-switch
// reference table in the ERB partial itself (there's no JS data structure those bindings
// live in to source from), plus the COMMAND registry's v1 command list rendered directly
// from ../keyboard_nav/commands.js's COMMAND_REGISTRY (renderGuideCommandList, called
// once from connect()) rather than a second, hand-duplicated copy that could drift the
// day P1.9 adds a metrics-query command -- the same single-source-of-truth discipline
// this controller already applies to theme/nav.
// See docs/specs/1187-modal-vim-keyboard-navigation.md.
//
// Turbo lifecycle note: standard (non-permanent) Turbo Drive visits replace <body>'s
// content, disconnecting and reconnecting this controller on every navigation -- that
// is the desired reset (mode back to "normal", no leaked listeners), not a bug. Do not
// mark <body> data-turbo-permanent.
export default class extends Controller {
  static values = { mode: { type: String, default: "normal" } }
  static targets = [
    "statusLine",
    "statusLineText",
    "guideDialog",
    "guideCommandList",
    "themeSelect",
    "commandBar",
    "commandGlyph",
    "commandLabel",
    "commandInput",
    "commandFeedback",
    "searchResults",
    "hintOverlay",
  ]

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

    this.renderGuideCommandList()
  }

  disconnect() {
    if (this.boundHandleKeydown) {
      document.removeEventListener("keydown", this.boundHandleKeydown)
      this.boundHandleKeydown = null
    }

    this.clearGPrefixTimeout()

    // Defensive, not load-bearing in the common case: a standard Turbo visit replaces
    // <body> (where the hint badges/status line live) wholesale anyway. It IS load-
    // bearing for the scroll-cancel listener, though -- that's attached to `window`,
    // which Turbo does NOT replace, so it would otherwise outlive this controller
    // instance across a navigation that happens mid-hint-jump without a scroll firing
    // first.
    this.cancelHintMode()
  }

  // Deliberately does NOT also toggle the command bar's visibility here (only the
  // status line text + the CSS hook) -- Stimulus's Value-changed callback runs off a
  // MutationObserver, i.e. *after* the current synchronous call stack, so anything that
  // must be visible/focusable before this same keydown handler's next line (see
  // enterCommandMode()'s focus() call) has to be applied directly and synchronously at
  // the entry/exit point, not deferred here. This mirrors how the guide dialog's
  // showModal()/close() are also called directly, never through this callback.
  modeValueChanged() {
    if (this.hasStatusLineTextTarget) this.statusLineTextTarget.textContent = `-- ${this.modeLabel()} --`
    document.body.dataset.keyboardMode = this.modeValue
  }

  // Shared by modeValueChanged() and setHintStatusQualifier() -- one place mapping the
  // mode Value to its status-line label, rather than two copies of the same lookup
  // table (hint-jump needs its own copy since it deliberately never changes modeValue,
  // spec R8, so it can't just rely on modeValueChanged() firing).
  modeLabel() {
    return { normal: "NORMAL", command: "COMMAND", search: "SEARCH" }[this.modeValue] || "NORMAL"
  }

  // Header `?` chip's click handler (terminal-identity redesign, #1226's design doc:
  // "Header" section) -- bound via data-action="click->keyboard-nav#openGuideDialog"
  // on the header's own `?` button. Additive: the document-level `?` keydown binding in
  // dispatchNormalMode (spec R10) still opens the same dialog the same way: this is a
  // second, mouse/touch-reachable entry point into that one showModal() call, never a
  // parallel open/close implementation.
  openGuideDialog(event) {
    event?.preventDefault()
    // Guard on .open: showModal() throws InvalidStateError if the dialog is already open
    // (e.g. the `?` chip double-clicked). The `?` keydown path (dispatchNormalMode) also
    // routes through here now; handleKeydown already bails while the dialog is open, so
    // that path never hits an open dialog -- this guard is what makes the click entry safe.
    if (this.hasGuideDialogTarget && !this.guideDialogTarget.open) this.guideDialogTarget.showModal()
  }

  // `?` guide overlay's COMMAND-registry list (spec R10, Increment 6): populated once
  // here, directly from COMMAND_REGISTRY, rather than a hand-authored copy in the ERB
  // partial -- the single source of truth the registry's own file-header comment already
  // promises ("shown in the `?` guide overlay"). Static content for the lifetime of this
  // controller instance (the registry itself never changes at runtime), so connect() is
  // the one place this needs to run, not a per-open re-render. A future P1.9 command
  // added to COMMAND_REGISTRY appears here with zero ERB/template changes required.
  renderGuideCommandList() {
    if (!this.hasGuideCommandListTarget) return

    this.guideCommandListTarget.innerHTML = ""

    COMMAND_REGISTRY.forEach((command) => {
      const dt = document.createElement("dt")
      const dd = document.createElement("dd")

      dt.textContent = formatCommandInvocation(command)
      dd.textContent = command.description

      this.guideCommandListTarget.append(dt, dd)
    })
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

    // Hint-jump is a NORMAL sub-state (spec R8): while its badges are showing, every
    // keydown is typed hint input, not a NORMAL binding -- including "f" itself and
    // every other key hint-jump's own alphabet happens to share with dispatchNormalMode
    // (e.g. "g", "t"). Checked here, before dispatchNormalMode, rather than inside it,
    // since dispatchNormalMode's own `this.modeValue !== "normal"` guard can't tell hint-
    // jump apart from bare NORMAL (mode Value deliberately stays "normal" throughout).
    if (this.hintModeActive) {
      this.handleHintKeydown(event)
      return
    }

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
    const modeOpen = this.modeValue !== "normal"
    const hintOpen = this.hintModeActive

    if (!modeOpen && !guideOpen && !hintOpen) return

    event.preventDefault()

    // Esc always returns to NORMAL and restores whatever had focus before entry (spec
    // R6, architecture plan Decision 1/7) -- never assumed to be document.body. Clearing
    // the input/feedback here (not just on the next entry) means a stale command never
    // flashes if COMMAND is reopened before its next explicit reset.
    if (modeOpen) this.cancelMode()
    if (guideOpen) this.guideDialogTarget.close()
    // Hint-jump never moved mode off "normal" (spec R8), so it needs its own explicit
    // cancel branch here -- modeOpen alone would never catch it.
    if (hintOpen) this.cancelHintMode()
  }

  // Shared cancel path for both Esc (handleEscape) and a not-found Enter that the
  // visitor abandons by pressing Esc next -- exits COMMAND or SEARCH identically (spec
  // R6/R7): clear input/feedback/results, return to NORMAL, restore prior focus.
  cancelMode() {
    if (this.hasCommandInputTarget) this.commandInputTarget.value = ""
    this.clearCommandFeedback()
    this.clearSearchResults()
    this.exitToNormal()
  }

  exitToNormal() {
    // Hidden synchronously, here, rather than via modeValueChanged() -- see that
    // method's comment for why anything focus/visibility-ordering-sensitive can't wait
    // on the async Value-changed callback.
    if (this.hasCommandBarTarget) this.commandBarTarget.classList.add("hidden")

    this.modeValue = "normal"

    const priorFocus = this.priorFocus
    this.priorFocus = null

    // Blur the bar's own <input> first, unconditionally -- calling .focus() on
    // priorFocus alone is not reliable when priorFocus is document.body: a bare
    // <body> has no tabindex, so per spec .focus() on it is a no-op while another
    // element (our own input) still holds focus, silently leaving the input focused
    // after "Esc" (a real, reproduced bug -- the next document-level keydown then
    // bails via the editable-target guard, since the still-focused input matches it).
    // Explicitly blurring first guarantees focus actually leaves the input; the
    // browser's own default then reverts activeElement to <body> when nothing else
    // claims it, so priorFocus.focus() below only has real work to do when priorFocus
    // is an actual focusable element other than body.
    if (this.hasCommandInputTarget) this.commandInputTarget.blur()

    if (priorFocus && priorFocus !== document.body && typeof priorFocus.focus === "function") priorFocus.focus()
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
        // Single showModal() entry point, shared with the header `?` chip's click handler
        // (openGuideDialog also calls preventDefault + guards the already-open case).
        this.openGuideDialog(event)
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
      case ":":
        event.preventDefault()
        this.enterCommandMode()
        return
      case "/":
        event.preventDefault()
        this.enterSearchMode()
        return
      case "f":
        event.preventDefault()
        this.enterHintMode()
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
    const current = document.documentElement.dataset.theme
    this.applyTheme(nextTheme(current))
  }

  // Shared with cycleTheme() so `t` and `:theme <name>` (COMMAND mode, spec R6) are
  // genuinely one code path, not two copies of "set value + dispatch change" -- both
  // ultimately drive the same P1.1 <select>/theme_picker#change pair (Decision 4).
  applyTheme(theme) {
    if (!this.hasThemeSelectTarget) return

    this.themeSelectTarget.value = theme
    this.themeSelectTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // `:` (NORMAL) -> COMMAND (spec R6, Decision 1/2).
  enterCommandMode() {
    this.enterBarMode("command")
  }

  // `/` (NORMAL) -> SEARCH (spec R7, Decision 1/2/3): identical entry shape to COMMAND
  // (save/restore focus, shared bar), plus kicking off the index fetch -- fetchSearchIndex
  // itself is idempotent for the rest of the tab session (search_index.js's module-level
  // cache), so re-entering SEARCH repeatedly never re-fetches.
  enterSearchMode() {
    this.enterBarMode("search")
    this.loadSearchIndex()
  }

  // Shared COMMAND/SEARCH entry (architecture plan file-layout table: "one partial, a
  // mode: local selects the placeholder/submit behavior"): save focus, clear any stale
  // input/feedback/results from a prior open, swap the bar's glyph/label/placeholder copy
  // for the requested mode, reveal the bar, move focus into its <input>. Enter/typing are
  // the input's own element-scoped Stimulus actions (data-action on the partial), not
  // document-level dispatch, since the editable-target guard (handleKeydown) already
  // bails out of mode dispatch the instant this input has focus.
  enterBarMode(mode) {
    if (!this.hasCommandInputTarget) return

    this.priorFocus = document.activeElement
    this.commandInputTarget.value = ""
    this.clearCommandFeedback()
    this.clearSearchResults()

    const copy = COMMAND_BAR_COPY[mode]
    if (this.hasCommandGlyphTarget) this.commandGlyphTarget.textContent = copy.glyph
    if (this.hasCommandLabelTarget) this.commandLabelTarget.textContent = copy.label
    this.commandInputTarget.placeholder = copy.placeholder

    // Un-hidden synchronously, here, rather than via modeValueChanged() -- see that
    // method's comment. A descendant of a still-`display: none` ancestor cannot receive
    // focus, so the bar must already be visible by the time focus() below runs, and the
    // async Value-changed callback cannot be relied on for that ordering.
    if (this.hasCommandBarTarget) this.commandBarTarget.classList.remove("hidden")
    this.modeValue = mode
    this.commandInputTarget.focus()
  }

  // Single input->/keydown-> actions on the shared bar's <input> (spec R6/R7 file-layout
  // table), dispatching on the controller's current mode Value rather than duplicating
  // this markup/wiring for a second bar. Stimulus's action key-filter list only supports
  // a fixed set of named keys (enter/esc/space/arrows/home/end/page_up/page_down) -- not
  // arbitrary letters like "n"/"N" -- so both Enter and SEARCH's n/N stepping are handled
  // here as plain keydown checks, not further data-action filters.
  handleBarInput() {
    if (this.modeValue === "search") {
      this.filterSearchResults()
    } else if (this.modeValue === "command") {
      this.handleCommandInput()
    }
  }

  handleBarKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      if (this.modeValue === "search") this.commitSearch()
      else if (this.modeValue === "command") this.commitCommand()
      return
    }

    if (this.modeValue !== "search") return

    // n/N are SEARCH-mode-scoped result-stepping keys (spec R7, architecture plan
    // Decision 3: "not a global 'repeat last search'"), reserved even while the search
    // <input> itself has focus -- a deliberate, named trade-off: a literal "n"/"N" cannot
    // be typed into the query while SEARCH is open, in exchange for vim's own n/N-steps-
    // through-matches convention working without ever leaving the input.
    if (event.key === "n") {
      event.preventDefault()
      this.stepSearchSelection(1)
    } else if (event.key === "N") {
      event.preventDefault()
      this.stepSearchSelection(-1)
    }
  }

  // Live-filter/rank feedback as the visitor types (spec R6: "live-filter/rank the
  // registry via rankCommands as the visitor types"). Enter (commitCommand), not this
  // handler, is what actually invokes a command -- this is feedback only, so an
  // in-progress, ambiguous, or not-yet-matching query never throws or navigates.
  handleCommandInput() {
    const { name } = parseCommand(this.commandInputTarget.value)

    if (!name) {
      this.clearCommandFeedback()
      return
    }

    const matches = rankCommands(name, COMMAND_REGISTRY)
    this.setCommandFeedback(
      matches.length > 0 ? matches.map((command) => `:${command.name}`).join("  ") : `${name}: no matching command`
    )
  }

  // Enter (spec R6): parseCommand the current input, look up by exact name/alias/
  // unambiguous prefix (findCommand), then willCommandApply for side-effect-free
  // preflight (today: `:theme` arg validity). An empty name (bare Enter with nothing
  // typed) is a silent no-op -- there's nothing to be "not found." Missing command or
  // failed preflight keep the bar open with one shared "not found" feedback state.
  // On success: clear the input, exitToNormal (blur + restore priorFocus), then run()
  // -- exit before run so showModal() (e.g. `:help`) does not capture the command
  // input as the dialog's focus-restore target.
  commitCommand() {
    const { name, args } = parseCommand(this.commandInputTarget.value)
    if (!name) return

    const command = findCommand(name, COMMAND_REGISTRY)
    if (!command || !willCommandApply(command, args)) {
      this.setCommandFeedback(`${name}: command not found`)
      return
    }

    const staysInCommandMode = command.staysInCommandMode === true

    this.commandInputTarget.value = ""
    this.clearCommandFeedback()
    if (!staysInCommandMode) {
      // Exit COMMAND mode (blur + restore priorFocus) before run() -- especially
      // openGuideDialog/showModal() -- so the native <dialog>'s own focus-restore on
      // Esc-close returns to the pre-COMMAND target, not the now-hidden command input.
      this.exitToNormal()
    }
    command.run(args, this.commandContext())
  }

  // Bound methods handed to a command's run(args, context) -- each delegates to this
  // controller's own existing methods (navigateTo/applyTheme/guideDialogTarget), so
  // COMMAND-mode commands are a second entry point into the same single code paths the
  // g-prefix jumps and `t` already use, never a parallel implementation.
  commandContext() {
    return {
      navigateTo: (target) => this.navigateTo(target),
      setTheme: (theme) => this.applyTheme(theme),
      openGuideDialog: () => this.hasGuideDialogTarget && this.guideDialogTarget.showModal(),
      setCommandFeedback: (text) => this.setCommandFeedback(text),
    }
  }

  setCommandFeedback(text) {
    if (this.hasCommandFeedbackTarget) this.commandFeedbackTarget.textContent = text
  }

  clearCommandFeedback() {
    this.setCommandFeedback("")
  }

  // SEARCH mode (spec R7, architecture plan Decision 3). `/`'s first open in a tab
  // session triggers this; fetchSearchIndex's own module-level cache (search_index.js) is
  // what actually makes "never re-fetch on a subsequent `/` open" hold across Turbo-
  // driven navigations, since a fresh keyboard-nav controller instance connects on every
  // Turbo visit (see this controller's own Turbo lifecycle note) and so cannot itself
  // hold that cache across navigations. Guards against a stale response landing after the
  // visitor has already left SEARCH (Esc, or a Turbo navigation reconnecting a new
  // controller instance).
  loadSearchIndex() {
    fetchSearchIndex()
      .then((index) => {
        if (this.modeValue !== "search") return

        this.searchIndex = index
        this.filterSearchResults()
      })
      .catch(() => {
        if (this.modeValue !== "search") return

        this.setCommandFeedback("search index unavailable")
      })
  }

  // Live-filter/rank as the visitor types (spec R7); rankSearchResults (search_index.js)
  // is the same "one pure ranking function, unit-tested independently" discipline
  // rankCommands already established for COMMAND. Before the index has loaded, shows a
  // loading state rather than nothing; an empty/whitespace query renders the full,
  // just-loaded index unranked (rankSearchResults' own empty-query convention), so SEARCH
  // shows its whole result set immediately once open, narrowing as the visitor types.
  filterSearchResults() {
    if (!this.searchIndex) {
      this.setCommandFeedback("Loading search index…")
      return
    }

    const results = rankSearchResults(this.commandInputTarget.value, this.searchIndex)
    this.renderSearchResults(results)
  }

  // Renders each result as a real, rendered <a href> (never a hand-built href -- each
  // item's `url` was already built server-side via post_url/project_url, R9) so Enter's
  // .click() (commitSearch) is a genuine link activation, exactly like resolveNavTarget's
  // own .click()-the-real-anchor pattern (Decision 6). The first result is highlighted by
  // default so n/N and Enter are meaningful the instant results appear, with no extra key
  // required to "start" browsing.
  renderSearchResults(results) {
    this.currentSearchResults = results
    this.highlightedSearchIndex = results.length > 0 ? 0 : -1

    if (this.hasSearchResultsTarget) {
      this.searchResultsTarget.innerHTML = ""

      results.forEach((item, index) => {
        const li = document.createElement("li")
        const link = document.createElement("a")

        link.href = item.url
        link.textContent = item.title
        link.dataset.searchResultIndex = String(index)
        link.className = "block px-2 py-1 rounded truncate"

        li.appendChild(link)
        this.searchResultsTarget.appendChild(li)
      })
    }

    this.applySearchHighlight()
    this.setCommandFeedback(results.length > 0 ? "" : "no matching posts or projects")
  }

  applySearchHighlight() {
    if (!this.hasSearchResultsTarget) return

    this.searchResultsTarget.querySelectorAll("a[data-search-result-index]").forEach((link) => {
      const isHighlighted = Number(link.dataset.searchResultIndex) === this.highlightedSearchIndex
      link.parentElement.dataset.searchHighlighted = isHighlighted ? "true" : "false"
      link.classList.toggle("bg-primary/20", isHighlighted)
      link.classList.toggle("text-primary", isHighlighted)
    })
  }

  // n/N (spec R7): move the highlighted selection within the currently-open results list
  // only -- SEARCH-mode-scoped, not a global "repeat last search" (architecture plan
  // Decision 3's explicitly-resolved ambiguity). Wraps at both ends.
  stepSearchSelection(direction) {
    if (!this.currentSearchResults || this.currentSearchResults.length === 0) return

    const count = this.currentSearchResults.length
    this.highlightedSearchIndex = (this.highlightedSearchIndex + direction + count) % count
    this.applySearchHighlight()

    const link = this.highlightedResultLink()
    if (link) link.scrollIntoView({ block: "nearest" })
  }

  // Enter (spec R7): activate the highlighted result via .click() on its real, rendered
  // <a> -- never construct or assign location.href by hand (Decision 3). A no-op if
  // nothing is highlighted (e.g. no results match the current query).
  commitSearch() {
    const link = this.highlightedResultLink()
    if (link) link.click()
  }

  highlightedResultLink() {
    if (!this.hasSearchResultsTarget) return null

    return this.searchResultsTarget.querySelector('[data-search-highlighted="true"] a')
  }

  clearSearchResults() {
    this.currentSearchResults = []
    this.highlightedSearchIndex = -1
    if (this.hasSearchResultsTarget) this.searchResultsTarget.innerHTML = ""
  }

  // `f` (NORMAL) -> hint-jump (spec R8, architecture plan Decision 5). A no-op with
  // nothing rendered/entered when there is nothing on screen to hint -- an empty
  // overlay would otherwise leave hint-jump silently "open" with no way to exit other
  // than Esc for no reason. No links currently in the viewport is a documented no-op,
  // exactly like `g l` today (R3/R4).
  enterHintMode() {
    if (this.modeValue !== "normal" || this.hintModeActive) return

    const links = this.collectViewportLinks()
    if (links.length === 0) return

    this.hintModeActive = true
    this.hintTypedInput = ""
    this.hintAssignments = assignHintLabels(links)
    this.renderHintBadges()
    this.setHintStatusQualifier(true)

    // First scroll event cancels hint-jump outright (spec R8: "no live reposition-on-
    // scroll -- named v1 simplification"), rather than recomputing badge positions.
    // {once: true} means this never needs its own removeEventListener call on the
    // normal cancel path (Esc, exact match); cancelHintMode()/disconnect() still null
    // out and remove it defensively for the abnormal path (a Turbo navigation away
    // mid-hint-jump with no scroll ever firing -- see disconnect()'s comment).
    this.boundHandleHintScroll = this.handleHintScroll.bind(this)
    window.addEventListener("scroll", this.boundHandleHintScroll, { passive: true, once: true })
  }

  // Links only, viewport-scoped (architecture plan Decision 5: "matches the issue's own
  // wording ['labels every link on screen']" -- off-screen links are an explicit v1
  // out-of-scope, no scroll-to-reveal). `a[href]` in real DOM order (document order,
  // with no explicit tabindex reordering anywhere on this site, IS tab order) --
  // deterministic, never sorted by visual position. A zero-size getBoundingClientRect
  // at the origin (the value display:none/detached elements report) fails the `bottom >
  // 0`/`right > 0` checks below, so hidden links (e.g. inside the not-currently-open
  // command bar's search results) are naturally excluded with no extra visibility check.
  collectViewportLinks() {
    return Array.from(document.querySelectorAll("a[href]")).filter((link) => {
      const rect = link.getBoundingClientRect()
      return rect.bottom > 0 && rect.right > 0 && rect.top < window.innerHeight && rect.left < window.innerWidth
    })
  }

  // Absolutely (fixed-)positioned via getBoundingClientRect() at each link's own
  // corner (architecture plan Decision 5) -- aria-hidden and pointer-events-none (R11),
  // so a mouse user can still click straight through a badge to the real link
  // underneath, and screen readers never see hint noise layered over their own
  // existing landmark/link navigation. hintBadgesByLabel is keyed for
  // updateHintBadgeVisibility() below to toggle without re-querying the DOM per
  // keystroke.
  renderHintBadges() {
    if (!this.hasHintOverlayTarget) return

    this.hintBadgesByLabel = new Map()

    this.hintAssignments.forEach(({ element, label }) => {
      const rect = element.getBoundingClientRect()
      const badge = document.createElement("span")

      badge.textContent = label
      badge.setAttribute("aria-hidden", "true")
      badge.dataset.hintLabel = label
      badge.className =
        "fixed z-50 pointer-events-none font-mono text-[11px] font-semibold leading-none " +
        "px-1 py-0.5 rounded bg-primary text-primary-content"
      badge.style.left = `${rect.left}px`
      badge.style.top = `${rect.top}px`

      this.hintOverlayTarget.appendChild(badge)
      this.hintBadgesByLabel.set(label, badge)
    })
  }

  removeHintBadges() {
    if (this.hasHintOverlayTarget) this.hintOverlayTarget.innerHTML = ""
    this.hintBadgesByLabel = null
  }

  // Every keydown while hint-jump is open is typed hint input (handleKeydown routes
  // here instead of dispatchNormalMode while hintModeActive). Non-single-character keys
  // (Tab, arrow keys, etc.) are deliberately left alone -- not preventDefault()'d, not
  // consumed -- since hint-jump moves no focus and traps nothing (R11); Escape never
  // reaches here at all (handled earlier in handleKeydown, before this branch).
  handleHintKeydown(event) {
    if (event.key.length !== 1) return

    event.preventDefault()
    this.hintTypedInput += event.key.toLowerCase()
    this.applyHintFilter()
  }

  // Typing filters to matching hint(s); an exact label match activates immediately
  // (spec R8) -- not "narrows to the last remaining candidate," since a complete,
  // exact-length label can itself be a prefix of a longer two-character code (e.g. "a"
  // vs "aa") and the spec's own wording is "exact match calls .click()," not
  // "narrowing." Typed input matching zero hints at all is treated as invalid input and
  // cancels (mirrors vim's own single-key-mode convention of a wrong key aborting,
  // unlike COMMAND's forgiving free-text "not found" state -- hint-jump's "alphabet" is
  // closed and known in advance, so there is no such thing as a not-yet-complete-but-
  // possibly-valid entry beyond an existing prefix).
  applyHintFilter() {
    const typed = this.hintTypedInput
    const matches = this.hintAssignments.filter((assignment) => assignment.label.startsWith(typed))

    if (matches.length === 0) {
      this.cancelHintMode()
      return
    }

    const exact = matches.find((assignment) => assignment.label === typed)
    if (exact) {
      this.activateHint(exact)
      return
    }

    this.updateHintBadgeVisibility(matches)
  }

  updateHintBadgeVisibility(matches) {
    if (!this.hintBadgesByLabel) return

    const matchingLabels = new Set(matches.map((assignment) => assignment.label))

    this.hintBadgesByLabel.forEach((badge, label) => {
      badge.classList.toggle("hidden", !matchingLabels.has(label))
    })
  }

  // Exact match (spec R8): tear down the overlay/listener first, then .click() the
  // real anchor -- never construct or assign location.href by hand. .click() preserves
  // target="_blank"/rel/Turbo's own link handling/download attributes for free, exactly
  // as a mouse click would (the same "one activation path" discipline navigateTo/
  // commitSearch already established for g-jumps/COMMAND-nav/SEARCH). Cleanup runs
  // before the click, not after, so a Turbo navigation triggered by the click can never
  // race an as-yet-unremoved scroll listener/leftover badge DOM.
  activateHint(assignment) {
    const { element } = assignment
    this.cancelHintMode()
    element.click()
  }

  // Esc, an invalid keystroke, activation, or disconnect() all funnel through here --
  // idempotent (safe to call when hint-jump isn't even open) so every one of those
  // callers can call it unconditionally rather than each re-deriving "is there anything
  // to tear down." Removes every injected badge, with zero leftover focus/tabindex/DOM
  // trace (R8's own acceptance criterion) -- hint-jump never moved focus or set
  // tabindex in the first place (R11), so there is nothing to restore, only the badges/
  // listener/typed-input state this method itself created.
  cancelHintMode() {
    this.hintModeActive = false
    this.hintTypedInput = ""
    this.hintAssignments = []
    this.removeHintBadges()
    this.setHintStatusQualifier(false)

    if (this.boundHandleHintScroll) {
      window.removeEventListener("scroll", this.boundHandleHintScroll)
      this.boundHandleHintScroll = null
    }
  }

  handleHintScroll() {
    // {once: true} (enterHintMode) already detached this listener from `window` by the
    // time it fires -- null it out first so cancelHintMode()'s own removeEventListener
    // is a harmless no-op, not a double-removal.
    this.boundHandleHintScroll = null
    this.cancelHintMode()
  }

  // Direct/synchronous, like exitToNormal()/enterBarMode() -- hint-jump never changes
  // modeValue (spec R8: "mode value stays normal"), so modeValueChanged() never fires
  // for it; this is the one place its status-line/body-dataset reflection happens.
  // document.body.dataset.keyboardHint mirrors keyboardMode's own existing convention,
  // giving CSS/tests a stable hook independent of the status line's exact text.
  setHintStatusQualifier(active) {
    if (this.hasStatusLineTextTarget) {
      this.statusLineTextTarget.textContent = active ? `-- ${this.modeLabel()} -- (HINT)` : `-- ${this.modeLabel()} --`
    }

    document.body.dataset.keyboardHint = active ? "true" : "false"
  }
}
