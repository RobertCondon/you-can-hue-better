import { mixHex } from "lib/hue_color"

export const LOWEST_LEVEL = 1
export const HIGHEST_LEVEL = 100
const OFF_TILE = "#2b3040"
const MINIMUM_COLOUR_STRENGTH = 0.3
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
    element.style.setProperty("--bri", level / HIGHEST_LEVEL)
    showAsOn(element)
    for (const levelLabel of element.querySelectorAll("[data-level]")) levelLabel.textContent = `${level}%`
  }
}

export function previewColour(lightId, hex) {
  for (const element of elementsShowing(lightId)) {
    const level = Number(element.dataset.brightness) || HIGHEST_LEVEL
    element.style.setProperty("--hue", hex)
    element.style.setProperty("--tile", mixHex(OFF_TILE, hex, MINIMUM_COLOUR_STRENGTH + (1 - MINIMUM_COLOUR_STRENGTH) * level / HIGHEST_LEVEL))
    showAsOn(element)
  }
}
