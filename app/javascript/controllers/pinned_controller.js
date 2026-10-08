import { Controller } from "@hotwired/stimulus"

// Behaviour of the pinned light's bar: expand or collapse the full panel beneath it, close it,
// and a sideways swipe to move to the neighbouring light (the page's light-panel controller decides which).
const SWIPE = 48

export default class extends Controller {
  expand() { this.dock?.classList.toggle("is-expanded") }

  close() {
    this.dispatch("close")
  }

  // A swipe may start on the icon or name (they are most of the bar), but not on the slider or in the sheet.
  swipeStart(e) {
    if (e.target.closest("input, .pin__sheet")) return
    this.swipe = { x: e.clientX, y: e.clientY, id: e.pointerId }
  }
  swipeMove(e) {
    if (!this.swipe || e.pointerId !== this.swipe.id) return
    const dx = e.clientX - this.swipe.x, dy = e.clientY - this.swipe.y
    if (Math.abs(dx) > SWIPE && Math.abs(dx) > Math.abs(dy) * 1.5) {
      this.swiped = true
      this.dispatch("swipe", { detail: { dir: dx < 0 ? 1 : -1 } })
      this.swipe = null
    }
  }
  swipeEnd() { this.swipe = null }
  // The click that follows a swipe must not fire the button it landed on.
  guard(e) { if (this.swiped) { this.swiped = false; e.stopPropagation(); e.preventDefault() } }

  get dock() { return this.element.closest(".dock") }
}
