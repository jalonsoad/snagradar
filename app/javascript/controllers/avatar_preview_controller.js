import { Controller } from "@hotwired/stimulus"

// Reads the selected file from a <input type="file"> and updates an <img>
// src with the local data URL so the user sees their picture before saving.
//
// Markup:
//   <div data-controller="avatar-preview">
//     <img data-avatar-preview-target="image" src="…current…">
//     <span data-avatar-preview-target="placeholder">SJ</span>
//     <input type="file" data-action="change->avatar-preview#change">
//   </div>
export default class extends Controller {
  static targets = ["image", "placeholder", "filename"]

  change(event) {
    const file = event.target.files?.[0]
    if (!file) return
    if (!file.type.startsWith("image/")) return
    const url = URL.createObjectURL(file)
    if (this.hasImageTarget) {
      this.imageTarget.src = url
      this.imageTarget.classList.remove("hidden")
    }
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    if (this.hasFilenameTarget)    this.filenameTarget.textContent = `${file.name} · ready to save`
  }
}
