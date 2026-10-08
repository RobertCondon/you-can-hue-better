import { Controller } from "@hotwired/stimulus"
import { release } from "lib/busy"
import { drawFloorLight } from "lib/floor_light"
import { clamp as clampCamera, zoomAt, pan as panCamera, fit as fitCamera, frame as frameCamera, levelFor, toWorld } from "lib/floor_camera"

// The floor. Lights, walls and furniture are positioned HTML elements; the light itself is drawn
// on a canvas underneath from those elements, so anything that moves or changes just redraws.
//
// Edit mode: drag lights and objects, resize from the corner, rotate from the top handle or the
// toolbar, remove the selection. Everything snaps to one unit (a tenth of a grid cell) and saves on drop.
// Preview: swaps the lamps to a scene's state locally; the bulbs are untouched.
const CELL = 10, SNAP = CELL / 10, ROTATE_SNAP = 5

export default class extends Controller {
  static targets = ["floor", "world", "light", "editButton", "editLabel", "tools", "hint", "canvas", "object", "selection", "selectionName", "roomChip", "sceneRow", "sceneChip", "setForm", "popover", "popoverBody",
                    "nets", "net", "netLabel", "draft", "void", "toolButton", "drawing", "drawingHint", "netRoom", "vertex", "dock",
                    "paintButton", "tray", "swatch", "hueSlider", "trayScene", "trayScenePalette", "trayRecent", "trayRecentPalette", "paintStatus", "paintClear", "paintApply"]
  static values = { url: String, objectsUrl: String, netsUrl: String, paintUrl: String, aspect: Number }

  connect() {
    this.aspect = this.aspectValue || 1
    this.camera = this.restoreCamera() || fitCamera()
    this.pointers = new Map()
    this.applyCamera()
    this.normaliseCircles()
    this.resizer = new ResizeObserver(() => this.redraw())
    this.resizer.observe(this.floorTarget)
    this.observer = new MutationObserver(() => this.scheduleRedraw())
    this.observer.observe(this.floorTarget, { childList: true, subtree: true, attributes: true, attributeFilter: ["style", "class"] })
    this.redraw()
    this.onKey = e => {
      if (e.key === "Escape") { this.tool ? this.cancelTool() : this.closeLight() }
      if (e.key === "Enter" && this.tool) this.closeDraft()
    }
    document.addEventListener("keydown", this.onKey)
  }

  disconnect() { this.resizer?.disconnect(); this.observer?.disconnect(); document.removeEventListener("keydown", this.onKey) }

  toggleEdit() {
    if (window.innerWidth < 900) return                                  // editing is a desk job
    this.closeLight()
    this.editing = !this.editing
    this.element.classList.toggle("is-editing", this.editing)
    this.editButtonTarget.setAttribute("aria-pressed", String(this.editing))
    this.editLabelTarget.textContent = this.editing ? "Done" : "Edit floor"
    if (this.hasToolsTarget) this.toolsTarget.hidden = !this.editing
    if (!this.editing) { this.cancelTool(); this.select(null) }
    if (this.editing && this.painting) this.togglePaint()
  }

