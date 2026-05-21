import { Controller } from "@hotwired/stimulus"

// Wraps a destructive form (button_to method: :delete, link with turbo-method,
// or any <form>). On submit:
//   1. Prevent the default submit
//   2. Open the shared #global-confirm-modal with the configured message
//   3. On "Yes, confirm" → submit the form programmatically
//   4. On Cancel/Esc/backdrop → abort
//
// Usage:
//   <%= button_to defect_path(d), method: :delete,
//         form: { data: {
//           controller: "confirm",
//           confirm_message_value: "Delete this defect?",
//           action: "submit->confirm#guard"
//         } } %>
export default class extends Controller {
  static values = { message: String }

  guard(event) {
    event.preventDefault()
    event.stopImmediatePropagation()

    const form = this.element.matches("form") ? this.element : this.element.closest("form")
    if (!form) return

    this.#openModal(this.messageValue || "Are you sure?").then((ok) => {
      if (!ok) return
      // Mark form as confirmed so a second submit doesn't re-prompt; Turbo
      // picks the requestSubmit() up like any normal user submission.
      form.dataset.confirmed = "true"
      if (typeof form.requestSubmit === "function") form.requestSubmit()
      else form.submit()
    })
  }

  #openModal(message) {
    return new Promise((resolve) => {
      const modalEl = document.getElementById("global-confirm-modal")
      if (!modalEl) { resolve(window.confirm(message)); return }

      const msgEl = modalEl.querySelector("[data-confirm-message]")
      const yesEl = modalEl.querySelector("[data-confirm-yes]")
      const noEls = Array.from(modalEl.querySelectorAll("[data-confirm-no]"))
      if (msgEl) msgEl.textContent = message

      let instance = window.FlowbiteInstances?.getInstance("Modal", "global-confirm-modal")
      if (!instance && typeof window.Modal === "function") {
        try { instance = new window.Modal(modalEl, { backdrop: "dynamic", closable: true }) }
        catch (_) { /* fall through to manual show */ }
      }
      const showM = () => {
        if (instance) instance.show()
        else {
          modalEl.classList.remove("hidden")
          modalEl.classList.add("flex")
          document.body.classList.add("overflow-hidden")
        }
      }
      const hideM = () => {
        if (instance) instance.hide()
        else {
          modalEl.classList.remove("flex")
          modalEl.classList.add("hidden")
          document.body.classList.remove("overflow-hidden")
        }
      }

      const cleanup = () => {
        yesEl.removeEventListener("click", onYes)
        noEls.forEach((el) => el.removeEventListener("click", onNo))
        document.removeEventListener("keydown", onKey)
      }
      const finish = (result) => { cleanup(); hideM(); resolve(result) }
      const onYes = () => finish(true)
      const onNo  = () => finish(false)
      const onKey = (e) => { if (e.key === "Escape") finish(false) }

      yesEl.addEventListener("click", onYes)
      noEls.forEach((el) => el.addEventListener("click", onNo))
      document.addEventListener("keydown", onKey)
      showM()
    })
  }
}
