import { clamp, zoomAt, pan, fit, frame, levelFor, toWorld, toScreen } from "lib/floor_camera"
import { boundingBox } from "lib/floor_geometry"

const STORAGE_KEY = "floor:camera:v2"
const ZOOM_STEP = 1.5
const DOUBLE_TAP_ZOOM = 2
const ZOOMED_IN_ENOUGH = 2.9
const WHEEL_SENSITIVITY = 0.01
const PAN_MOVEMENT_THRESHOLD = 2
const TOUCH = "touch"
const GRID_UNIT = 1

export class FloorViewport {
  constructor(floor) {
    this.floor = floor
    this.pointers = new Map()
    this.camera = this.restore() || fit()
  }

  get element() { return this.floor.floorTarget }

  size() {
    const bounds = this.element.getBoundingClientRect()
    return { width: bounds.width, height: bounds.height }
  }

  aspectRatio() {
    const { width, height } = this.size()
    return height > 0 ? width / height : this.floor.aspect
  }

  apply() {
    this.element.style.setProperty("--k", this.camera.zoom)
    this.element.style.setProperty("--tx", `${this.camera.offsetX}px`)
    this.element.style.setProperty("--ty", `${this.camera.offsetY}px`)
    this.element.dataset.level = levelFor(this.camera.zoom)
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(this.camera)) } catch {}
    this.floor.lightCanvas.scheduleRedraw()
    this.floor.lampPanel.reposition()
  }

  restore() {
    try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) } catch { return null }
  }

  set(camera) {
    this.camera = clamp(camera, this.size())
    this.apply()
  }

  zoomIn() { this.zoomAboutCentre(ZOOM_STEP) }
  zoomOut() { this.zoomAboutCentre(1 / ZOOM_STEP) }
  zoomFit() { this.set(fit()) }

  zoomAboutCentre(factor) {
    const size = this.size()
    this.set(zoomAt(this.camera, factor, size.width / 2, size.height / 2, size))
  }

  wheel(event) {
    event.preventDefault()
    const pinching = event.ctrlKey || event.metaKey
    if (pinching) this.zoomAbout(event, Math.exp(-event.deltaY * WHEEL_SENSITIVITY))
    else this.set(pan(this.camera, -event.deltaX, -event.deltaY, this.size()))
  }

  zoomAbout(event, factor) {
    const bounds = this.element.getBoundingClientRect()
    this.set(zoomAt(this.camera, factor, event.clientX - bounds.left, event.clientY - bounds.top, this.size()))
  }

  doubleTap(event, roomOutlineUnderPointer) {
    if (this.camera.zoom >= ZOOMED_IN_ENOUGH) return this.zoomFit()
    if (roomOutlineUnderPointer) return this.frame(roomOutlineUnderPointer)
    this.zoomAbout(event, DOUBLE_TAP_ZOOM)
  }

  frame(points) { this.set(frame(boundingBox(points), this.size())) }

  startGesture(event) {
    this.element.setPointerCapture(event.pointerId)
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY })
    if (this.pointers.size === 1) this.panning = { x: event.clientX, y: event.clientY, moved: false }
    if (this.pointers.size === 2) this.pinch = this.pinchState()
  }

  continueGesture(event) {
    if (!this.pointers.has(event.pointerId)) return
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY })
    if (this.pointers.size >= 2 && this.pinch) this.continuePinch()
    else if (this.panning) this.continuePan(event)
  }

  continuePinch() {
    const current = this.pinchState(), bounds = this.element.getBoundingClientRect(), size = this.size()
    const zoomed = zoomAt(this.camera, current.distance / this.pinch.distance, this.pinch.middle.x - bounds.left, this.pinch.middle.y - bounds.top, size)
    this.set(pan(zoomed, current.middle.x - this.pinch.middle.x, current.middle.y - this.pinch.middle.y, size))
    this.pinch = current
  }

  continuePan(event) {
    const deltaX = event.clientX - this.panning.x, deltaY = event.clientY - this.panning.y
    if (Math.abs(deltaX) + Math.abs(deltaY) > PAN_MOVEMENT_THRESHOLD) this.panning.moved = true
    this.set(pan(this.camera, deltaX, deltaY, this.size()))
    this.panning.x = event.clientX
    this.panning.y = event.clientY
  }

  endGesture(event) {
    this.pointers.delete(event.pointerId)
    if (this.pointers.size < 2) this.pinch = null
    if (this.pointers.size > 0) return
    if (this.panning?.moved) this.clickSuppressed = true
    this.panning = null
  }

  consumeSuppressedClick() {
    if (!this.clickSuppressed) return false
    this.clickSuppressed = false
    return true
  }

  pinchState() {
    const [first, second] = [...this.pointers.values()]
    return {
      distance: Math.hypot(first.x - second.x, first.y - second.y) || 1,
      middle: { x: (first.x + second.x) / 2, y: (first.y + second.y) / 2 }
    }
  }

  isTouch(event) { return event.pointerType === TOUCH }

  toWorld(event) {
    const bounds = this.element.getBoundingClientRect()
    return toWorld(this.camera, event.clientX - bounds.left, event.clientY - bounds.top, this.size())
  }

  toClient(worldPoint) {
    const bounds = this.element.getBoundingClientRect(), onScreen = toScreen(this.camera, worldPoint, this.size())
    return { x: onScreen.x + bounds.left, y: onScreen.y + bounds.top }
  }

  snapX(percent) { return Math.round(percent / GRID_UNIT) * GRID_UNIT }

  snapY(percent) {
    const ratio = this.aspectRatio()
    return Math.round(percent / ratio / GRID_UNIT) * GRID_UNIT * ratio
  }
}