  // ---- camera: zoom and pan over the world ----
  view() { const r = this.floorTarget.getBoundingClientRect(); return { w: r.width, h: r.height } }
  applyCamera() {
    const c = this.camera, f = this.floorTarget
    f.style.setProperty("--k", c.k); f.style.setProperty("--tx", `${c.tx}px`); f.style.setProperty("--ty", `${c.ty}px`)
    f.dataset.level = levelFor(c.k)
    try { localStorage.setItem("floor:camera", JSON.stringify(c)) } catch {}
    this.scheduleRedraw()
    if (this.openFor) this.positionPopover(this.openFor)
  }
  setCamera(c) { this.camera = clampCamera(c, this.view()); this.applyCamera() }
  restoreCamera() { try { return JSON.parse(localStorage.getItem("floor:camera")) } catch { return null } }
  zoomIn()  { const v = this.view(); this.setCamera(zoomAt(this.camera, 1.5, v.w / 2, v.h / 2, v)) }
  zoomOut() { const v = this.view(); this.setCamera(zoomAt(this.camera, 1 / 1.5, v.w / 2, v.h / 2, v)) }
  zoomFit() { this.setCamera(fitCamera()) }
  wheel(e) {
    e.preventDefault()
    const v = this.view(), r = this.floorTarget.getBoundingClientRect()
    if (e.ctrlKey || e.metaKey) {                                        // pinch on a trackpad, or ctrl + wheel
      this.setCamera(zoomAt(this.camera, Math.exp(-e.deltaY * 0.01), e.clientX - r.left, e.clientY - r.top, v))
    } else {
      this.setCamera(panCamera(this.camera, -e.deltaX, -e.deltaY, v))
    }
  }
  doubleTap(e) {
    if (this.editing) return
    const v = this.view(), r = this.floorTarget.getBoundingClientRect()
    if (this.camera.k >= 2.9) return this.setCamera(fitCamera())
    const w = this.percent(e)
    const net = this.netTargets.find(n => n.dataset.kind === "room" && pointInPolygon(w, JSON.parse(n.dataset.points)))
    if (net) return this.setCamera(frameCamera(bboxOf(JSON.parse(net.dataset.points)), v))
    this.setCamera(zoomAt(this.camera, 2, e.clientX - r.left, e.clientY - r.top, v))
  }
  frameNet(e) {
    if (this.painting) return this.paintRoom(e.currentTarget.dataset.groupId)
    if (this.editing) return
    const net = this.netTargets.find(n => n.dataset.id === e.currentTarget.dataset.netId)
    if (net) this.setCamera(frameCamera(bboxOf(JSON.parse(net.dataset.points)), this.view()))
  }
  // Pointer handling on the viewport itself: one finger pans the background, two fingers pinch.
  // Lamps and objects stop propagation of their own drags while editing.
  viewDown(e) {
    if (this.tool) return
    if (this.painting) return this.sweepStart(e)
    const onBackground = e.target === this.floorTarget || e.target === this.canvasTarget || e.target === this.worldTarget
    if (this.editing && !onBackground) return
    if (!onBackground && e.pointerType !== "touch") return
    this.floorTarget.setPointerCapture(e.pointerId)
    this.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
    if (this.pointers.size === 1) this.panning = { x: e.clientX, y: e.clientY, moved: false }
    if (this.pointers.size === 2) this.pinch = this.pinchState()
  }
  viewMove(e) {
    if (this.painting) return this.sweepMove(e)
    if (this.tool) this.renderDraft(this.percent(e))
    if (!this.pointers.has(e.pointerId)) return
    this.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
    const v = this.view()
    if (this.pointers.size >= 2 && this.pinch) {
      const now = this.pinchState(), r = this.floorTarget.getBoundingClientRect()
      let c = zoomAt(this.camera, now.dist / this.pinch.dist, this.pinch.mid.x - r.left, this.pinch.mid.y - r.top, v)
      c = panCamera(c, now.mid.x - this.pinch.mid.x, now.mid.y - this.pinch.mid.y, v)
      this.setCamera(c); this.pinch = now
    } else if (this.panning) {
      const dx = e.clientX - this.panning.x, dy = e.clientY - this.panning.y
      if (Math.abs(dx) + Math.abs(dy) > 2) this.panning.moved = true
      this.setCamera(panCamera(this.camera, dx, dy, v))
      this.panning.x = e.clientX; this.panning.y = e.clientY
    }
  }
  viewUp(e) {
    if (this.painting) this.sweepEnd()
    this.pointers.delete(e.pointerId)
    if (this.pointers.size < 2) this.pinch = null
    if (this.pointers.size === 0) { if (this.panning?.moved) this.suppressClick = true; this.panning = null }
  }
  pinchState() {
    const [a, b] = [...this.pointers.values()]
    return { dist: Math.hypot(a.x - b.x, a.y - b.y) || 1, mid: { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 } }
  }

  // ---- lights ----
  down(e) {
    if (this.painting) return
    if (!this.editing) return
    e.preventDefault(); e.stopPropagation()
    e.currentTarget.setPointerCapture(e.pointerId)
    this.drag = { el: e.currentTarget, kind: "light" }
  }
  move(e) {
    if (this.drag?.el !== e.currentTarget || this.drag.kind !== "light") return
    const { x, y } = this.percent(e)
    this.placeLight(this.drag.el, x, y)
  }
  up(e) {
    if (this.drag?.el !== e.currentTarget || this.drag.kind !== "light") return
    const el = this.drag.el
    this.drag = null
    const { x, y } = this.percent(e)
    this.placeLight(el, this.snapX(x), this.snapY(y))
    this.patch(this.urlValue, { light_id: el.dataset.lightId, x: cssNum(el, "--x"), y: cssNum(el, "--y") })
  }
  nudge(e) {
    if (!this.editing) return
    const d = { ArrowLeft: [-SNAP, 0], ArrowRight: [SNAP, 0], ArrowUp: [0, -SNAP], ArrowDown: [0, SNAP] }[e.key]
    if (!d) return
    e.preventDefault()
    const el = e.currentTarget
    this.placeLight(el, cssNum(el, "--x") + d[0], cssNum(el, "--y") + d[1] * this.ratio())
    this.patch(this.urlValue, { light_id: el.dataset.lightId, x: cssNum(el, "--x"), y: cssNum(el, "--y") })
  }
  placeLight(el, x, y) {
    el.style.setProperty("--x", clamp(x, 2, 98))
    el.style.setProperty("--y", clamp(y, 2, 98))
    el.classList.remove("is-unplaced")
    if (this.hasHintTarget && !this.lightTargets.some(l => l.classList.contains("is-unplaced"))) this.hintTarget.hidden = true
  }

