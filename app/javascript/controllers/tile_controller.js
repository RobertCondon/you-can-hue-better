import { Controller } from "@hotwired/stimulus"
import { hold, release } from "lib/busy"
import { patchAndRenderStreams } from "lib/requests"
import { previewLevel, LOWEST_LEVEL, HIGHEST_LEVEL } from "lib/light_preview"

const DRAG_THRESHOLD = 8
const PRIMARY_BUTTON = 0
const MOUSE = "mouse"
const DRAGGING_CLASS = "is-dragging"
const TOGGLE = "toggle"

export default class extends Controller {
  static values = { url: String }

  down(event) {
    if (event.button !== PRIMARY_BUTTON && event.pointerType === MOUSE) return
    this.dragOrigin = { x: event.clientX, y: event.clientY }
    this.dragging = false
  }

  move(event) {
    if (!this.dragOrigin) return
    if (!this.dragging && !this.startDragging(event)) return
    previewLevel(this.element.dataset.lightId, this.levelAt(event.clientX))
  }

  startDragging(event) {
    const distanceX = Math.abs(event.clientX - this.dragOrigin.x), distanceY = Math.abs(event.clientY - this.dragOrigin.y)
    if (distanceX < DRAG_THRESHOLD || distanceX < distanceY) return false
    this.dragging = true
    this.element.setPointerCapture(event.pointerId)
    this.element.classList.add(DRAGGING_CLASS)
    hold(this.element)
    return true
  }

  up(event) {
    if (this.dragging) {
      this.justDragged = true
      this.element.classList.remove(DRAGGING_CLASS)
      release(this.element)
      patchAndRenderStreams(this.urlValue, { "light[brightness]": this.levelAt(event.clientX) })
    }
    this.dragOrigin = null
    this.dragging = false
  }

  guard(event) {
    if (!this.justDragged) return
    this.justDragged = false
    event.stopPropagation()
    event.preventDefault()
  }

  toggle(event) {
    event.stopPropagation()
    patchAndRenderStreams(this.urlValue, { "light[on]": TOGGLE })
  }

  levelAt(clientX) {
    const bounds = this.element.getBoundingClientRect()
    return Math.min(HIGHEST_LEVEL, Math.max(LOWEST_LEVEL, Math.round((clientX - bounds.left) / bounds.width * HIGHEST_LEVEL)))
  }
}
