import { linearize, encode, clampFraction } from "lib/color/srgb"

const RGB_TO_XYZ = [
  [0.4124, 0.3576, 0.1805],
  [0.2126, 0.7152, 0.0722],
  [0.0193, 0.1192, 0.9505]
]
const XYZ_TO_RGB = [
  [3.2406, -1.5372, -0.4986],
  [-0.9689, 1.8758, 0.0415],
  [0.0557, -0.204, 1.057]
]
const D65_WHITE_POINT = { x: 0.3127, y: 0.329 }
const FULL_BRIGHTNESS = 1
const NO_LIGHT = 0

const multiply = (matrix, vector) => matrix.map(row => row.reduce((sum, coefficient, index) => sum + coefficient * vector[index], 0))

export function rgbToXy(fractions) {
  const [tristimulusX, tristimulusY, tristimulusZ] = multiply(RGB_TO_XYZ, fractions.map(linearize))
  const total = tristimulusX + tristimulusY + tristimulusZ
  return total === 0 ? { ...D65_WHITE_POINT } : { x: tristimulusX / total, y: tristimulusY / total }
}

export function xyToRgb({ x: chromaticityX, y: chromaticityY }) {
  if (chromaticityY === 0) return [NO_LIGHT, NO_LIGHT, NO_LIGHT]
  const tristimulus = [
    (FULL_BRIGHTNESS / chromaticityY) * chromaticityX,
    FULL_BRIGHTNESS,
    (FULL_BRIGHTNESS / chromaticityY) * (1 - chromaticityX - chromaticityY)
  ]
  let linear = multiply(XYZ_TO_RGB, tristimulus).map(channel => Math.max(NO_LIGHT, channel))
  const brightest = Math.max(...linear)
  if (brightest > FULL_BRIGHTNESS) linear = linear.map(channel => channel / brightest)
  return linear.map(channel => clampFraction(encode(channel)))
}
