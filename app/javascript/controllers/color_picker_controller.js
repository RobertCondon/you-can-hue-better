import { Controller } from "@hotwired/stimulus"
import { hold, release } from "lib/busy"
import { GAMUT_C } from "lib/hue_color"
import { asyncHueCall } from "lib/hue_calls"
import { isPending } from "lib/light_intents"
import { previewColour, snapshotLight, restoreLight } from "lib/light_preview"
import { showStillChanging } from "lib/toasts"
import { drawColourWheel, drawWhiteRange, colourAt, mirekAt, colourHex, whiteHex, colourMarkerPosition, whiteMarkerPosition } from "lib/color_wheel"

const WHITE_MODE = "ct"
const COLOUR_MODE = "xy"
const CHROMATICITY_DECIMAL_PLACES = 4

export default class extends Controller {
  static targets = ["wheel", "marker", "modeButton", "ends"]
  static values = { id: String, url: String, gamut: Object, x: Number, y: Number, mirek: Number, mode: String }

  connect() {
    if (!this.hasWheelTarget) return
    this.gamut = Object.keys(this.gamutValue).length ? this.gamutValue : GAMUT_C
    this.chromaticity = this.xValue ? { x: this.xValue, y: this.yValue } : null
    this.mirek = this.mirekValue || null
    this.setMode(this.modeValue === WHITE_MODE ? WHITE_MODE : COLOUR_MODE)
  }

  chooseMode(event) {
    this.setMode(event.params.mode)
  }

  setMode(mode) {
    this.mode = mode
    for (const button of this.modeButtonTargets) button.setAttribute("aria-pressed", button.dataset.colorPickerModeParam === mode)
    this.endsTarget.hidden = !this.whiteMode
    this.whiteMode ? drawWhiteRange(this.wheelTarget) : drawColourWheel(this.wheelTarget, this.gamut)
    this.placeMarker()
  }

  down(event) {
    event.target.setPointerCapture(event.pointerId)
    this.beforeDrag = { appearance: snapshotLight(this.idValue), chromaticity: this.chromaticity, mirek: this.mirek }
    this.dragging = true
    hold(this.element)
    this.move(event)
  }

  move(event) {
    if (!this.dragging) return
    const { offsetX, offsetY } = this.offsetFromCentre(event)
    if (this.whiteMode) {
      this.mirek = mirekAt(offsetX)
      previewColour(this.idValue, whiteHex(this.mirek))
    } else {
      this.chromaticity = colourAt(offsetX, offsetY, this.gamut)
      previewColour(this.idValue, colourHex(this.chromaticity))
    }
    this.placeMarker()
  }

  up() {
    if (!this.dragging) return
    this.dragging = false
    release(this.element)
    isPending(this.idValue) ? this.snapBack() : asyncHueCall(this.urlValue, this.chosenFields(), [ this.idValue ])
  }

  chosenFields() {
    return this.whiteMode
      ? { "light[mirek]": this.mirek }
      : { "light[x]": this.chromaticity.x.toFixed(CHROMATICITY_DECIMAL_PLACES), "light[y]": this.chromaticity.y.toFixed(CHROMATICITY_DECIMAL_PLACES) }
  }

  snapBack() {
    restoreLight(this.beforeDrag.appearance)
    this.chromaticity = this.beforeDrag.chromaticity
    this.mirek = this.beforeDrag.mirek
    this.placeMarker()
    showStillChanging()
  }

  get whiteMode() {
    return this.mode === WHITE_MODE
  }

  offsetFromCentre(event) {
    const bounds = this.wheelTarget.getBoundingClientRect()
    return { offsetX: (event.clientX - bounds.left) / bounds.width * 2 - 1, offsetY: (event.clientY - bounds.top) / bounds.height * 2 - 1 }
  }

  placeMarker() {
    const marker = this.markerTarget
    const position = this.whiteMode
      ? this.mirek && whiteMarkerPosition(this.mirek)
      : this.chromaticity && colourMarkerPosition(this.chromaticity)
    marker.hidden = !position
    if (position) Object.assign(marker.style, position)
  }
}
