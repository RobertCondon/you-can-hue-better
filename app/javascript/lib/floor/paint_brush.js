import { hold, release } from "lib/busy"
import { styleNumber, roomIdsOf, snapshotAppearance, restoreAppearance } from "lib/floor/element_style"
import { asyncHueCall } from "lib/hue_calls"
import { anyPending } from "lib/light_intents"
import { showStillChanging } from "lib/toasts"

const RECENT_STORAGE_KEY = "floor.recent"
const RECENT_LIMIT = 8
const PAINTING_CLASS = "is-painting"
const PAINTED_CLASS = "is-painted"
const ON_CLASS = "is-on"
const OFF_CLASS = "is-off"
const MUTED_CLASS = "is-muted"
const LAMP_SELECTOR = ".floor__lamp"
const SWATCH_SELECTOR = ".swatch"
const DEFAULT_SWATCH_INDEX = 1
const BRIGHTNESS_FOR_UNLIT_PAINT = 0.6
const DEGREES_PER_HOUR = 30
const HOURS_ON_WHEEL = 12
const RED_HOUR = 0
const GREEN_HOUR = 8
const BLUE_HOUR = 4
const MAX_CHANNEL = 255
const HEX_BASE = 16
const POST = "POST"

function hueToHex(hueDegrees) {
  const channel = startHour => {
    const hour = (startHour + hueDegrees / DEGREES_PER_HOUR) % HOURS_ON_WHEEL
    const level = 0.5 - 0.5 * Math.max(-1, Math.min(hour - 3, 9 - hour, 1))
    return Math.round(level * MAX_CHANNEL).toString(HEX_BASE).padStart(2, "0")
  }
  return `#${channel(RED_HOUR)}${channel(GREEN_HOUR)}${channel(BLUE_HOUR)}`
}

const swatchHtml = hex => `<button type="button" class="swatch" data-action="floor#pickPaint" data-floor-hex-param="${hex}" style="--c: ${hex}" aria-pressed="false" aria-label="${hex}"></button>`

function recentColours() {
  try { return JSON.parse(localStorage.getItem(RECENT_STORAGE_KEY) || "[]") } catch { return [] }
}

function rememberColours(hexes) {
  try { localStorage.setItem(RECENT_STORAGE_KEY, JSON.stringify([...new Set([...hexes, ...recentColours()])].slice(0, RECENT_LIMIT))) } catch {}
}

export class FloorPaintBrush {
  constructor(floor) {
    this.floor = floor
    this.active = false
    this.brush = null
    this.strokes = {}
    this.originalAppearances = {}
  }

  toggle() {
    this.active = !this.active
    if (this.active && this.floor.layout.editing) this.floor.layout.toggle()
    this.floor.lampPanel.close()
    this.floor.paintButtonTarget.setAttribute("aria-pressed", String(this.active))
    this.floor.trayTarget.hidden = !this.active
    this.floor.element.classList.toggle(PAINTING_CLASS, this.active)
    if (!this.active) return this.clear()
    this.strokes = {}
    this.renderRecent()
    if (!this.brush) this.pickSwatch(this.floor.swatchTargets[DEFAULT_SWATCH_INDEX])
  }

  pickSwatch(swatch) {
    this.useBrush({ hex: swatch.dataset.floorHexParam, mirek: swatch.dataset.floorMirekParam ? Number(swatch.dataset.floorMirekParam) : null }, swatch)
  }

  pickHue(slider) {
    const hex = hueToHex(Number(slider.value))
    slider.style.setProperty("--c", hex)
    this.useBrush({ hex, mirek: null }, null)
  }

  useBrush(brush, chosenSwatch) {
    this.brush = brush
    for (const swatch of this.floor.element.querySelectorAll(SWATCH_SELECTOR)) swatch.setAttribute("aria-pressed", String(swatch === chosenSwatch))
    this.floor.element.style.setProperty("--brush", brush.hex)
  }

  showScenePalette(hexes) {
    if (!this.floor.hasTraySceneTarget) return
    this.floor.traySceneTarget.hidden = hexes.length === 0
    this.floor.trayScenePaletteTarget.innerHTML = hexes.map(swatchHtml).join("")
  }

  renderRecent() {
    const recent = recentColours()
    this.floor.trayRecentTarget.hidden = recent.length === 0
    this.floor.trayRecentPaletteTarget.innerHTML = recent.map(swatchHtml).join("")
  }

  paintLamp(lamp) {
    if (!this.brush || !lamp || lamp.classList.contains(MUTED_CLASS)) return
    const lightId = lamp.dataset.lightId
    if (!this.strokes[lightId]) this.originalAppearances[lightId] = snapshotAppearance(lamp)
    this.strokes[lightId] = { light_id: lightId, hex: this.brush.hex, mirek: this.brush.mirek }
    lamp.style.setProperty("--hue", this.brush.hex)
    if (styleNumber(lamp, "--bri") === 0) lamp.style.setProperty("--bri", BRIGHTNESS_FOR_UNLIT_PAINT)
    lamp.classList.add(ON_CLASS, PAINTED_CLASS)
    lamp.classList.remove(OFF_CLASS)
    hold(lamp)
    this.renderStatus()
    this.floor.lightCanvas.scheduleRedraw()
  }

  paintRoom(roomId) {
    if (!roomId) return
    for (const lamp of this.floor.lightTargets) if (roomIdsOf(lamp).includes(roomId)) this.paintLamp(lamp)
  }

  startSweep(event) {
    this.sweeping = true
    this.paintLamp(event.target.closest(LAMP_SELECTOR))
  }

  continueSweep(event) {
    if (this.sweeping) this.paintLamp(document.elementFromPoint(event.clientX, event.clientY)?.closest(LAMP_SELECTOR))
  }

  endSweep() {
    this.sweeping = false
  }

  renderStatus() {
    const paintedCount = Object.keys(this.strokes).length
    this.floor.paintStatusTarget.textContent = paintedCount ? this.floor.labels.painted.replace("%{count}", paintedCount) : this.floor.labels.paintInstructions
    this.floor.paintClearTarget.hidden = this.floor.paintApplyTarget.hidden = paintedCount === 0
  }

  clear() {
    for (const lamp of this.floor.lightTargets) {
      const original = this.originalAppearances[lamp.dataset.lightId]
      if (!original) continue
      restoreAppearance(lamp, original)
      release(lamp)
    }
    this.forgetStrokes()
  }

  async apply() {
    const strokes = Object.values(this.strokes)
    if (!strokes.length) return
    const lightIds = strokes.map(stroke => stroke.light_id)
    if (anyPending(lightIds)) return showStillChanging()
    this.floor.preview.end()
    this.keepStrokesAsGuess()
    rememberColours(strokes.map(stroke => stroke.hex))
    this.renderRecent()
    await asyncHueCall(this.floor.paintUrlValue, { strokes: JSON.stringify(strokes) }, lightIds, { method: POST })
  }

  keepStrokesAsGuess() {
    for (const lamp of this.floor.lightTargets) if (this.originalAppearances[lamp.dataset.lightId]) release(lamp)
    this.forgetStrokes()
  }

  forgetStrokes() {
    this.originalAppearances = {}
    this.strokes = {}
    if (this.floor.hasPaintStatusTarget) this.renderStatus()
    this.floor.lightCanvas.scheduleRedraw()
  }
}
