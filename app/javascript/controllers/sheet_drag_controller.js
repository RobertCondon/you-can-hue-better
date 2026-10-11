import { Controller } from "@hotwired/stimulus"

const DISMISS_DISTANCE = 80
const PRIMARY_BUTTON = 0
const MOUSE = "mouse"
const SETTLE = "transform var(--quick) ease"

// Drag a sheet down by its handle; far enough and it asks to be closed.
export default class extends Controller {
  start(event) {
    if (event.button !== PRIMARY_BUTTON && event.pointerType === MOUSE) return
    this.originY = event.clientY
    this.distance = 0
    event.currentTarget.setPointerCapture(event.pointerId)
    this.element.style.transition = "none"
  }

  move(event) {
    if (this.originY === undefined) return
    this.distance = Math.max(0, event.clientY - this.originY)
    this.element.style.transform = `translateY(${this.distance}px)`
  }

  end() {
    if (this.originY === undefined) return
    const dismissed = this.distance > DISMISS_DISTANCE
    this.originY = undefined
    this.element.style.transition = dismissed ? "" : SETTLE
    this.element.style.transform = ""
    if (dismissed) this.dispatch("dismiss")
  }
}
