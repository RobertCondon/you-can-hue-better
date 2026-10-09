import { styleNumber, clampRounded, setStyles } from "lib/floor/element_style"
import { post, patch, destroy } from "lib/requests"
import { pointInPolygon } from "lib/floor_geometry"

const SVG_NAMESPACE = "http://www.w3.org/2000/svg"
const ROOM = "room"
const OUTLINE = "outline"
const DRAWING_CLASS = "is-drawing"
const CLOSABLE_CLASS = "is-closable"
const MINIMUM_POINTS = 3
const CLOSE_LOOP_DISTANCE_PIXELS = 12
const FLOOR_SQUARE_PATH = "M0 0H100V100H0Z"
const FLOOR_EDGE = 100
const LABEL_INSERT_BEFORE = ".floor__object, .floor__lamp"
const VERTEX_ACTIONS = "pointerdown->floor#vertexDown pointermove->floor#vertexMove pointerup->floor#vertexUp pointercancel->floor#vertexUp dblclick->floor#vertexRemove"
const NET_ACTION = "click->floor#selectNet"
const LABEL_ACTION = "floor#frameNet"
const NETS_PATH = "/floor_nets"

const svgPoints = points => points.map(point => point.join(",")).join(" ")
const voidPath = points => `${FLOOR_SQUARE_PATH} M${points.map(point => point.join(" ")).join(" L ")} Z`

export class FloorNetEditor {
  constructor(floor) {
    this.floor = floor
    this.tool = null
    this.draft = []
  }

  get drawing() { return this.tool !== null }
  get viewport() { return this.floor.viewport }

  startTool(tool) {
    if (this.tool === tool) return this.cancelTool()
    this.floor.selection.clear()
    this.tool = tool
    this.draft = []
    for (const button of this.floor.toolButtonTargets) button.setAttribute("aria-pressed", String(button.dataset.floorToolParam === tool))
    this.floor.drawingTarget.hidden = false
    this.floor.drawingHintTarget.textContent = tool === OUTLINE ? this.floor.labels.outlineHint : this.floor.labels.roomHint
    this.floor.element.classList.add(DRAWING_CLASS)
    this.renderDraft()
  }

  cancelTool() {
    this.tool = null
    this.draft = []
    for (const button of this.floor.toolButtonTargets) button.setAttribute("aria-pressed", "false")
    if (this.floor.hasDrawingTarget) this.floor.drawingTarget.hidden = true
    this.floor.element.classList.remove(DRAWING_CLASS)
    this.renderDraft()
  }

  addPoint(event) {
    if (this.closesLoop(event)) return this.closeDraft()
    const point = this.viewport.toWorld(event)
    this.draft.push({ x: this.viewport.snapX(point.x), y: this.viewport.snapY(point.y) })
    this.renderDraft()
  }

  closesLoop(event) {
    if (this.draft.length < MINIMUM_POINTS) return false
    const firstPoint = this.viewport.toClient(this.draft[0])
    return Math.hypot(event.clientX - firstPoint.x, event.clientY - firstPoint.y) < CLOSE_LOOP_DISTANCE_PIXELS
  }

  renderDraft(cursor) {
    if (!this.floor.hasDraftTarget) return
    const points = cursor ? [...this.draft, cursor] : this.draft
    this.floor.draftTarget.hidden = points.length === 0
    this.floor.draftTarget.setAttribute("points", points.map(point => `${point.x},${point.y}`).join(" "))
    this.floor.draftTarget.classList.toggle(CLOSABLE_CLASS, this.draft.length >= MINIMUM_POINTS)
  }

  async closeDraft() {
    if (!this.tool || this.draft.length < MINIMUM_POINTS) return
    const fields = { points: JSON.stringify(this.draft.map(point => [point.x, point.y])) }
    if (this.tool === ROOM) fields.group_id = this.floor.preview.chosenRoomId || ""
    const response = await post(this.floor.netsUrlValue, fields)
    this.cancelTool()
    if (!response.ok) return
    const net = await response.json()
    if (net.kind === OUTLINE) this.polygonsOfKind(OUTLINE).forEach(polygon => polygon.remove())
    this.mount(net)
    this.select(net.id)
    this.floor.lightCanvas.scheduleRedraw()
  }

  mount(net) {
    const polygon = this.polygonFor(net.id) || this.createPolygon()
    polygon.setAttribute("class", `floor__net floor__net--${net.kind}`)
    polygon.id = `floor_net_${net.id}`
    Object.assign(polygon.dataset, {
      floorTarget: "net", id: net.id, kind: net.kind, url: `${NETS_PATH}/${net.id}`, groupId: net.group_id || "",
      label: net.label, points: JSON.stringify(net.points), action: NET_ACTION
    })
    polygon.setAttribute("points", svgPoints(net.points))
    if (net.kind === ROOM) this.mountLabel(net)
    else {
      this.labelFor(net.id)?.remove()
      this.drawVoid(net.points)
    }
  }

  createPolygon() {
    const polygon = document.createElementNS(SVG_NAMESPACE, "polygon")
    this.floor.netsTarget.insertBefore(polygon, this.floor.draftTarget)
    return polygon
  }

  mountLabel(net) {
    const label = this.labelFor(net.id) || this.createLabel(net.id)
    label.textContent = net.label
    label.dataset.groupId = net.group_id || ""
    setStyles(label, { "--x": net.centroid[0], "--y": net.centroid[1] })
  }

