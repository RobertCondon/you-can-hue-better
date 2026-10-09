import { Controller } from "@hotwired/stimulus"
import { hold, release } from "lib/busy"
import { asyncHueCall } from "lib/hue_calls"
import { isPending } from "lib/light_intents"
import { previewLevel, previewPower, snapshotLight, restoreLight } from "lib/light_preview"
import { lightConstants } from "lib/light_constants"
import { showStillChanging } from "lib/toasts"

const DRAG_THRESHOLD = 8
const PRIMARY_BUTTON = 0
const MOUSE = "mouse"
const DRAGGING_CLASS = "is-dragging"
const ON_CLASS = "is-on"

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
    previewLevel(this.lightId, this.levelAt(event.clientX))
  }

  startDragging(event) {
    const distanceX = Math.abs(event.clientX - this.dragOrigin.x), distanceY = Math.abs(event.clientY - this.dragOrigin.y)
    if (distanceX < DRAG_THRESHOLD || distanceX < distanceY) return false
    this.dragging = true
    this.beforeDrag = snapshotLight(this.lightId)
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
      this.finishDrag(this.levelAt(event.clientX))
    }
    this.dragOrigin = null
    this.dragging = false
  }

  finishDrag(level) {
    if (isPending(this.lightId)) {
      restoreLight(this.beforeDrag)
      showStillChanging()
      return
    }
    asyncHueCall(this.urlValue, { "light[brightness]": level }, [ this.lightId ])
  }

  guard(event) {
    if (!this.justDragged) return
    this.justDragged = false
    event.stopPropagation()
    event.preventDefault()
  }

  toggle(event) {
    event.stopPropagation()
    const on = !this.element.classList.contains(ON_CLASS)
    asyncHueCall(this.urlValue, { "light[on]": on }, [ this.lightId ], { guess: () => previewPower(this.lightId, on) })
  }

  get lightId() {
    return this.element.dataset.lightId
  }

  levelAt(clientX) {
    const bounds = this.element.getBoundingClientRect(), { lowestLevel, highestLevel } = lightConstants()
    return Math.min(highestLevel, Math.max(lowestLevel, Math.round((clientX - bounds.left) / bounds.width * highestLevel)))
  }
}
