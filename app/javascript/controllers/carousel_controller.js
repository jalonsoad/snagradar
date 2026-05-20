import { Controller } from "@hotwired/stimulus"

// Simple one-slide-at-a-time carousel with prev/next arrows, dots, and auto-rotate.
// Usage:
//   <div data-controller="carousel" data-carousel-auto-value="true" data-carousel-interval-value="8000">
//     <div data-carousel-target="track" class="flex transition-transform duration-700 ease-out">
//       <article data-carousel-target="slide" class="min-w-full">...</article>
//       <article data-carousel-target="slide" class="min-w-full">...</article>
//     </div>
//     <button data-action="carousel#prev">←</button>
//     <button data-action="carousel#next">→</button>
//     <button data-action="carousel#go" data-index="0" data-carousel-target="dot">·</button>
//   </div>
export default class extends Controller {
  static targets = ["track", "slide", "dot"]
  static values  = {
    index:    { type: Number,  default: 0 },
    auto:     { type: Boolean, default: false },
    interval: { type: Number,  default: 8000 }
  }

  connect() {
    this.render()
    if (this.autoValue) this.start()
    // Pause auto-rotate when the section is off-screen, resume when back
    this.io = new IntersectionObserver(([e]) => {
      if (e.isIntersecting && this.autoValue) this.start()
      else this.stop()
    }, { threshold: 0.25 })
    this.io.observe(this.element)
  }

  disconnect() {
    this.stop()
    if (this.io) this.io.disconnect()
  }

  next() { this.indexValue = (this.indexValue + 1) % this.slideTargets.length; this.bump() }
  prev() { this.indexValue = (this.indexValue - 1 + this.slideTargets.length) % this.slideTargets.length; this.bump() }
  go(e)  { this.indexValue = parseInt(e.currentTarget.dataset.index, 10); this.bump() }

  bump() { this.render(); this.restart() }

  render() {
    this.trackTarget.style.transform = `translateX(-${this.indexValue * 100}%)`
    this.dotTargets.forEach((d, i) => {
      const active = i === this.indexValue
      d.classList.toggle("bg-talent-navy",         active)
      d.classList.toggle("w-8",                    active)
      d.classList.toggle("bg-talent-navy/20",     !active)
      d.classList.toggle("w-2",                   !active)
    })
  }

  start() {
    this.stop()
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  stop()    { if (this.timer) { clearInterval(this.timer); this.timer = null } }
  restart() { if (this.autoValue) this.start() }
}