  createLabel(netId) {
    const label = document.createElement("button")
    label.type = "button"
    label.className = "floor__netlabel"
    Object.assign(label.dataset, { floorTarget: "netLabel", netId, action: LABEL_ACTION })
    this.floor.worldTarget.insertBefore(label, this.floor.worldTarget.querySelector(LABEL_INSERT_BEFORE))
    return label
  }

  drawVoid(points) {
    if (this.floor.hasVoidTarget) this.floor.voidTarget.setAttribute("d", points ? voidPath(points) : "")
  }

  selectFromClick(event) {
    if (!this.floor.layout.editing || this.drawing) return
    event.stopPropagation()
    this.select(event.currentTarget.dataset.id)
  }

  select(netId) {
    const polygon = this.polygonFor(netId)
    if (!polygon) return this.floor.selection.clear()
    const name = polygon.dataset.kind === OUTLINE ? this.floor.labels.houseOutline : this.floor.labels.netName.replace("%{name}", polygon.dataset.label)
    this.floor.selection.selectNet(polygon, name)
    this.mountVertices(polygon)
  }

  mountVertices(polygon) {
    this.unmountVertices()
    JSON.parse(polygon.dataset.points).forEach(([pointX, pointY], index) => {
      const vertex = document.createElement("button")
      vertex.type = "button"
      vertex.className = "floor__vertex"
      Object.assign(vertex.dataset, { floorTarget: "vertex", index, action: VERTEX_ACTIONS })
      vertex.setAttribute("aria-label", this.floor.labels.point.replace("%{number}", index + 1))
      setStyles(vertex, { "--x": pointX, "--y": pointY })
      this.floor.worldTarget.appendChild(vertex)
    })
  }

  unmountVertices() {
    for (const vertex of this.floor.vertexTargets) vertex.remove()
  }

  startVertexDrag(event) {
    event.preventDefault()
    event.stopPropagation()
    event.currentTarget.setPointerCapture(event.pointerId)
    this.draggedVertex = event.currentTarget
  }

  moveVertex(event) {
    if (this.draggedVertex !== event.currentTarget) return
    const point = this.viewport.toWorld(event)
    setStyles(event.currentTarget, { "--x": clampRounded(point.x, 0, FLOOR_EDGE), "--y": clampRounded(point.y, 0, FLOOR_EDGE) })
    this.applyVertices()
  }

  dropVertex(event) {
    if (this.draggedVertex !== event.currentTarget) return
    this.draggedVertex = null
    const point = this.viewport.toWorld(event)
    setStyles(event.currentTarget, {
      "--x": this.viewport.snapX(clampRounded(point.x, 0, FLOOR_EDGE)),
      "--y": this.viewport.snapY(clampRounded(point.y, 0, FLOOR_EDGE))
    })
    this.applyVertices()
    this.save()
  }

  removeVertex(event) {
    event.preventDefault()
    if (this.floor.vertexTargets.length <= MINIMUM_POINTS) return
    event.currentTarget.remove()
    this.applyVertices()
    this.save()
  }

  applyVertices() {
    const polygon = this.floor.selection.net
    if (!polygon) return
    const points = this.floor.vertexTargets.map(vertex => [styleNumber(vertex, "--x"), styleNumber(vertex, "--y")])
    polygon.dataset.points = JSON.stringify(points)
    polygon.setAttribute("points", svgPoints(points))
    if (polygon.dataset.kind === OUTLINE) this.drawVoid(points)
    this.floor.lightCanvas.scheduleRedraw()
  }

  async save() {
    const polygon = this.floor.selection.net
    if (!polygon) return
    const response = await this.send(polygon, { points: polygon.dataset.points })
    if (response.ok) this.mount(await response.json())
  }

  async assignRoom(groupId) {
    const polygon = this.floor.selection.net
    if (!polygon) return
    const response = await this.send(polygon, { group_id: groupId })
    if (!response.ok) return
    const net = await response.json()
    if (net.kind !== polygon.dataset.kind) {
      polygon.remove()
      this.labelFor(net.id)?.remove()
    }
    this.mount(net)
    this.select(net.id)
  }

  async removeSelected() {
    const polygon = this.floor.selection.net
    await destroy(polygon.dataset.url)
    this.labelFor(polygon.dataset.id)?.remove()
    if (polygon.dataset.kind === OUTLINE) this.drawVoid(null)
    this.floor.selection.clear()
    polygon.remove()
    this.floor.lightCanvas.scheduleRedraw()
  }

  roomOutlineAt(point) {
    const polygon = this.polygonsOfKind(ROOM).find(candidate => pointInPolygon(point, JSON.parse(candidate.dataset.points)))
    return polygon && JSON.parse(polygon.dataset.points)
  }

  pointsOf(netId) {
    const polygon = this.polygonFor(netId)
    return polygon && JSON.parse(polygon.dataset.points)
  }

  send(polygon, fields) {
    return patch(polygon.dataset.url, fields)
  }

  polygonFor(netId) { return this.floor.netTargets.find(polygon => polygon.dataset.id === String(netId)) }
  polygonsOfKind(kind) { return this.floor.netTargets.filter(polygon => polygon.dataset.kind === kind) }
  labelFor(netId) { return this.floor.netLabelTargets.find(label => label.dataset.netId === String(netId)) }
}
