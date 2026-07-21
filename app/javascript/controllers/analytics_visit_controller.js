import { Controller } from "@hotwired/stimulus"

// Module-level: <body> (and this controller) is replaced on every Turbo visit, so a
// per-instance flag would reset before turbo:load fires.
let pendingTurboVisit = false

// Posts a cookieless page-view beacon on Turbo Drive navigations (#1188). Full page loads
// are recorded server-side; this covers in-tab Turbo visits that skip a full round trip.
export default class extends Controller {
  connect() {
    this.boundBeforeVisit = () => {
      pendingTurboVisit = true
    }
    this.boundRecordVisit = this.recordVisit.bind(this)
    document.addEventListener("turbo:before-visit", this.boundBeforeVisit)
    document.addEventListener("turbo:load", this.boundRecordVisit)
  }

  disconnect() {
    if (this.boundBeforeVisit) {
      document.removeEventListener("turbo:before-visit", this.boundBeforeVisit)
      this.boundBeforeVisit = null
    }

    if (this.boundRecordVisit) {
      document.removeEventListener("turbo:load", this.boundRecordVisit)
      this.boundRecordVisit = null
    }
  }

  recordVisit() {
    if (!pendingTurboVisit) return

    pendingTurboVisit = false

    const path = `${window.location.pathname}${window.location.search}`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrfToken) return

    fetch("/analytics/page_views", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({
        path,
        referrer: document.referrer || "",
      }),
      keepalive: true,
    }).catch(() => {
      // Analytics must never surface errors to the visitor.
    })
  }
}
