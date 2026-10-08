import { styleNumber, clampRounded, setStyles } from "lib/floor/element_style"
import { patch, formDataFrom } from "lib/requests"

const EDITING_MIN_WIDTH = 900
const EDITING_CLASS = "is-editing"
const UNPLACED_CLASS = "is-unplaced"
const CIRCLE = "circle"
const OBJECT_SELECTOR = ".floor__object"
const LAMP_SELECTOR = ".floor__lamp"
const LAMP_MARGIN = 2
const FLOOR_EDGE = 100
const MINIMUM_SIZE = 1
const OVERHANG = -50
const NUDGE_STEP = 1
const ROTATION_STEP = 15
const ROTATION_SNAP = 5
const FULL_TURN_DEGREES = 360
const QUARTER_TURN_DEGREES = 90
const DEGREES_TO_RADIANS = Math.PI / 180
const NUDGES = { ArrowLeft: [-NUDGE_STEP, 0], ArrowRight: [NUDGE_STEP, 0], ArrowUp: [0, -NUDGE_STEP], ArrowDown: [0, NUDGE_STEP] }
const DELETE_KEYS = ["Delete", "Backspace"]
const ROTATE_KEYS = { "[": -ROTATION_STEP, "]": ROTATION_STEP }

const wholeTurn = degrees => ((degrees % FULL_TURN_DEGREES) + FULL_TURN_DEGREES) % FULL_TURN_DEGREES

export class FloorLayoutEditor {
  constructor(floor) {
    this.floor = floor
    this.editing = false
  }

  get viewport() { return this.floor.viewport }

  toggle() {
    if (window.innerWidth < EDITING_MIN_WIDTH) return
    this.floor.lampPanel.close()
    this.editing = !this.editing
    this.floor.element.classList.toggle(EDITING_CLASS, this.editing)
    this.floor.editButtonTarget.setAttribute("aria-pressed", String(this.editing))
    this.floor.editLabelTarget.textContent = this.editing ? this.floor.labels.done : this.floor.labels.editFloor
    if (this.floor.hasToolsTarget) this.floor.toolsTarget.hidden = !this.editing
    if (!this.editing) {
      this.floor.nets.cancelTool()
      this.floor.selection.clear()
    }
    if (this.editing && this.floor.paint.active) this.floor.paint.toggle()
  }

  startLampDrag(event) {
    if (!this.editing || this.floor.paint.active) return
    event.preventDefault()
    event.stopPropagation()
    event.currentTarget.setPointerCapture(event.pointerId)
    this.drag = { element: event.currentTarget, kind: "lamp" }
  }

  moveLamp(event) {
    if (!this.dragging(event, "lamp")) return
    const point = this.viewport.toWorld(event)
    this.placeLamp(this.drag.element, point.x, point.y)
  }

  dropLamp(event) {
    if (!this.dragging(event, "lamp")) return
    const lamp = this.drag.element
    this.drag = null
    const point = this.viewport.toWorld(event)
    this.placeLamp(lamp, this.viewport.snapX(point.x), this.viewport.snapY(point.y))
    this.saveLamp(lamp)
  }

  nudgeLamp(event) {
    const step = NUDGES[event.key]
    if (!this.editing || !step) return
    event.preventDefault()
    const lamp = event.currentTarget
    this.placeLamp(lamp, styleNumber(lamp, "--x") + step[0], styleNumber(lamp, "--y") + step[1] * this.viewport.aspectRatio())
    this.saveLamp(lamp)
  }

  placeLamp(lamp, percentX, percentY) {
    setStyles(lamp, {
      "--x": clampRounded(percentX, LAMP_MARGIN, FLOOR_EDGE - LAMP_MARGIN),
      "--y": clampRounded(percentY, LAMP_MARGIN, FLOOR_EDGE - LAMP_MARGIN)
    })
    lamp.classList.remove(UNPLACED_CLASS)
    const everyLampPlaced = !this.floor.lightTargets.some(candidate => candidate.classList.contains(UNPLACED_CLASS))
    if (this.floor.hasHintTarget && everyLampPlaced) this.floor.hintTarget.hidden = true
  }

