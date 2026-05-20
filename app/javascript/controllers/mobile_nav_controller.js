import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "iconOpen", "iconClose"]

  toggle() {
    const open = this.panelTarget.classList.toggle("hidden") === false
    this.iconOpenTarget.classList.toggle("hidden", open)
    this.iconCloseTarget.classList.toggle("hidden", !open)
    document.body.style.overflow = open ? "hidden" : ""
  }
}
