import { Controller } from "@hotwired/stimulus"
import { release } from "lib/busy"
import { hsvToRgb, rgbToHsv, rgbToXy, xyToRgb, rgbToHex, mixHex, clampToGamut, mirekToRgb, GAMUT_C } from "lib/hue_color"

// The colour component inside a light's panel.
// A bulb is in one of two modes, so the picker is too: Colour shows a hue/saturation wheel in which
// every pixel is clamped to the bulb's own gamut; White shows the same circle as a warm-to-cool range.
// Dragging previews on the tile and panel; releasing tells the bridge.
const SIZE = 220, MIREK_MIN = 153, MIREK_MAX = 500, OFF_TILE = "#2b3040"
const wheelCache = new Map()

export default class extends Controller {
  static targets = ["wheel", "marker", "modeButton", "ends"]
  static values = { id: String, url: String, gamut: Object, x: Number, y: Number, mirek: Number, mode: String }

  connect() {
    if (!this.hasWheelTarget) return
    this.light = {
      id: this.idValue, url: this.urlValue, gamut: Object.keys(this.gamutValue).length ? this.gamutValue : GAMUT_C,
      xy: this.xValue ? { x: this.xValue, y: this.yValue } : null, mirek: this.mirekValue || null
    }
    this.setMode(this.modeValue === "ct" ? "ct" : "xy")
  }

  chooseMode(event) { this.setMode(event.params.mode) }

  setMode(mode) {
    this.mode = mode
    for (const b of this.modeButtonTargets) b.setAttribute("aria-pressed", b.dataset.colorPickerModeParam === mode)
    this.endsTarget.hidden = mode !== "ct"
    mode === "ct" ? this.drawWhite() : this.drawColour(this.light.gamut)
    this.placeMarker()
  }

  // ---- pointer: one circle, two meanings ----
  down(e) { e.target.setPointerCapture(e.pointerId); this.dragging = true; this.element.dataset.busy = "1"; this.move(e) }
  move(e) {
    if (!this.dragging) return
    const rect = this.wheelTarget.getBoundingClientRect()
    const dx = (e.clientX - rect.left) / rect.width * 2 - 1, dy = (e.clientY - rect.top) / rect.height * 2 - 1
    if (this.mode === "ct") {
      const t = Math.min(1, Math.max(0, (dx + 1) / 2))
      this.light.mirek = Math.round(MIREK_MAX - t * (MIREK_MAX - MIREK_MIN))
      this.preview(rgbToHex(mirekToRgb(this.light.mirek)))
    } else {
      const s = Math.min(1, Math.hypot(dx, dy))
      let h = Math.atan2(dy, dx) * 180 / Math.PI
      if (h < 0) h += 360
      this.light.xy = clampToGamut(rgbToXy(hsvToRgb(h, s, 1)), this.light.gamut)
      this.preview(rgbToHex(xyToRgb(this.light.xy)))
    }
    this.placeMarker()
  }
  up() {
    if (!this.dragging) return
    this.dragging = false
    release(this.element)
    if (this.mode === "ct") this.commit({ "light[mirek]": this.light.mirek })
    else this.commit({ "light[x]": this.light.xy.x.toFixed(4), "light[y]": this.light.xy.y.toFixed(4) })
  }

  // ---- drawing ----
  placeMarker() {
    const m = this.markerTarget
    if (this.mode === "ct") {
      if (!this.light.mirek) return (m.hidden = true)
      m.style.left = `${100 * (MIREK_MAX - this.light.mirek) / (MIREK_MAX - MIREK_MIN)}%`
      m.style.top = "50%"
    } else {
      if (!this.light.xy) return (m.hidden = true)
      const [h, s] = rgbToHsv(xyToRgb(this.light.xy)), rad = h * Math.PI / 180
      m.style.left = `${50 + 50 * s * Math.cos(rad)}%`
      m.style.top = `${50 + 50 * s * Math.sin(rad)}%`
    }
    m.hidden = false
  }

  preview(hex) {
    for (const el of document.querySelectorAll(`[data-light-id="${this.light.id}"]`)) {
      const bri = Number(el.dataset.brightness) || 100
      el.style.setProperty("--hue", hex)
      el.style.setProperty("--tile", mixHex(OFF_TILE, hex, 0.3 + 0.7 * bri / 100))
      el.classList.remove("is-off"); el.classList.add("is-on")
    }
  }

  async commit(fields) {
    const body = new FormData()
    for (const [k, v] of Object.entries(fields)) body.append(k, v)
    const res = await fetch(this.light.url, {
      method: "PATCH", body,
      headers: { Accept: "text/vnd.turbo-stream.html", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
    if (res.ok) Turbo.renderStreamMessage(await res.text())
  }

  drawColour(gamut) {
    const key = JSON.stringify(gamut)
    if (!wheelCache.has(key)) wheelCache.set(key, this.renderColour(gamut))
    this.wheelTarget.width = this.wheelTarget.height = SIZE
    this.wheelTarget.getContext("2d").putImageData(wheelCache.get(key), 0, 0)
  }

  // Every pixel: hue/saturation -> sRGB -> xy -> clamped into the gamut -> sRGB. Honest colours only.
  renderColour(gamut) {
    const img = new ImageData(SIZE, SIZE), d = img.data, r = SIZE / 2
    for (let py = 0; py < SIZE; py++) {
      for (let px = 0; px < SIZE; px++) {
        const dx = (px + 0.5 - r) / r, dy = (py + 0.5 - r) / r, s = Math.hypot(dx, dy)
        const i = (py * SIZE + px) * 4
        if (s > 1) { d[i + 3] = 0; continue }
        let h = Math.atan2(dy, dx) * 180 / Math.PI
        if (h < 0) h += 360
        const rgb = xyToRgb(clampToGamut(rgbToXy(hsvToRgb(h, s, 1)), gamut))
        d[i] = rgb[0] * 255; d[i + 1] = rgb[1] * 255; d[i + 2] = rgb[2] * 255; d[i + 3] = 255
      }
    }
    return img
  }

  // The same circle as a warm (left) to cool (right) range of whites.
  drawWhite() {
    const c = this.wheelTarget, ctx = c.getContext("2d")
    c.width = c.height = SIZE
    ctx.clearRect(0, 0, SIZE, SIZE)
    ctx.save()
    ctx.beginPath(); ctx.arc(SIZE / 2, SIZE / 2, SIZE / 2, 0, Math.PI * 2); ctx.clip()
    const g = ctx.createLinearGradient(0, 0, SIZE, 0)
    for (let i = 0; i <= 10; i++) g.addColorStop(i / 10, rgbToHex(mirekToRgb(MIREK_MAX - (i / 10) * (MIREK_MAX - MIREK_MIN))))
    ctx.fillStyle = g
    ctx.fillRect(0, 0, SIZE, SIZE)
    ctx.restore()
  }
}