  // ---- objects: walls and furniture ----
  objectDown(e) {
    if (!this.editing) return
    e.preventDefault(); e.stopPropagation()
    const el = e.currentTarget
    this.select(el)
    el.setPointerCapture(e.pointerId)
    this.drag = { el, kind: "move", start: this.percent(e), x: cssNum(el, "--x"), y: cssNum(el, "--y") }
  }
  resizeDown(e) {
    if (!this.editing) return
    e.preventDefault(); e.stopPropagation()
    const el = e.currentTarget.closest(".floor__object")
    this.select(el)
    e.currentTarget.setPointerCapture(e.pointerId)
    // The corner opposite the handle (the object's own top-left) stays put while the size changes.
    const ratio = this.ratio(), r = (cssNum(el, "--r") * Math.PI) / 180
    const w = cssNum(el, "--w"), h = cssNum(el, "--h") / ratio
    const c = { x: cssNum(el, "--x") + w / 2, y: cssNum(el, "--y") / ratio + h / 2 }
    const pin = { x: c.x + (-w / 2) * Math.cos(r) - (-h / 2) * Math.sin(r), y: c.y + (-w / 2) * Math.sin(r) + (-h / 2) * Math.cos(r) }
    this.drag = { el, kind: "resize", start: this.percent(e), w, h, r, pin, handle: e.currentTarget }
  }
  rotateDown(e) {
    if (!this.editing) return
    e.preventDefault(); e.stopPropagation()
    const el = e.currentTarget.closest(".floor__object")
    this.select(el)
    e.currentTarget.setPointerCapture(e.pointerId)
    this.drag = { el, kind: "rotate", handle: e.currentTarget }
  }
  objectMove(e) {
    const d = this.drag
    if (!d || (d.el !== e.currentTarget && d.handle !== e.currentTarget)) return
    const p = this.percent(e)
    if (d.kind === "move") {
      this.placeObject(d.el, { x: d.x + p.x - d.start.x, y: d.y + p.y - d.start.y })
    } else if (d.kind === "resize") {
      // Resize in the object's own frame so a rotated box grows along its own sides.
      const dx = p.x - d.start.x, dy = (p.y - d.start.y) / this.ratio()        // units
      const lw = dx * Math.cos(d.r) + dy * Math.sin(d.r), lh = -dx * Math.sin(d.r) + dy * Math.cos(d.r)
      this.resizeFromPin(d, d.w + lw, d.h + lh)
    } else if (d.kind === "rotate") {
      const c = this.centre(d.el)
      const deg = (Math.atan2(p.y / this.ratio() - c.y, p.x - c.x) * 180) / Math.PI + 90
      d.el.style.setProperty("--r", ((Math.round(deg) % 360) + 360) % 360)
    }
  }
  objectUp(e) {
    const d = this.drag
    if (!d || (d.el !== e.currentTarget && d.handle !== e.currentTarget)) return
    this.drag = null
    const el = d.el
    if (d.kind === "rotate") {
      el.style.setProperty("--r", (Math.round(cssNum(el, "--r") / ROTATE_SNAP) * ROTATE_SNAP) % 360)
    } else if (d.kind === "resize") {
      this.resizeFromPin(d, this.snapX(cssNum(el, "--w")), this.snapX(cssNum(el, "--h") / this.ratio()))
    } else {
      this.placeObject(el, { x: this.snapX(cssNum(el, "--x")), y: this.snapY(cssNum(el, "--y")) })
    }
    this.save(el)
  }
  objectKey(e) {
    if (!this.editing) return
    if (e.key === "Delete" || e.key === "Backspace") { e.preventDefault(); this.remove(e.currentTarget) }
    if (e.key === "[") { e.preventDefault(); this.rotate(e.currentTarget, -15) }
    if (e.key === "]") { e.preventDefault(); this.rotate(e.currentTarget, 15) }
  }
  rotateBy(e) { if (this.selected) this.rotate(this.selected, Number(e.params.degrees)) }
  rotate(el, by) {
    el.style.setProperty("--r", (((cssNum(el, "--r") + by) % 360) + 360) % 360)
    this.save(el)
  }
  // Apply a new size (in units) keeping the pinned corner exactly where it was.
  resizeFromPin(d, w, h) {
    const ratio = this.ratio()
    w = Math.max(1, w)
    h = d.el.dataset.kind === "circle" ? w : Math.max(1 / ratio, h)
    const cx = d.pin.x + (w / 2) * Math.cos(d.r) - (h / 2) * Math.sin(d.r)
    const cy = d.pin.y + (w / 2) * Math.sin(d.r) + (h / 2) * Math.cos(d.r)
    const el = d.el
    el.style.setProperty("--w", clamp(w, 1, 100))
    el.style.setProperty("--h", clamp(h * ratio, 1, 100))
    el.style.setProperty("--x", clamp(cx - w / 2, -50, 100))
    el.style.setProperty("--y", clamp((cy - h / 2) * ratio, -50, 100))
  }

