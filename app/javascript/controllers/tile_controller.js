import { Controller } from "@hotwired/stimulus"
import { release } from "lib/busy"

// The tile grammar. Tap the icon to switch, tap the name to open the panel (the light-panel
// controller handles that click), drag sideways across the tile to dim: the fill follows the
// finger and the bridge is told once, on release. A vertical drag is left to the page to scroll.
const START = 8

export default class extends Controller {
  static values = { url: String }

  down(e) {
    if (e.button !== 0 && e.pointerType === "mouse") return
    this.start = { x: e.clientX, y: e.clientY }
    this.dragging = false
  }

  move(e) {
    if (!this.start) return
    const dx = e.clientX - this.start.x, dy = e.clientY - this.start.y
    if (!this.dragging) {
      if (Math.abs(dx) < START || Math.abs(dx) < Math.abs(dy)) return
      this.dragging = true
      this.element.setPointerCapture(e.pointerId)
      this.element.classList.add("is-dragging")
      this.element.dataset.busy = "1"
    }
    this.preview(this.valueAt(e.clientX))
  }

  up(e) {
    if (this.dragging) {
      this.dragged = true
      this.element.classList.remove("is-dragging")
      release(this.element)
      this.send({ "light[brightness]": this.valueAt(e.clientX) })
    }
    this.start = null
    this.dragging = false
  }

  // After a drag the browser still fires a click on whatever is under the pointer; swallow it.
  guard(e) {
    if (!this.dragged) return
    this.dragged = false
    e.stopPropagation(); e.preventDefault()
  }

  toggle(e) {
    e.stopPropagation()
    this.send({ "light[on]": "toggle" })
  }

  valueAt(clientX) {
    const r = this.element.getBoundingClientRect()
    return Math.min(100, Math.max(1, Math.round((clientX - r.left) / r.width * 100)))
  }

  preview(value) {
    const id = this.element.dataset.lightId
    for (const el of document.querySelectorAll(`[data-light-id="${id}"]`)) {
      el.dataset.brightness = value
      el.style.setProperty("--fill", `${value}%`)
      el.style.setProperty("--bri", value / 100)
      el.classList.remove("is-off"); el.classList.add("is-on")
      for (const level of el.querySelectorAll("[data-level]")) level.textContent = `${value}%`
    }
  }

  async send(fields) {
    const body = new FormData()
    for (const [k, v] of Object.entries(fields)) body.append(k, v)
    const res = await fetch(this.urlValue, {
      method: "PATCH", body,
      headers: { Accept: "text/vnd.turbo-stream.html", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
    if (res.ok) Turbo.renderStreamMessage(await res.text())
  }
}
