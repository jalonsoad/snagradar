// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Flowbite — Turbo-compatible UMD bundle. Self-initializes on DOMContentLoaded
// AND re-initializes on turbo:load / turbo:render. Exposes window.Flowbite.
import "flowbite"

// ─── Global confirm modal ─────────────────────────────────────────────
// Every `data-turbo-confirm` in the app dispatches through this method,
// which renders the shared Flowbite confirmation modal instead of the
// browser's native window.confirm(). One modal, every delete confirmation.
const showConfirm = (message) => new Promise((resolve) => {
  const modalEl = document.getElementById("global-confirm-modal")
  if (!modalEl) {
    resolve(window.confirm(message))   // fallback for layouts without the modal
    return
  }

  const msgEl = modalEl.querySelector("[data-confirm-message]")
  const yesEl = modalEl.querySelector("[data-confirm-yes]")
  const noEls = Array.from(modalEl.querySelectorAll("[data-confirm-no]"))
  if (msgEl) msgEl.textContent = message || "Are you sure?"

  // Prefer the Flowbite Modal API when available; fall back to direct DOM
  // manipulation so the modal still works if Flowbite hasn't initialised.
  let instance = window.FlowbiteInstances?.getInstance("Modal", "global-confirm-modal")
  if (!instance && typeof window.Modal === "function") {
    try { instance = new window.Modal(modalEl, { backdrop: "dynamic", closable: true }) }
    catch (e) { console.warn("confirm modal: Flowbite Modal init failed", e) }
  }

  const showModal = () => {
    if (instance) { instance.show(); return }
    // Manual show — matches what Flowbite's Modal.show() does.
    modalEl.classList.remove("hidden")
    modalEl.classList.add("flex")
    modalEl.setAttribute("aria-modal", "true")
    modalEl.setAttribute("role", "dialog")
    document.body.classList.add("overflow-hidden")
  }
  const hideModal = () => {
    if (instance) { instance.hide(); return }
    modalEl.classList.remove("flex")
    modalEl.classList.add("hidden")
    modalEl.removeAttribute("aria-modal")
    modalEl.removeAttribute("role")
    document.body.classList.remove("overflow-hidden")
  }

  const cleanup = () => {
    yesEl.removeEventListener("click", onYes)
    noEls.forEach((el) => el.removeEventListener("click", onNo))
    document.removeEventListener("keydown", onKey)
  }
  const finish = (result) => { cleanup(); hideModal(); resolve(result) }
  const onYes = () => finish(true)
  const onNo  = () => finish(false)
  const onKey = (e) => { if (e.key === "Escape") finish(false) }

  yesEl.addEventListener("click", onYes)
  noEls.forEach((el) => el.addEventListener("click", onNo))
  document.addEventListener("keydown", onKey)

  showModal()
})

// Bind on both initial load and Turbo re-renders so window.Turbo is ready.
const wireConfirm = () => {
  if (window.Turbo?.setConfirmMethod) {
    window.Turbo.setConfirmMethod(showConfirm)
  }
}
document.addEventListener("DOMContentLoaded", wireConfirm)
document.addEventListener("turbo:load", wireConfirm)
wireConfirm()

// ApexCharts — UMD bundle, exposes window.ApexCharts. Used by the Flowbite
// chart components (and rendered through the chart Stimulus controller).
import "apexcharts"

// SortableJS — UMD bundle, exposes window.Sortable. Used by kanban_controller
// to drag cards between columns.
import "sortablejs"
