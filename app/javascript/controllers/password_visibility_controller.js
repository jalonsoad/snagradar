import { Controller } from "@hotwired/stimulus"

// Toggle a password input between type=password and type=text.
// Markup:
//   <div data-controller="password-visibility">
//     <input data-password-visibility-target="input" type="password" …>
//     <button data-action="password-visibility#toggle">
//       <svg data-password-visibility-target="iconShow">…</svg>
//       <svg data-password-visibility-target="iconHide" class="hidden">…</svg>
//     </button>
//   </div>
export default class extends Controller {
  static targets = ["input", "iconShow", "iconHide"]

  toggle(event) {
    event.preventDefault()
    const hidden = this.inputTarget.type === "password"
    this.inputTarget.type = hidden ? "text" : "password"
    this.iconShowTarget.classList.toggle("hidden", hidden)
    this.iconHideTarget.classList.toggle("hidden", !hidden)
  }
}