  placeObject(el, attrs) {
    if (attrs.w !== undefined) el.style.setProperty("--w", clamp(attrs.w, 1, 100))
    if (attrs.h !== undefined) el.style.setProperty("--h", clamp(attrs.h, 1, 100))
    if (el.dataset.kind === "circle") el.style.setProperty("--h", clamp(cssNum(el, "--w") * this.ratio(), 1, 100))
    if (attrs.x !== undefined) el.style.setProperty("--x", clamp(attrs.x, 0, 100 - cssNum(el, "--w")))
    if (attrs.y !== undefined) el.style.setProperty("--y", clamp(attrs.y, 0, 100 - cssNum(el, "--h")))
  }
  normaliseCircles() {
    for (const el of this.objectTargets) if (el.dataset.kind === "circle") this.placeObject(el, {})
  }
  async addObject(e) {
    const body = new FormData(); body.append("kind", e.params.kind)
    const res = await fetch(this.objectsUrlValue, { method: "POST", body, headers: this.headers() })
    if (!res.ok) return
    const first = this.worldTarget.querySelector(".floor__lamp")
    first ? first.insertAdjacentHTML("beforebegin", await res.text()) : this.worldTarget.insertAdjacentHTML("beforeend", await res.text())
    const el = this.objectTargets.at(-1)
    this.placeObject(el, {})
    this.select(el)
    el.focus()
  }
  async removeSelected() {
    if (this.selectedNet) {
      const poly = this.selectedNet
      await fetch(poly.dataset.url, { method: "DELETE", headers: this.headers() })
      this.netLabelTargets.find(l => l.dataset.netId === poly.dataset.id)?.remove()
      if (poly.dataset.kind === "outline" && this.hasVoidTarget) this.voidTarget.setAttribute("d", "")
      poly.remove(); this.select(null); this.scheduleRedraw()
      return
    }
    if (this.selected) this.remove(this.selected)
  }
  async remove(el) {
    await fetch(el.dataset.url, { method: "DELETE", headers: this.headers() })
    if (this.selected === el) this.select(null)
    el.remove()
  }
  select(el) {
    this.selected = el
    if (this.selectedNet) { this.selectedNet.classList.remove("is-selected"); this.selectedNet = null; this.unmountVertices() }
    for (const o of this.objectTargets) o.classList.toggle("is-selected", o === el)
    if (this.hasSelectionTarget) {
      this.selectionTarget.hidden = !el
      if (this.hasNetRoomTarget) this.netRoomTarget.hidden = true
      if (el) this.selectionNameTarget.textContent = el.getAttribute("aria-label")
    }
  }
  save(el) {
    this.patch(el.dataset.url, { x: cssNum(el, "--x"), y: cssNum(el, "--y"), w: cssNum(el, "--w"), h: cssNum(el, "--h"), rotation: cssNum(el, "--r") })
  }

  setAspect(e) {
    this.aspect = Number(e.target.value)
    this.floorTarget.style.setProperty("--aspect", this.aspect)
    this.normaliseCircles()
    this.patch(this.urlValue, { aspect: this.aspect })
  }

  // ---- a light's panel, floating beside it: the same controls as the rows, live ----
  async openLight(e) {
    if (this.suppressClick) { this.suppressClick = false; return }
    if (this.painting) return
    if (this.editing || !this.hasPopoverTarget) return
    const lamp = e.currentTarget
    if (this.openFor === lamp) return this.closeLight()
    const narrow = window.innerWidth < 900 && this.hasDockTarget
    const res = await fetch(narrow ? e.params.panelUrl.replace(/panel$/, "pin") : e.params.panelUrl, { headers: { Accept: "text/html" } })
    if (!res.ok) return
    this.closeLight()
    if (narrow) {
      this.dockTarget.innerHTML = await res.text(); this.dockTarget.hidden = false
    } else {
      this.popoverBodyTarget.innerHTML = await res.text(); this.popoverTarget.hidden = false
    }
    this.openFor = lamp
    for (const l of this.lightTargets) l.classList.toggle("is-open", l === lamp)
    if (!narrow) this.positionPopover(lamp)
  }
  closeLight() {
    if (this.hasDockTarget) { this.dockTarget.innerHTML = ""; this.dockTarget.hidden = true; this.dockTarget.classList.remove("is-expanded") }
    if (this.hasPopoverTarget) { this.popoverTarget.hidden = true; this.popoverBodyTarget.innerHTML = "" }
    this.openFor = null
    for (const l of this.lightTargets) l.classList.remove("is-open")
  }
  dockClosed() { this.closeLight() }
  floorClick(e) {
    if (this.suppressClick) { this.suppressClick = false; return }
    if (this.tool) return this.addPoint(e)
    if (e.target === this.floorTarget || e.target === this.canvasTarget || e.target === this.worldTarget || e.target === this.netsTarget) { this.closeLight(); this.select(null) }
  }

