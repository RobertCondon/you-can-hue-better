import { hsvToRgb, rgbToHsv, rgbToXy, xyToRgb, rgbToHex, clampToGamut, mirekToRgb } from "lib/hue_color"

export const WHEEL_SIZE = 220
export const WARMEST_MIREK = 500
export const COOLEST_MIREK = 153
const MIREK_SPAN = WARMEST_MIREK - COOLEST_MIREK
const RADIANS_TO_DEGREES = 180 / Math.PI
const FULL_TURN_DEGREES = 360
const FULL_VALUE = 1
const MAX_CHANNEL = 255
const OPAQUE = 255
const TRANSPARENT = 0
const CHANNELS_PER_PIXEL = 4
const PIXEL_CENTRE = 0.5
const WHITE_GRADIENT_STEPS = 10
const CENTRE_PERCENT = 50
const RADIUS_PERCENT = 50
const colourWheels = new Map()

function hueAndSaturationAt(offsetX, offsetY) {
  let hueDegrees = Math.atan2(offsetY, offsetX) * RADIANS_TO_DEGREES
  if (hueDegrees < 0) hueDegrees += FULL_TURN_DEGREES
  return { hueDegrees, saturation: Math.hypot(offsetX, offsetY) }
}

export function colourAt(offsetX, offsetY, gamut) {
  const { hueDegrees, saturation } = hueAndSaturationAt(offsetX, offsetY)
  return clampToGamut(rgbToXy(hsvToRgb(hueDegrees, Math.min(1, saturation), FULL_VALUE)), gamut)
}

export function mirekAt(offsetX) {
  const warmToCool = Math.min(1, Math.max(0, (offsetX + 1) / 2))
  return Math.round(WARMEST_MIREK - warmToCool * MIREK_SPAN)
}

export const whiteHex = mirek => rgbToHex(mirekToRgb(mirek))
export const colourHex = chromaticity => rgbToHex(xyToRgb(chromaticity))

function renderColourWheel(gamut) {
  const image = new ImageData(WHEEL_SIZE, WHEEL_SIZE)
  const pixels = image.data, radius = WHEEL_SIZE / 2
  for (let row = 0; row < WHEEL_SIZE; row++) {
    for (let column = 0; column < WHEEL_SIZE; column++) {
      const offsetX = (column + PIXEL_CENTRE - radius) / radius, offsetY = (row + PIXEL_CENTRE - radius) / radius
      const index = (row * WHEEL_SIZE + column) * CHANNELS_PER_PIXEL
      if (Math.hypot(offsetX, offsetY) > 1) { pixels[index + 3] = TRANSPARENT; continue }
      const [red, green, blue] = xyToRgb(colourAt(offsetX, offsetY, gamut))
      pixels.set([red * MAX_CHANNEL, green * MAX_CHANNEL, blue * MAX_CHANNEL, OPAQUE], index)
    }
  }
  return image
}

export function drawColourWheel(canvas, gamut) {
  const cacheKey = JSON.stringify(gamut)
  if (!colourWheels.has(cacheKey)) colourWheels.set(cacheKey, renderColourWheel(gamut))
  canvas.width = canvas.height = WHEEL_SIZE
  canvas.getContext("2d").putImageData(colourWheels.get(cacheKey), 0, 0)
}

export function drawWhiteRange(canvas) {
  const context = canvas.getContext("2d"), radius = WHEEL_SIZE / 2
  canvas.width = canvas.height = WHEEL_SIZE
  context.clearRect(0, 0, WHEEL_SIZE, WHEEL_SIZE)
  context.save()
  context.beginPath()
  context.arc(radius, radius, radius, 0, Math.PI * 2)
  context.clip()
  const gradient = context.createLinearGradient(0, 0, WHEEL_SIZE, 0)
  for (let step = 0; step <= WHITE_GRADIENT_STEPS; step++) {
    const position = step / WHITE_GRADIENT_STEPS
    gradient.addColorStop(position, whiteHex(WARMEST_MIREK - position * MIREK_SPAN))
  }
  context.fillStyle = gradient
  context.fillRect(0, 0, WHEEL_SIZE, WHEEL_SIZE)
  context.restore()
}

export function whiteMarkerPosition(mirek) {
  return { left: `${100 * (WARMEST_MIREK - mirek) / MIREK_SPAN}%`, top: `${CENTRE_PERCENT}%` }
}

export function colourMarkerPosition(chromaticity) {
  const [hueDegrees, saturation] = rgbToHsv(xyToRgb(chromaticity))
  const angle = hueDegrees / RADIANS_TO_DEGREES
  return { left: `${CENTRE_PERCENT + RADIUS_PERCENT * saturation * Math.cos(angle)}%`, top: `${CENTRE_PERCENT + RADIUS_PERCENT * saturation * Math.sin(angle)}%` }
}
