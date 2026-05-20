import { Controller } from "@hotwired/stimulus"

// Debounced search dropdown for the topbar input.
// Fires GET /search.json?q=… and renders grouped results below the input.
export default class extends Controller {
  static targets = ["input", "panel", "results"]
  static values  = { url: String }

  connect() { this.timer = null }

  schedule() {
    clearTimeout(this.timer)
    const q = this.inputTarget.value.trim()
    if (q.length < 2) {
      this.hide()
      return
    }
    this.timer = setTimeout(() => this.search(q), 220)
  }

  async search(q) {
    try {
      const url = `${this.urlValue}.json?q=${encodeURIComponent(q)}`
      const res = await fetch(url, { headers: { "Accept": "application/json" } })
      if (!res.ok) return
      this.render(await res.json())
    } catch (e) {}
  }

  render({ defects = [], sites = [] }) {
    if (defects.length === 0 && sites.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="p-4 text-sm text-talent-muted">No matches.</div>`
      this.show()
      return
    }

    const slaPill = (state) => {
      if (state === "red")   return '<span class="sla-red"><span class="dot bg-red-500"></span> overdue</span>'
      if (state === "amber") return '<span class="sla-amber"><span class="dot bg-amber-500"></span> ≤48h</span>'
      if (state === "green") return '<span class="sla-green"><span class="dot bg-emerald-500"></span> on track</span>'
      return ""
    }

    const sections = []

    if (defects.length) {
      sections.push(`
        <div class="px-4 pt-3 pb-1 text-[10px] font-semibold uppercase tracking-widest text-talent-muted">Defects</div>
        <ul class="divide-y divide-talent-navy/5">
          ${defects.map(d => `
            <li>
              <a href="${d.url}" class="flex items-center gap-3 px-4 py-2.5 hover:bg-talent-mist/50 transition">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 text-xs text-talent-muted">
                    <span class="font-mono">${escape(d.reference || "")}</span>
                    ${d.site ? `<span>·</span><span>${escape(d.site)}</span>` : ""}
                    ${d.plot ? `<span>·</span><span>${escape(d.plot)}</span>` : ""}
                  </div>
                  <div class="text-sm font-semibold text-talent-navy truncate">${escape(d.title)}</div>
                </div>
                ${slaPill(d.sla_state)}
              </a>
            </li>`).join("")}
        </ul>`)
    }

    if (sites.length) {
      sections.push(`
        <div class="px-4 pt-3 pb-1 text-[10px] font-semibold uppercase tracking-widest text-talent-muted">Sites</div>
        <ul class="divide-y divide-talent-navy/5">
          ${sites.map(s => `
            <li>
              <a href="/sites/${s.id}" class="flex items-center gap-3 px-4 py-2.5 hover:bg-talent-mist/50 transition">
                <span class="h-7 w-7 rounded-lg bg-talent-blue/15 text-talent-blue grid place-items-center">
                  <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18M5 21V8l7-5 7 5v13M9 21v-6h6v6"/></svg>
                </span>
                <div class="flex-1 min-w-0">
                  <div class="text-sm font-semibold text-talent-navy truncate">${escape(s.name)}</div>
                  ${s.reference ? `<div class="text-xs text-talent-muted font-mono">${escape(s.reference)}</div>` : ""}
                </div>
              </a>
            </li>`).join("")}
        </ul>`)
    }

    this.resultsTarget.innerHTML = sections.join("")
    this.show()
  }

  show() { this.panelTarget.classList.remove("hidden") }
  hide() { this.panelTarget.classList.add("hidden") }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.hide()
  }
}

function escape(s) {
  return String(s).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]))
}
