import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "body", "icon"]

  toggle(event) {
    const item = event.currentTarget.closest("[data-faq-target='item']")
    const body = item.querySelector("[data-faq-target='body']")
    const icon = item.querySelector("[data-faq-target='icon']")
    const open = body.classList.toggle("hidden") === false
    icon.style.transform = open ? "rotate(45deg)" : "rotate(0deg)"
    item.classList.toggle("ring-2", open)
    item.classList.toggle("ring-talent-orange/30", open)
  }
}
