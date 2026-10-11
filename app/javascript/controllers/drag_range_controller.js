import { Controller } from "@hotwired/stimulus"

const DRAG_THRESHOLD = 8
const PRIMARY_BUTTON = 0
const MOUSE = "mouse"
const DRAGGING_CLASS = "is-dragging"

// A slider that nudges: a sideways drag anywhere on it moves the value by how far the finger
// travels, from wherever it was, instead of jumping to the spot that was pressed.
export default class extends Controller {
  static targets = ["input"]

  down(event) {
    if (event.button !== PRIMARY_BUTTON && event.pointerType === MOUSE) return
    this.origin = { x: event.clientX, y: event.clientY, value: this.inputTarget.valueAsNumber }
    this.dragging = false
  }

  move(event) {
    if (!this.origin) return
    if (!this.dragging && !this.startDragging(event)) return
    const { min, max } = this.limits
    const travelled = (event.clientX - this.origin.x) / this.element.getBoundingClientRect().width
    const value = Math.round(Math.min(max, Math.max(min, this.origin.value + travelled * (max - min))))
    if (value === this.inputTarget.valueAsNumber) return
    this.inputTarget.value = value
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  startDragging(event) {
    const distanceX = Math.abs(event.clientX - this.origin.x), distanceY = Math.abs(event.clientY - this.origin.y)
    if (distanceY > DRAG_THRESHOLD && distanceY > distanceX) this.origin = null
    if (!this.origin || distanceX < DRAG_THRESHOLD || distanceX < distanceY) return false
    this.dragging = true
    this.element.setPointerCapture(event.pointerId)
    this.element.classList.add(DRAGGING_CLASS)
    return true
  }

  up() {
    if (this.dragging) {
      this.element.classList.remove(DRAGGING_CLASS)
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.origin = null
    this.dragging = false
  }

  get limits() {
    return { min: Number(this.inputTarget.min), max: Number(this.inputTarget.max) }
  }
}
