import { Controller } from "@hotwired/stimulus"

// Live trade + priority suggestion as the user types the defect title/description.
// Debounces, calls /defects/classify, then surfaces suggestion chips with
// "Apply" buttons that fill the trade <select> and priority <select>.
export default class extends Controller {
  static targets  = ["title", "description", "tradeSelect", "prioritySelect", "panel"]
  static values   = { url: String, csrfToken: String }

  connect() {
    this.timer = null
    this.lastText = ""
  }

  schedule() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.classify(), 400)
  }

  async classify() {
    const text = `${this.titleTarget.value} ${this.hasDescriptionTarget ? this.descriptionTarget.value : ""}`.trim()
    if (text.length < 6 || text === this.lastText) return
    this.lastText = text

    try {
      const res = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type":  "application/json",
          "Accept":        "application/json",
          "X-CSRF-Token":  this.csrfTokenValue
        },
        body: JSON.stringify({ title: this.titleTarget.value, description: this.hasDescriptionTarget ? this.descriptionTarget.value : "" })
      })
      if (!res.ok) return
      const data = await res.json()
      this.render(data)
    } catch (e) {
      // network noise — ignore, panel just won't update
    }
  }

  render({ trade_id, trade_name, priority, matched_keywords }) {
    if (!trade_name && !priority) {
      this.panelTarget.classList.add("hidden")
      return
    }

    const chips = []
    if (trade_name) {
      chips.push(`
        <button type="button"
                data-action="defect-classifier#applyTrade"
                data-trade-id="${trade_id || ''}"
                class="inline-flex items-center gap-1.5 rounded-full bg-talent-orange/10 text-talent-orange-700 px-3 py-1.5 text-xs font-semibold hover:bg-talent-orange/20 transition">
          <svg class="h-3 w-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><polyline points="20 6 9 17 4 12"/></svg>
          Trade: ${trade_name}
        </button>
      `)
    }
    if (priority) {
      const colour = priority === "urgent" ? "bg-rose-100 text-rose-700"
                   : priority === "high"   ? "bg-amber-100 text-amber-700"
                   : priority === "medium" ? "bg-talent-blue/15 text-talent-blue"
                   : "bg-emerald-100 text-emerald-700"
      chips.push(`
        <button type="button"
                data-action="defect-classifier#applyPriority"
                data-priority="${priority}"
                class="inline-flex items-center gap-1.5 rounded-full ${colour} px-3 py-1.5 text-xs font-semibold hover:scale-[1.02] transition capitalize">
          <svg class="h-3 w-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><polyline points="20 6 9 17 4 12"/></svg>
          Priority: ${priority}
        </button>
      `)
    }

    const matched = (matched_keywords || []).slice(0, 4)
      .map(k => `<span class="text-[10px] font-mono text-talent-muted">"${k}"</span>`)
      .join(" ")

    this.panelTarget.innerHTML = `
      <div class="flex items-start gap-3">
        <span class="inline-flex h-7 w-7 rounded-lg bg-gradient-to-br from-talent-orange to-talent-orange-600 grid place-items-center text-white text-[10px] font-bold">AI</span>
        <div class="flex-1">
          <div class="text-xs font-semibold text-talent-navy">Suggested classification</div>
          <div class="mt-2 flex flex-wrap gap-2">${chips.join("")}</div>
          ${matched.length ? `<div class="mt-2 flex flex-wrap gap-2">${matched}</div>` : ""}
        </div>
      </div>
    `
    this.panelTarget.classList.remove("hidden")
  }

  applyTrade(event) {
    const id = event.currentTarget.dataset.tradeId
    if (id && this.hasTradeSelectTarget) {
      this.tradeSelectTarget.value = id
      this.tradeSelectTarget.dispatchEvent(new Event("change"))
    }
  }

  applyPriority(event) {
    const p = event.currentTarget.dataset.priority
    if (p && this.hasPrioritySelectTarget) {
      this.prioritySelectTarget.value = p
      this.prioritySelectTarget.dispatchEvent(new Event("change"))
    }
  }
}
