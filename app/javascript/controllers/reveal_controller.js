import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (!("IntersectionObserver" in window)) {
      this.element.classList.add("is-visible")
      return
    }
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          e.target.classList.add("is-visible")
          this.observer.unobserve(e.target)
        }
      })
    }, { rootMargin: "0px 0px -10% 0px", threshold: 0.05 })

    this.element.querySelectorAll(".reveal").forEach(el => this.observer.observe(el))
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
