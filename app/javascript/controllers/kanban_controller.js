import { Controller } from "@hotwired/stimulus"

// Wires SortableJS on every kanban column so cards can be reordered
// within a column and dragged between columns.
//
//   <div data-controller="kanban">
//     <div data-kanban-target="column">
//       <article data-card-id="123">…</article>
//       …
//     </div>
//     <div data-kanban-target="column">…</div>
//   </div>
//
// On drop, the controller dispatches a "kanban:move" CustomEvent on the
// element with `{ cardId, fromColumn, toColumn, newIndex }`. Wire that up
// later to a Turbo Stream update endpoint — for the playground it just logs.
export default class extends Controller {
  static targets = ["column"]

  connect() {
    if (typeof window.Sortable === "undefined") {
      console.warn("kanban_controller: window.Sortable is not loaded")
      return
    }
    this.sortables = this.columnTargets.map((col) =>
      new window.Sortable(col, {
        group:       "kanban",
        animation:   160,
        ghostClass:  "kanban-ghost",
        dragClass:   "kanban-drag",
        chosenClass: "kanban-chosen",
        draggable:   "article",
        forceFallback: true,
        onEnd:       (evt) => this.handleMove(evt)
      })
    )
  }

  disconnect() {
    if (this.sortables) {
      this.sortables.forEach((s) => s.destroy())
      this.sortables = null
    }
  }

  handleMove(evt) {
    const detail = {
      cardId:     evt.item.dataset.cardId,
      fromColumn: evt.from.dataset.columnKey,
      toColumn:   evt.to.dataset.columnKey,
      newIndex:   evt.newIndex
    }
    this.element.dispatchEvent(new CustomEvent("kanban:move", { detail, bubbles: true }))
    if (window.console) console.log("[kanban]", detail)
  }
}
