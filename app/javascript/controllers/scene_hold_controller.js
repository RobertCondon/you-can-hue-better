import { Controller } from "@hotwired/stimulus"

const HOLD_MILLISECONDS = 500
const MOVE_TOLERANCE = 10

export default class extends Controller {
  start(event) {
    this.held = false
    this.origin = { x: event.clientX, y: event.clientY }
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.hold(), HOLD_MILLISECONDS)
  }

  move(event) {
    if (!this.origin) return
    if (Math.hypot(event.clientX - this.origin.x, event.clientY - this.origin.y) > MOVE_TOLERANCE) this.cancel()
  }

  cancel() {
    clearTimeout(this.timer)
    this.origin = null
  }

  menu(event) {
    event.preventDefault()
    if (!this.held) this.hold()
  }

  guard(event) {
    if (!this.held) return
    this.held = false
    event.preventDefault()
    event.stopPropagation()
  }

  hold() {
    this.cancel()
    this.held = true
    this.dispatch("edit")
  }
}
