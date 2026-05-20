import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthly", "yearly", "price", "indicator"]
  static values = { period: { type: String, default: "yearly" } }

  connect() { this.render() }

  set(event) {
    this.periodValue = event.currentTarget.dataset.period
    this.render()
  }

  render() {
    const yearly = this.periodValue === "yearly"
    this.priceTargets.forEach(el => {
      el.textContent = yearly ? el.dataset.yearly : el.dataset.monthly
    })
    this.monthlyTarget.classList.toggle("bg-white", !yearly)
    this.monthlyTarget.classList.toggle("shadow-soft", !yearly)
    this.monthlyTarget.classList.toggle("text-talent-navy", !yearly)
    this.monthlyTarget.classList.toggle("text-talent-muted", yearly)

    this.yearlyTarget.classList.toggle("bg-white", yearly)
    this.yearlyTarget.classList.toggle("shadow-soft", yearly)
    this.yearlyTarget.classList.toggle("text-talent-navy", yearly)
    this.yearlyTarget.classList.toggle("text-talent-muted", !yearly)
  }
}
