import { mixHex } from "lib/hue_color"
import { lightConstants } from "lib/light_constants"

const ON_CLASS = "is-on"
const OFF_CLASS = "is-off"

const elementsShowing = lightId => document.querySelectorAll(`[data-light-id="${lightId}"]`)

function showAsOn(element) {
  element.classList.remove(OFF_CLASS)
  element.classList.add(ON_CLASS)
}

export function previewLevel(lightId, level) {
  for (const element of elementsShowing(lightId)) {
    element.dataset.brightness = level
    element.style.setProperty("--fill", `${level}%`)
    element.style.setProperty("--bri", level / lightConstants().highestLevel)
    showAsOn(element)
    for (const levelLabel of element.querySelectorAll("[data-level]")) levelLabel.textContent = `${level}%`
  }
}

export function previewColour(lightId, hex) {
  for (const element of elementsShowing(lightId)) {
    const { highestLevel, offTile, glowMinimum } = lightConstants()
    const level = Number(element.dataset.brightness) || highestLevel
    element.style.setProperty("--hue", hex)
    element.style.setProperty("--tile", mixHex(offTile, hex, glowMinimum + (1 - glowMinimum) * level / highestLevel))
    showAsOn(element)
  }
}