  // ---- nets: closed loops drawn on the floor; the outline also shapes the light ----
  startTool(e) {
    const tool = e.params.tool
    if (this.tool === tool) return this.cancelTool()
    this.select(null)
    this.tool = tool
    this.draft = []
    for (const b of this.toolButtonTargets) b.setAttribute("aria-pressed", String(b.dataset.floorToolParam === tool))
    this.drawingTarget.hidden = false
    this.drawingHintTarget.textContent = tool === "outline" ? "Trace the house: click around its edge, then click the first point to close." : "Click around the room, then click the first point to close."
    this.element.classList.add("is-drawing")
    this.renderDraft()
  }
  cancelTool() {
    this.tool = null; this.draft = []
    for (const b of this.toolButtonTargets) b.setAttribute("aria-pressed", "false")
    if (this.hasDrawingTarget) this.drawingTarget.hidden = true
    this.element.classList.remove("is-drawing")
    this.renderDraft()
  }
  addPoint(e) {
    const w = this.percent(e)
    const first = this.draft[0]
    if (first && this.draft.length >= 3) {
      const r = this.floorTarget.getBoundingClientRect(), v = this.view()
      const fx = first.x / 100 * v.w * this.camera.k + this.camera.tx + r.left, fy = first.y / 100 * v.h * this.camera.k + this.camera.ty + r.top
      if (Math.hypot(e.clientX - fx, e.clientY - fy) < 12) return this.closeDraft()
    }
    this.draft.push({ x: this.snapX(w.x), y: this.snapY(w.y) })
    this.renderDraft()
  }
  renderDraft(cursor) {
    if (!this.hasDraftTarget) return
    const pts = [...(this.draft || []), ...(cursor ? [cursor] : [])]
    this.draftTarget.hidden = pts.length === 0
    this.draftTarget.setAttribute("points", pts.map(p => `${p.x},${p.y}`).join(" "))
    this.draftTarget.classList.toggle("is-closable", (this.draft || []).length >= 3)
  }
  async closeDraft() {
    if (!this.tool || this.draft.length < 3) return
    const body = new FormData()
    body.append("points", JSON.stringify(this.draft.map(p => [p.x, p.y])))
    if (this.tool === "room") body.append("group_id", this.roomChipTargets.find(c => c.getAttribute("aria-pressed") === "true")?.dataset.floorRoomParam || "")
    const res = await fetch(this.netsUrlValue, { method: "POST", body, headers: this.headers() })
    this.cancelTool()
    if (!res.ok) return
    const net = await res.json()
    if (net.kind === "outline") for (const n of this.netTargets) if (n.dataset.kind === "outline") { n.remove() }
    this.mountNet(net)
    this.selectNetById(net.id)
    this.scheduleRedraw()
  }
  // Build a net's polygon (+ label) from its JSON. Used after create and after edits.
  mountNet(net) {
    const ns = "http://www.w3.org/2000/svg"
    let poly = this.netTargets.find(n => n.dataset.id === String(net.id))
    if (!poly) { poly = document.createElementNS(ns, "polygon"); this.netsTarget.insertBefore(poly, this.draftTarget) }
    poly.setAttribute("class", `floor__net floor__net--${net.kind}`)
    poly.id = `floor_net_${net.id}`
    Object.assign(poly.dataset, { floorTarget: "net", id: net.id, kind: net.kind, url: `/floor_nets/${net.id}`, groupId: net.group_id || "", label: net.label, points: JSON.stringify(net.points), action: "click->floor#selectNet" })
    poly.setAttribute("points", net.points.map(p => p.join(",")).join(" "))
    let label = this.netLabelTargets.find(l => l.dataset.netId === String(net.id))
    if (net.kind === "room") {
      if (!label) { label = document.createElement("button"); label.type = "button"; label.className = "floor__netlabel"; label.dataset.floorTarget = "netLabel"; label.dataset.netId = net.id; label.dataset.action = "floor#frameNet"; this.worldTarget.insertBefore(label, this.worldTarget.querySelector(".floor__object, .floor__lamp")) }
      label.textContent = net.label
      label.dataset.groupId = net.group_id || ""
      label.style.setProperty("--x", net.centroid[0]); label.style.setProperty("--y", net.centroid[1])
    } else {
      label?.remove()
      if (this.hasVoidTarget) this.voidTarget.setAttribute("d", `M0 0H100V100H0Z M${net.points.map(p => p.join(" ")).join(" L ")} Z`)
    }
  }
  selectNet(e) {
    if (!this.editing || this.tool) return
    e.stopPropagation()
    this.selectNetById(e.currentTarget.dataset.id)
  }
  selectNetById(id) {
    this.select(null)
    const poly = this.netTargets.find(n => n.dataset.id === String(id))
    if (!poly) return
    this.selectedNet = poly
    poly.classList.add("is-selected")
    this.selectionTarget.hidden = false
    this.selectionNameTarget.textContent = poly.dataset.kind === "outline" ? "House outline" : `Net: ${poly.dataset.label}`
    this.netRoomTarget.hidden = false
    this.netRoomTarget.value = poly.dataset.groupId || ""
    this.mountVertices(poly)
  }
  mountVertices(poly) {
    this.unmountVertices()
    JSON.parse(poly.dataset.points).forEach(([x, y], i) => {
      const v = document.createElement("button")
      v.type = "button"; v.className = "floor__vertex"; v.dataset.floorTarget = "vertex"; v.dataset.index = i
      v.setAttribute("aria-label", `Point ${i + 1}`)
      v.style.setProperty("--x", x); v.style.setProperty("--y", y)
      v.dataset.action = "pointerdown->floor#vertexDown pointermove->floor#vertexMove pointerup->floor#vertexUp pointercancel->floor#vertexUp dblclick->floor#vertexRemove"
      this.worldTarget.appendChild(v)
    })
  }
  unmountVertices() { for (const v of this.vertexTargets) v.remove() }
  vertexDown(e) { e.preventDefault(); e.stopPropagation(); e.currentTarget.setPointerCapture(e.pointerId); this.drag = { el: e.currentTarget, kind: "vertex" } }
  vertexMove(e) {
    if (this.drag?.el !== e.currentTarget || this.drag.kind !== "vertex") return
    const w = this.percent(e)
    e.currentTarget.style.setProperty("--x", clamp(w.x, 0, 100)); e.currentTarget.style.setProperty("--y", clamp(w.y, 0, 100))
    this.applyVertices()
  }
  vertexUp(e) {
    if (this.drag?.el !== e.currentTarget || this.drag.kind !== "vertex") return
    this.drag = null
    const w = this.percent(e)
    e.currentTarget.style.setProperty("--x", this.snapX(clamp(w.x, 0, 100))); e.currentTarget.style.setProperty("--y", this.snapY(clamp(w.y, 0, 100)))
    this.applyVertices(); this.saveNet()
  }
  vertexRemove(e) {
    e.preventDefault()
    if (this.vertexTargets.length <= 3) return
    e.currentTarget.remove()
    this.applyVertices(); this.saveNet()
  }
  applyVertices() {
    const poly = this.selectedNet; if (!poly) return
    const pts = this.vertexTargets.map(v => [cssNum(v, "--x"), cssNum(v, "--y")])
    poly.dataset.points = JSON.stringify(pts)
    poly.setAttribute("points", pts.map(p => p.join(",")).join(" "))
    if (poly.dataset.kind === "outline" && this.hasVoidTarget) this.voidTarget.setAttribute("d", `M0 0H100V100H0Z M${pts.map(p => p.join(" ")).join(" L ")} Z`)
    this.scheduleRedraw()
  }
  async saveNet() {
    const poly = this.selectedNet; if (!poly) return
    const body = new FormData()
    body.append("points", poly.dataset.points)
    const res = await fetch(poly.dataset.url, { method: "PATCH", body, headers: this.headers() })
    if (res.ok) this.mountNet(await res.json())
  }
  async assignNetRoom(e) {
    const poly = this.selectedNet; if (!poly) return
    const body = new FormData(); body.append("group_id", e.target.value)
    const res = await fetch(poly.dataset.url, { method: "PATCH", body, headers: this.headers() })
    if (!res.ok) return
    const net = await res.json()
    if (net.kind !== poly.dataset.kind) { poly.remove(); this.netLabelTargets.find(l => l.dataset.netId === String(net.id))?.remove() }
    this.mountNet(net)
    this.selectNetById(net.id)
  }
  positionPopover(lamp) {
    const wrap = this.element.getBoundingClientRect(), f = this.floorTarget.getBoundingClientRect(), l = lamp.getBoundingClientRect()
    const p = this.popoverTarget, pw = p.offsetWidth, ph = p.offsetHeight, m = 12
    if (window.innerWidth < 640) return                                   // CSS pins it to the bottom of the screen
    const dot = { x: l.left + l.width / 2, y: l.top + 7 }
    let left = dot.x + 18, top = dot.y - 24
    if (left + pw > f.right - m) left = dot.x - 18 - pw                   // no room on the right: go left
    left = Math.max(f.left + m, left)
    top = Math.min(Math.max(f.top + m, top), f.bottom - ph - m)
    p.style.left = `${left - wrap.left}px`
    p.style.top = `${top - wrap.top}px`
  }

