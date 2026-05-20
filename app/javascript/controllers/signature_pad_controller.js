import { Controller } from "@hotwired/stimulus"

// Minimal pointer-driven signature pad. Renders strokes on a canvas
// and serialises to a base64 PNG into a hidden input on form submit.
export default class extends Controller {
  static targets = ["canvas", "output"]

  connect() {
    this.ctx = this.canvasTarget.getContext("2d")
    this.resize()
    window.addEventListener("resize", this.resize)

    this.drawing = false
    this.canvasTarget.addEventListener("pointerdown", this.start)
    this.canvasTarget.addEventListener("pointermove", this.move)
    window.addEventListener("pointerup",   this.end)
    window.addEventListener("pointerleave",this.end)

    this.element.addEventListener("submit", this.flush)
  }

  disconnect() {
    window.removeEventListener("resize", this.resize)
    window.removeEventListener("pointerup", this.end)
    window.removeEventListener("pointerleave", this.end)
  }

  resize = () => {
    const c   = this.canvasTarget
    const dpr = window.devicePixelRatio || 1
    const rect = c.getBoundingClientRect()
    c.width  = rect.width  * dpr
    c.height = rect.height * dpr
    this.ctx.scale(dpr, dpr)
    this.ctx.lineWidth   = 2
    this.ctx.lineCap     = "round"
    this.ctx.lineJoin    = "round"
    this.ctx.strokeStyle = "#022043"
  }

  pos(e) {
    const rect = this.canvasTarget.getBoundingClientRect()
    return { x: e.clientX - rect.left, y: e.clientY - rect.top }
  }

  start = (e) => {
    e.preventDefault()
    this.drawing = true
    const { x, y } = this.pos(e)
    this.ctx.beginPath()
    this.ctx.moveTo(x, y)
  }

  move = (e) => {
    if (!this.drawing) return
    e.preventDefault()
    const { x, y } = this.pos(e)
    this.ctx.lineTo(x, y)
    this.ctx.stroke()
  }

  end = () => { this.drawing = false }

  clear() {
    this.ctx.clearRect(0, 0, this.canvasTarget.width, this.canvasTarget.height)
    this.outputTarget.value = ""
  }

  flush = () => {
    this.outputTarget.value = this.canvasTarget.toDataURL("image/png")
  }
}
