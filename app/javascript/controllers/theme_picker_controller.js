import { Controller } from "@hotwired/stimulus"

// Single documented localStorage key shared with the render-blocking inline script in
// app/views/layouts/application.html.erb that prevents a flash-of-wrong-theme on load.
const STORAGE_KEY = "theme"
const DEFAULT_THEME = "light"

// Connects to data-controller="theme-picker"
//
// Drives the header's theme switcher: on selection, applies the theme immediately by
// setting document.documentElement.dataset.theme, and persists the choice to
// localStorage so it survives a reload. This controller does not prevent the
// flash-of-wrong-theme itself -- the inline <script> in the layout's <head> does that,
// before Stimulus even boots. connect() only needs to read the already-applied theme
// back into the <select> so the control's own UI reflects reality.
export default class extends Controller {
  static targets = ["select"]

  connect() {
    this.selectTarget.value = document.documentElement.dataset.theme || DEFAULT_THEME
  }

  change() {
    const theme = this.selectTarget.value
    document.documentElement.dataset.theme = theme

    try {
      window.localStorage.setItem(STORAGE_KEY, theme)
    } catch (e) {
      // localStorage can throw in some private-browsing modes. The theme still applies
      // for the rest of this page view via the dataset assignment above; it just won't
      // persist across a reload.
    }
  }
}