  // ---- filters: Everything (live), one room (others greyed), or a scene from that room (its
  // lights as it sets them, every other light greyed). Previewing never touches the bulbs. ----
  pickRoom(e) {
    const room = e.params.room
    this.endPreview()
    this.room = room
    for (const c of this.roomChipTargets) c.setAttribute("aria-pressed", String(c.dataset.floorRoomParam === room))
    for (const row of this.sceneRowTargets) row.hidden = row.dataset.room !== room
    if (room) this.muteExcept(l => l.dataset.rooms.split(" ").includes(room))
  }
  async pickScene(e) {
    const chip = e.currentTarget, wasOn = chip.getAttribute("aria-pressed") === "true"
    this.endPreview()
    if (this.room) this.muteExcept(l => l.dataset.rooms.split(" ").includes(this.room))
    if (wasOn) return

    const res = await fetch(e.params.url, { headers: { Accept: "application/json" } })
    if (!res.ok) return
    const states = Object.fromEntries((await res.json()).map(s => [s.light_id, s]))
    this.original = Object.fromEntries(this.lightTargets.map(l => [l.dataset.lightId, { style: l.getAttribute("style"), cls: l.className }]))
    for (const l of this.lightTargets) {
      const s = states[l.dataset.lightId]
      if (s) {
        l.style.setProperty("--hue", s.hex); l.style.setProperty("--bri", s.bri)
        l.classList.toggle("is-on", s.on); l.classList.toggle("is-off", !s.on)
      }
      l.classList.toggle("is-muted", !s)
      l.dataset.busy = "1"                                   // a live update must not overwrite the preview
    }
    chip.setAttribute("aria-pressed", "true")
    this.element.classList.add("is-previewing")
    this.showScenePalette(e.params.palette || [])
    const form = chip.closest(".chips").querySelector("[data-floor-target=setForm]")
    if (form) { form.action = e.params.setUrl; form.hidden = false }
  }
  muteExcept(keep) {
    for (const l of this.lightTargets) { l.classList.toggle("is-muted", !keep(l)); l.dataset.busy = "1" }
  }
  endPreview() {
    for (const l of this.lightTargets) {
      const o = this.original?.[l.dataset.lightId]
      if (o) { l.setAttribute("style", o.style); l.className = o.cls }
      l.classList.remove("is-muted")
      release(l)
    }
    this.original = null
    this.element.classList.remove("is-previewing")
    for (const c of this.sceneChipTargets) c.setAttribute("aria-pressed", "false")
    for (const f of this.setFormTargets) f.hidden = true
    this.showScenePalette([])
  }