  saveLamp(lamp) {
    patch(this.floor.urlValue, formDataFrom({ light_id: lamp.dataset.lightId, x: styleNumber(lamp, "--x"), y: styleNumber(lamp, "--y") }))
  }

  startObjectMove(event) {
    if (!this.editing) return
    event.preventDefault()
    event.stopPropagation()
    const object = event.currentTarget
    this.floor.selection.selectObject(object)
    object.setPointerCapture(event.pointerId)
    this.drag = { element: object, kind: "move", start: this.viewport.toWorld(event), x: styleNumber(object, "--x"), y: styleNumber(object, "--y") }
  }

  startResize(event) {
    if (!this.editing) return
    event.preventDefault()
    event.stopPropagation()
    const object = event.currentTarget.closest(OBJECT_SELECTOR)
    this.floor.selection.selectObject(object)
    event.currentTarget.setPointerCapture(event.pointerId)
    const ratio = this.viewport.aspectRatio(), angle = styleNumber(object, "--r") * DEGREES_TO_RADIANS
    const width = styleNumber(object, "--w"), height = styleNumber(object, "--h") / ratio
    const centre = { x: styleNumber(object, "--x") + width / 2, y: styleNumber(object, "--y") / ratio + height / 2 }
    const pinnedCorner = {
      x: centre.x - (width / 2) * Math.cos(angle) + (height / 2) * Math.sin(angle),
      y: centre.y - (width / 2) * Math.sin(angle) - (height / 2) * Math.cos(angle)
    }
    this.drag = { element: object, kind: "resize", start: this.viewport.toWorld(event), width, height, angle, pinnedCorner, handle: event.currentTarget }
  }

  startRotate(event) {
    if (!this.editing) return
    event.preventDefault()
    event.stopPropagation()
    const object = event.currentTarget.closest(OBJECT_SELECTOR)
    this.floor.selection.selectObject(object)
    event.currentTarget.setPointerCapture(event.pointerId)
    this.drag = { element: object, kind: "rotate", handle: event.currentTarget }
  }

  continueObjectGesture(event) {
    const drag = this.drag
    if (!this.draggingObject(event)) return
    const point = this.viewport.toWorld(event)
    if (drag.kind === "move") this.placeObject(drag.element, { x: drag.x + point.x - drag.start.x, y: drag.y + point.y - drag.start.y })
    else if (drag.kind === "resize") this.continueResize(drag, point)
    else if (drag.kind === "rotate") this.continueRotate(drag, point)
  }

  continueResize(drag, point) {
    const deltaX = point.x - drag.start.x, deltaY = (point.y - drag.start.y) / this.viewport.aspectRatio()
    const growWidth = deltaX * Math.cos(drag.angle) + deltaY * Math.sin(drag.angle)
    const growHeight = -deltaX * Math.sin(drag.angle) + deltaY * Math.cos(drag.angle)
    this.resizeFromPinnedCorner(drag, drag.width + growWidth, drag.height + growHeight)
  }

  continueRotate(drag, point) {
    const centre = this.centreOf(drag.element)
    const degrees = Math.atan2(point.y / this.viewport.aspectRatio() - centre.y, point.x - centre.x) / DEGREES_TO_RADIANS + QUARTER_TURN_DEGREES
    drag.element.style.setProperty("--r", wholeTurn(Math.round(degrees)))
  }

  endObjectGesture(event) {
    const drag = this.drag
    if (!this.draggingObject(event)) return
    this.drag = null
    const object = drag.element
    if (drag.kind === "rotate") {
      object.style.setProperty("--r", (Math.round(styleNumber(object, "--r") / ROTATION_SNAP) * ROTATION_SNAP) % FULL_TURN_DEGREES)
    } else if (drag.kind === "resize") {
      this.resizeFromPinnedCorner(drag, this.viewport.snapX(styleNumber(object, "--w")), this.viewport.snapX(styleNumber(object, "--h") / this.viewport.aspectRatio()))
    } else {
      this.placeObject(object, { x: this.viewport.snapX(styleNumber(object, "--x")), y: this.viewport.snapY(styleNumber(object, "--y")) })
    }
    this.saveObject(object)
  }

  objectKey(event) {
    if (!this.editing) return
    if (DELETE_KEYS.includes(event.key)) {
      event.preventDefault()
      this.removeObject(event.currentTarget)
    } else if (event.key in ROTATE_KEYS) {
      event.preventDefault()
      this.rotate(event.currentTarget, ROTATE_KEYS[event.key])
    }
  }

