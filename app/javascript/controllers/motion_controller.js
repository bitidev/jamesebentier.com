import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="motion"
//
// Restrained scroll-triggered fade/slide-in. Elements using this controller start
// visible by default (see the .motion-hidden rule in application.tailwind.css, which is
// itself scoped to `@media (prefers-reduced-motion: no-preference)`) -- this controller
// only *adds* the hidden/offset state on connect(), then removes it once the element
// scrolls into view. That ordering means an element is never hidden without JS having
// actually chosen to hide it, so nothing strands invisible if JS fails to load.
export default class extends Controller {
  connect() {
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    if (prefersReducedMotion) {
      // Render in the final, visible state immediately -- no observer, no delayed
      // appearance, matching the CSS hover-lift's own motion-safe: gating.
      return
    }

    this.element.classList.add("motion-hidden")

    this.observer = new IntersectionObserver(this.handleIntersect.bind(this), {
      threshold: 0.15,
    })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  handleIntersect(entries) {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return

      this.element.classList.remove("motion-hidden")
      this.observer.unobserve(entry.target)
    })
  }
}