  // ---- paint: pick a colour from the tray, then tap or sweep across lamps, or tap a room's name.
  // Lamps repaint locally; Apply sends once and offers Undo. ----
  togglePaint() {
    this.painting = !this.painting
    if (this.painting && this.editing) this.toggleEdit()
    this.closeLight()
    this.paintButtonTarget.setAttribute("aria-pressed", String(this.painting))
    this.trayTarget.hidden = !this.painting
    this.element.classList.toggle("is-painting", this.painting)
    if (this.painting) { this.strokes = {}; this.renderRecent(); if (!this.brush) this.pickSwatch(this.swatchTargets[1]) }
    else this.clearPaint()
  }
  pickPaint(e) { this.pickSwatch(e.currentTarget) }
  pickSwatch(el) {
    this.brush = { hex: el.dataset.floorHexParam, mirek: el.dataset.floorMirekParam ? Number(el.dataset.floorMirekParam) : null }
    for (const sw of this.element.querySelectorAll(".swatch")) sw.setAttribute("aria-pressed", String(sw === el))
    this.element.style.setProperty("--brush", this.brush.hex)
  }
  pickHue(e) {
    const hex = hueToHex(Number(e.target.value))
    e.target.style.setProperty("--c", hex)
    this.brush = { hex, mirek: null }
    for (const sw of this.element.querySelectorAll(".swatch")) sw.setAttribute("aria-pressed", "false")
    this.element.style.setProperty("--brush", hex)
  }
  showScenePalette(hexes) {
    if (!this.hasTraySceneTarget) return
    this.traySceneTarget.hidden = hexes.length === 0
    this.trayScenePaletteTarget.innerHTML = hexes.map(h => swatchHTML(h)).join("")
  }
  renderRecent() {
    const recent = readRecent()
    this.trayRecentTarget.hidden = recent.length === 0
    this.trayRecentPaletteTarget.innerHTML = recent.map(h => swatchHTML(h)).join("")
  }
  paintLamp(lamp) {
    if (!this.brush || !lamp || lamp.classList.contains("is-muted")) return
    const id = lamp.dataset.lightId
    if (!this.strokes[id]) {
      this.paintOriginal ??= {}
      this.paintOriginal[id] = { style: lamp.getAttribute("style"), cls: lamp.className }
    }
    this.strokes[id] = { light_id: id, hex: this.brush.hex, mirek: this.brush.mirek }
    lamp.style.setProperty("--hue", this.brush.hex)
    if (cssNum(lamp, "--bri") === 0) lamp.style.setProperty("--bri", 0.6)
    lamp.classList.add("is-on", "is-painted"); lamp.classList.remove("is-off")
    lamp.dataset.busy = "1"
    this.renderPaintStatus()
    this.scheduleRedraw()
  }
  paintRoom(groupId) {
    if (!groupId) return
    for (const l of this.lightTargets) if (l.dataset.rooms.split(" ").includes(groupId)) this.paintLamp(l)
  }
  sweepStart(e) {
    this.sweeping = true
    this.paintLamp(e.target.closest(".floor__lamp"))
  }
  sweepMove(e) {
    if (!this.sweeping) return
    this.paintLamp(document.elementFromPoint(e.clientX, e.clientY)?.closest(".floor__lamp"))
  }
  sweepEnd() { this.sweeping = false }
  renderPaintStatus() {
    const n = Object.keys(this.strokes || {}).length
    this.paintStatusTarget.textContent = n ? `${n} painted · tap a room name to paint the whole room` : "Pick a colour, then tap or sweep across lamps. Tap a room name to paint the whole room."
    this.paintClearTarget.hidden = this.paintApplyTarget.hidden = n === 0
  }
  clearPaint() {
    for (const l of this.lightTargets) {
      const o = this.paintOriginal?.[l.dataset.lightId]
      if (o) { l.setAttribute("style", o.style); l.className = o.cls; release(l) }
    }
    this.paintOriginal = null; this.strokes = {}
    if (this.hasPaintStatusTarget) this.renderPaintStatus()
    this.scheduleRedraw()
  }
  async applyPaint() {
    const strokes = Object.values(this.strokes || {})
    if (!strokes.length) return
    const body = new FormData(); body.append("strokes", JSON.stringify(strokes))
    this.paintApplyTarget.disabled = true
    const res = await fetch(this.paintUrlValue, { method: "POST", body, headers: { ...this.headers(), Accept: "text/vnd.turbo-stream.html" } })
    this.paintApplyTarget.disabled = false
    if (!res.ok) return
    rememberRecent(strokes.map(s => s.hex))
    this.endPreview()
    this.clearPaint()
    Turbo.renderStreamMessage(await res.text())
    this.renderRecent()
  }

