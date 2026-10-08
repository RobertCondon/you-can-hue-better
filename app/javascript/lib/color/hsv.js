const DEGREES_PER_SECTOR = 60
const SECTOR_COUNT = 6
const FULL_TURN_DEGREES = 360
const GREEN_SECTOR_START = 2
const BLUE_SECTOR_START = 4

const SECTOR_CHANNELS = [
  (strong, middle) => [strong, middle, 0],
  (strong, middle) => [middle, strong, 0],
  (strong, middle) => [0, strong, middle],
  (strong, middle) => [0, middle, strong],
  (strong, middle) => [middle, 0, strong],
  (strong, middle) => [strong, 0, middle]
]

export function hsvToRgb(hueDegrees, saturation, value) {
  const chroma = value * saturation
  const middle = chroma * (1 - Math.abs(((hueDegrees / DEGREES_PER_SECTOR) % 2) - 1))
  const floor = value - chroma
  const sector = Math.min(SECTOR_COUNT - 1, Math.floor(hueDegrees / DEGREES_PER_SECTOR))
  return SECTOR_CHANNELS[sector](chroma, middle).map(channel => channel + floor)
}

export function rgbToHsv([red, green, blue]) {
  const brightest = Math.max(red, green, blue)
  const spread = brightest - Math.min(red, green, blue)
  let hueDegrees = 0
  if (spread > 0) {
    if (brightest === red) hueDegrees = DEGREES_PER_SECTOR * (((green - blue) / spread) % SECTOR_COUNT)
    else if (brightest === green) hueDegrees = DEGREES_PER_SECTOR * ((blue - red) / spread + GREEN_SECTOR_START)
    else hueDegrees = DEGREES_PER_SECTOR * ((red - green) / spread + BLUE_SECTOR_START)
  }
  if (hueDegrees < 0) hueDegrees += FULL_TURN_DEGREES
  return [hueDegrees, brightest === 0 ? 0 : spread / brightest, brightest]
}
