import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse"
export default class extends Controller {
  connect() {
    this.arrowElement   = this.element.querySelector('[data-collapse="arrow"]');
    this.contentElement = this.element.querySelector('[data-collapse="content"]');
  }

  toggle() {
    this.contentElement.classList.toggle('hidden');
    this.arrowElement.classList.toggle('fa-caret-right');
    this.arrowElement.classList.toggle('fa-caret-down');
  }
}