  // ---- the light itself ----
  scheduleRedraw() {
    cancelAnimationFrame(this.frame)
    this.frame = requestAnimationFrame(() => this.redraw())
  }
  redraw() {
    if (!this.hasCanvasTarget) return
    const c = this.canvasTarget, rect = this.floorTarget.getBoundingClientRect(), dpr = window.devicePixelRatio || 1
    if (rect.width === 0) return
    c.width = Math.round(rect.width * dpr); c.height = Math.round(rect.height * dpr)
    const a = this.ratio()
    const lights = this.lightTargets.filter(l => !l.classList.contains("is-off") && !l.classList.contains("is-muted")).map(l => ({
      x: cssNum(l, "--x"), y: cssNum(l, "--y") / a, hex: l.style.getPropertyValue("--hue").trim() || "#ffd9a0", bri: cssNum(l, "--bri")
    }))
    const walls = this.objectTargets.filter(o => o.dataset.kind === "wall").map(o => ({
      x: cssNum(o, "--x"), y: cssNum(o, "--y") / a, w: cssNum(o, "--w"), h: cssNum(o, "--h") / a, r: cssNum(o, "--r")
    }))
    const outlinePoly = this.hasNetsTarget && this.netTargets.find(n => n.dataset.kind === "outline")
    const outline = outlinePoly ? JSON.parse(outlinePoly.dataset.points).map(([x, y]) => ({ x, y: y / a })) : null
    drawFloorLight(c, { lights, walls, aspect: a, outline, camera: this.camera, dpr })
  }

  // ---- helpers ----
  // The box's real width/height; the geometry must match what is on screen.
  ratio() {
    const r = this.floorTarget.getBoundingClientRect()
    return r.height > 0 ? r.width / r.height : this.aspect
  }
  // Snap in floor units (square cells), then back to percent of each axis.
  snapX(v) { return Math.round(v / SNAP) * SNAP }
  snapY(v) { const u = v / this.ratio(); return Math.round(u / SNAP) * SNAP * this.ratio() }
  centre(el) { return { x: cssNum(el, "--x") + cssNum(el, "--w") / 2, y: (cssNum(el, "--y") + cssNum(el, "--h") / 2) / this.ratio() } }
  percent(e) {
    const r = this.floorTarget.getBoundingClientRect()
    return toWorld(this.camera, e.clientX - r.left, e.clientY - r.top, { w: r.width, h: r.height })
  }
  headers() { return { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content } }
  async patch(url, fields) {
    const body = new FormData()
    for (const [k, v] of Object.entries(fields)) body.append(k, v)
    await fetch(url, { method: "PATCH", body, headers: this.headers() })
  }
}

const cssNum = (el, prop) => Number(el.style.getPropertyValue(prop)) || 0
const hueToHex = h => { const f = n => { const k = (n + h / 60) % 12; const c = 0.5 - 0.5 * Math.max(-1, Math.min(k - 3, 9 - k, 1)); return Math.round(c * 255).toString(16).padStart(2, "0") }; return `#${f(0)}${f(8)}${f(4)}` }
const swatchHTML = hex => `<button type="button" class="swatch" data-action="floor#pickPaint" data-floor-hex-param="${hex}" style="--c: ${hex}" aria-pressed="false" aria-label="${hex}"></button>`
const readRecent = () => { try { return JSON.parse(localStorage.getItem("floor.recent") || "[]") } catch { return [] } }
const rememberRecent = hexes => { try { const list = [...new Set([...hexes, ...readRecent()])].slice(0, 8); localStorage.setItem("floor.recent", JSON.stringify(list)) } catch {} }
const bboxOf = pts => { const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]); const x = Math.min(...xs), y = Math.min(...ys); return { x, y, w: Math.max(...xs) - x, h: Math.max(...ys) - y } }
const pointInPolygon = (p, pts) => { let c = false; for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) { const [ax, ay] = pts[i], [bx, by] = pts[j]; if ((ay > p.y) !== (by > p.y) && p.x < (bx - ax) * (p.y - ay) / (by - ay) + ax) c = !c } return c }
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, Math.round(v * 100) / 100))
