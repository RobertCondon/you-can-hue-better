const PERCENT_DECIMALS = 100

export const styleNumber = (element, property) => Number(element.style.getPropertyValue(property)) || 0

export const clampRounded = (value, minimum, maximum) => Math.min(maximum, Math.max(minimum, Math.round(value * PERCENT_DECIMALS) / PERCENT_DECIMALS))

export function setStyles(element, properties) {
  for (const [property, value] of Object.entries(properties)) element.style.setProperty(property, value)
}

export const roomIdsOf = lamp => lamp.dataset.rooms.split(" ")

export function snapshotAppearance(element) {
  return { style: element.getAttribute("style"), className: element.className }
}

export function restoreAppearance(element, appearance) {
  element.setAttribute("style", appearance.style)
  element.className = appearance.className
}
