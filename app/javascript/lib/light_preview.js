import { mixHex } from "lib/hue_color"
import { lightConstants } from "lib/light_constants"
import { snapshotAppearance, restoreAppearance } from "lib/floor/element_style"

const ON_CLASS = "is-on"
const OFF_CLASS = "is-off"
const LEVEL_SELECTOR = "[data-level]"
const NO_FILL = "0%"

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
    for (const levelLabel of element.querySelectorAll(LEVEL_SELECTOR)) levelLabel.textContent = `${level}%`
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

export function previewPower(lightId, on) {
  for (const element of elementsShowing(lightId)) {
    const look = on ? { style: element.dataset.onStyle, level: element.dataset.onLevel } : { style: element.dataset.offStyle, level: element.dataset.offLevel }
    if (look.style !== undefined) element.setAttribute("style", look.style)
    else element.style.setProperty("--fill", on ? `${element.dataset.brightness}%` : NO_FILL)
    element.classList.toggle(ON_CLASS, on)
    element.classList.toggle(OFF_CLASS, !on)
    if (look.level !== undefined) for (const levelLabel of element.querySelectorAll(LEVEL_SELECTOR)) levelLabel.textContent = look.level
  }
}

export function snapshotLight(lightId) {
  return [...elementsShowing(lightId)].map(element => ({
    element,
    appearance: snapshotAppearance(element),
    brightness: element.dataset.brightness,
    levels: [...element.querySelectorAll(LEVEL_SELECTOR)].map(levelLabel => levelLabel.textContent)
  }))
}

export function restoreLight(snapshot) {
  for (const { element, appearance, brightness, levels } of snapshot) {
    restoreAppearance(element, appearance)
    element.dataset.brightness = brightness
    element.querySelectorAll(LEVEL_SELECTOR).forEach((levelLabel, index) => { levelLabel.textContent = levels[index] })
  }
}
