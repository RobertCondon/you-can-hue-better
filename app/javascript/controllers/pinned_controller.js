import { Controller } from "@hotwired/stimulus"

const SWIPE_DISTANCE = 48
const HORIZONTAL_BIAS = 1.5
const NEXT = 1
const PREVIOUS = -1
const EXPANDED_CLASS = "is-expanded"
const NOT_SWIPEABLE = "input, .pin__sheet"
const DOCK_SELECTOR = ".dock"

export default class extends Controller {
  expand() {
    this.element.closest(DOCK_SELECTOR)?.classList.toggle(EXPANDED_CLASS)
  }

  close() {
    this.dispatch("close")
  }

  swipeStart(event) {
    if (event.target.closest(NOT_SWIPEABLE)) return
    this.swipeOrigin = { x: event.clientX, y: event.clientY, pointerId: event.pointerId }
  }

  swipeMove(event) {
    if (!this.swipeOrigin || event.pointerId !== this.swipeOrigin.pointerId) return
    const distanceX = event.clientX - this.swipeOrigin.x, distanceY = event.clientY - this.swipeOrigin.y
    if (Math.abs(distanceX) <= SWIPE_DISTANCE || Math.abs(distanceX) <= Math.abs(distanceY) * HORIZONTAL_BIAS) return
    this.swiped = true
    this.dispatch("swipe", { detail: { direction: distanceX < 0 ? NEXT : PREVIOUS } })
    this.swipeOrigin = null
  }

  swipeEnd() {
    this.swipeOrigin = null
  }

  guard(event) {
    if (!this.swiped) return
    this.swiped = false
    event.stopPropagation()
    event.preventDefault()
  }
}
