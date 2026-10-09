import { Controller } from "@hotwired/stimulus"
import { FloorViewport } from "lib/floor/viewport"
import { FloorLightCanvas } from "lib/floor/light_canvas"
import { FloorSelection } from "lib/floor/selection"
import { FloorLayoutEditor } from "lib/floor/layout_editor"
import { FloorNetEditor } from "lib/floor/net_editor"
import { FloorScenePreview } from "lib/floor/scene_preview"
import { FloorPaintBrush } from "lib/floor/paint_brush"
import { FloorLampPanel } from "lib/floor/lamp_panel"

const DEFAULT_ASPECT = 1
const REDRAW_ON_ATTRIBUTES = ["style", "class"]

export default class extends Controller {
  static targets = [
    "floor", "world", "light", "canvas", "object", "hint", "editButton", "editLabel", "tools", "selection", "selectionName",
    "roomChip", "sceneRow", "sceneChip", "setForm", "popover", "popoverBody", "dock",
    "nets", "net", "netLabel", "draft", "void", "toolButton", "drawing", "drawingHint", "netRoom", "vertex",
    "paintButton", "tray", "swatch", "hueSlider", "trayScene", "trayScenePalette", "trayRecent", "trayRecentPalette", "paintStatus", "paintClear", "paintApply"
  ]
  static values = { url: String, objectsUrl: String, netsUrl: String, paintUrl: String, aspect: Number, labels: Object }

  connect() {
    this.aspect = this.aspectValue || DEFAULT_ASPECT
    this.lightCanvas = new FloorLightCanvas(this)
    this.lampPanel = new FloorLampPanel(this)
    this.viewport = new FloorViewport(this)
    this.selection = new FloorSelection(this)
    this.layout = new FloorLayoutEditor(this)
    this.nets = new FloorNetEditor(this)
    this.preview = new FloorScenePreview(this)
    this.paint = new FloorPaintBrush(this)
    this.viewport.apply()
    this.layout.normaliseCircles()
    this.watchForRedraws()
    this.lightCanvas.redraw()
    this.keyboardShortcuts = event => this.shortcut(event)
    document.addEventListener("keydown", this.keyboardShortcuts)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.mutationObserver?.disconnect()
    document.removeEventListener("keydown", this.keyboardShortcuts)
  }

  get labels() { return this.labelsValue }

  watchForRedraws() {
    this.resizeObserver = new ResizeObserver(() => this.lightCanvas.redraw())
    this.resizeObserver.observe(this.floorTarget)
    this.mutationObserver = new MutationObserver(() => this.lightCanvas.scheduleRedraw())
    this.mutationObserver.observe(this.floorTarget, { childList: true, subtree: true, attributes: true, attributeFilter: REDRAW_ON_ATTRIBUTES })
  }

  shortcut(event) {
    if (event.key === "Escape") this.nets.drawing ? this.nets.cancelTool() : this.lampPanel.close()
    if (event.key === "Enter" && this.nets.drawing) this.nets.closeDraft()
  }

  onBackground(event) {
    return [this.floorTarget, this.canvasTarget, this.worldTarget].includes(event.target)
  }

  zoomIn() { this.viewport.zoomIn() }
  zoomOut() { this.viewport.zoomOut() }
  zoomFit() { this.viewport.zoomFit() }
  wheel(event) { this.viewport.wheel(event) }

  doubleTap(event) {
    if (this.layout.editing) return
    this.viewport.doubleTap(event, this.nets.roomOutlineAt(this.viewport.toWorld(event)))
  }

  frameNet(event) {
    if (this.paint.active) return this.paint.paintRoom(event.currentTarget.dataset.groupId)
    if (this.layout.editing) return
    const points = this.nets.pointsOf(event.currentTarget.dataset.netId)
    if (points) this.viewport.frame(points)
  }

  viewDown(event) {
    if (this.nets.drawing) return
    if (this.paint.active) return this.paint.startSweep(event)
    const background = this.onBackground(event)
    if (this.layout.editing && !background) return
    if (!background && !this.viewport.isTouch(event)) return
    this.viewport.startGesture(event)
  }

  viewMove(event) {
    if (this.paint.active) return this.paint.continueSweep(event)
    if (this.nets.drawing) this.nets.renderDraft(this.viewport.toWorld(event))
    this.viewport.continueGesture(event)
  }

  viewUp(event) {
    if (this.paint.active) this.paint.endSweep()
    this.viewport.endGesture(event)
  }

  floorClick(event) {
    if (this.viewport.consumeSuppressedClick()) return
    if (this.nets.drawing) return this.nets.addPoint(event)
    if (this.onBackground(event) || event.target === this.netsTarget) {
      this.lampPanel.close()
      this.selection.clear()
    }
  }

  toggleEdit() { this.layout.toggle() }
  down(event) { this.layout.startLampDrag(event) }
  move(event) { this.layout.moveLamp(event) }
  up(event) { this.layout.dropLamp(event) }
  nudge(event) { this.layout.nudgeLamp(event) }
  objectDown(event) { this.layout.startObjectMove(event) }
  resizeDown(event) { this.layout.startResize(event) }
  rotateDown(event) { this.layout.startRotate(event) }
  objectMove(event) { this.layout.continueObjectGesture(event) }
  objectUp(event) { this.layout.endObjectGesture(event) }
  objectKey(event) { this.layout.objectKey(event) }
  rotateBy(event) { this.layout.rotateSelected(Number(event.params.degrees)) }
  addObject(event) { this.layout.addObject(event.params.kind) }
  setAspect(event) { this.layout.setAspect(Number(event.target.value)) }

  removeSelected() {
    if (this.selection.net) return this.nets.removeSelected()
    if (this.selection.object) this.layout.removeObject(this.selection.object)
  }

  startTool(event) { this.nets.startTool(event.params.tool) }
  cancelTool() { this.nets.cancelTool() }
  closeDraft() { this.nets.closeDraft() }
  selectNet(event) { this.nets.selectFromClick(event) }
  assignNetRoom(event) { this.nets.assignRoom(event.target.value) }
  vertexDown(event) { this.nets.startVertexDrag(event) }
  vertexMove(event) { this.nets.moveVertex(event) }
  vertexUp(event) { this.nets.dropVertex(event) }
  vertexRemove(event) { this.nets.removeVertex(event) }

  pickRoom(event) { this.preview.pickRoom(event.params.room) }
  pickScene(event) { this.preview.pickScene(event.currentTarget, event.params) }

  togglePaint() { this.paint.toggle() }
  pickPaint(event) { this.paint.pickSwatch(event.currentTarget) }
  pickHue(event) { this.paint.pickHue(event.target) }
  clearPaint() { this.paint.clear() }
  applyPaint() { this.paint.apply() }

  openLight(event) {
    if (this.viewport.consumeSuppressedClick() || this.paint.active || this.layout.editing || !this.hasPopoverTarget) return
    this.lampPanel.toggle(event.currentTarget, event.params.panelUrl)
  }

  closeLight() { this.lampPanel.close() }
  dockClosed() { this.lampPanel.close() }
}