  rotateSelected(degrees) {
    if (this.floor.selection.object) this.rotate(this.floor.selection.object, degrees)
  }

  rotate(object, degrees) {
    object.style.setProperty("--r", wholeTurn(styleNumber(object, "--r") + degrees))
    this.saveObject(object)
  }

  resizeFromPinnedCorner(drag, width, height) {
    const ratio = this.viewport.aspectRatio(), object = drag.element
    const newWidth = Math.max(MINIMUM_SIZE, width)
    const newHeight = object.dataset.kind === CIRCLE ? newWidth : Math.max(MINIMUM_SIZE / ratio, height)
    const centreX = drag.pinnedCorner.x + (newWidth / 2) * Math.cos(drag.angle) - (newHeight / 2) * Math.sin(drag.angle)
    const centreY = drag.pinnedCorner.y + (newWidth / 2) * Math.sin(drag.angle) + (newHeight / 2) * Math.cos(drag.angle)
    setStyles(object, {
      "--w": clampRounded(newWidth, MINIMUM_SIZE, FLOOR_EDGE),
      "--h": clampRounded(newHeight * ratio, MINIMUM_SIZE, FLOOR_EDGE),
      "--x": clampRounded(centreX - newWidth / 2, OVERHANG, FLOOR_EDGE),
      "--y": clampRounded((centreY - newHeight / 2) * ratio, OVERHANG, FLOOR_EDGE)
    })
  }

  placeObject(object, { x: percentX, y: percentY } = {}) {
    if (object.dataset.kind === CIRCLE) object.style.setProperty("--h", clampRounded(styleNumber(object, "--w") * this.viewport.aspectRatio(), MINIMUM_SIZE, FLOOR_EDGE))
    if (percentX !== undefined) object.style.setProperty("--x", clampRounded(percentX, 0, FLOOR_EDGE - styleNumber(object, "--w")))
    if (percentY !== undefined) object.style.setProperty("--y", clampRounded(percentY, 0, FLOOR_EDGE - styleNumber(object, "--h")))
  }

  normaliseCircles() {
    for (const object of this.floor.objectTargets) if (object.dataset.kind === CIRCLE) this.placeObject(object)
  }

  async addObject(kind) {
    const response = await fetch(this.floor.objectsUrlValue, { method: "POST", body: formDataFrom({ kind }), headers: this.floor.csrfHeaders })
    if (!response.ok) return
    const html = await response.text()
    const firstLamp = this.floor.worldTarget.querySelector(LAMP_SELECTOR)
    firstLamp ? firstLamp.insertAdjacentHTML("beforebegin", html) : this.floor.worldTarget.insertAdjacentHTML("beforeend", html)
    const object = this.floor.objectTargets.at(-1)
    this.placeObject(object)
    this.floor.selection.selectObject(object)
    object.focus()
  }

  async removeObject(object) {
    await fetch(object.dataset.url, { method: "DELETE", headers: this.floor.csrfHeaders })
    if (this.floor.selection.object === object) this.floor.selection.clear()
    object.remove()
  }

  saveObject(object) {
    patch(object.dataset.url, formDataFrom({
      x: styleNumber(object, "--x"), y: styleNumber(object, "--y"), w: styleNumber(object, "--w"), h: styleNumber(object, "--h"), rotation: styleNumber(object, "--r")
    }))
  }

  setAspect(aspect) {
    this.floor.aspect = aspect
    this.floor.floorTarget.style.setProperty("--aspect", aspect)
    this.normaliseCircles()
    patch(this.floor.urlValue, formDataFrom({ aspect }))
  }

  centreOf(object) {
    return {
      x: styleNumber(object, "--x") + styleNumber(object, "--w") / 2,
      y: (styleNumber(object, "--y") + styleNumber(object, "--h") / 2) / this.viewport.aspectRatio()
    }
  }

  dragging(event, kind) { return this.drag?.element === event.currentTarget && this.drag.kind === kind }

  draggingObject(event) { return this.drag && (this.drag.element === event.currentTarget || this.drag.handle === event.currentTarget) }
}
