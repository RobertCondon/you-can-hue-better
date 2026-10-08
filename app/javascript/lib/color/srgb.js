const MAX_CHANNEL = 255
const HEX_PREFIX = "#"
const HEX_BASE = 16
const HEX_DIGITS_PER_CHANNEL = 2
const RED_SHIFT = 16
const GREEN_SHIFT = 8
const CHANNEL_MASK = 0xff
const LINEAR_SEGMENT_LIMIT = 0.04045
const LINEAR_SEGMENT_LIMIT_ENCODED = 0.0031308
const LINEAR_SEGMENT_SLOPE = 12.92
const CURVE_OFFSET = 0.055
const CURVE_SCALE = 1.055
const CURVE_EXPONENT = 2.4

export function linearize(encodedFraction) {
  if (encodedFraction <= LINEAR_SEGMENT_LIMIT) return encodedFraction / LINEAR_SEGMENT_SLOPE
  return Math.pow((encodedFraction + CURVE_OFFSET) / CURVE_SCALE, CURVE_EXPONENT)
}

export function encode(linearFraction) {
  if (linearFraction <= LINEAR_SEGMENT_LIMIT_ENCODED) return LINEAR_SEGMENT_SLOPE * linearFraction
  return CURVE_SCALE * Math.pow(linearFraction, 1 / CURVE_EXPONENT) - CURVE_OFFSET
}

export function rgbToHex(fractions) {
  return HEX_PREFIX + fractions.map(fraction => Math.round(fraction * MAX_CHANNEL).toString(HEX_BASE).padStart(HEX_DIGITS_PER_CHANNEL, "0")).join("")
}

export function hexToRgb(hex) {
  const packed = parseInt(hex.slice(HEX_PREFIX.length), HEX_BASE)
  return [(packed >> RED_SHIFT) & CHANNEL_MASK, (packed >> GREEN_SHIFT) & CHANNEL_MASK, packed & CHANNEL_MASK].map(channel => channel / MAX_CHANNEL)
}

export function mixHex(fromHex, toHex, ratio) {
  const from = hexToRgb(fromHex), to = hexToRgb(toHex)
  return rgbToHex(from.map((fromChannel, index) => fromChannel + (to[index] - fromChannel) * ratio))
}

export const clampFraction = fraction => Math.min(1, Math.max(0, fraction))
