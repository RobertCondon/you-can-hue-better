const MIREKS_PER_KELVIN_RECIPROCAL = 1e6
const KELVIN_PER_STEP = 100
const WARM_LIMIT = 66
const NO_BLUE_LIMIT = 19
const COOL_OFFSET = 60
const BLUE_LOG_OFFSET = 10
const MAX_CHANNEL = 255
const RED_COOL_SCALE = 329.698727446
const RED_COOL_EXPONENT = -0.1332047592
const GREEN_WARM_SCALE = 99.4708025861
const GREEN_WARM_OFFSET = 161.1195681661
const GREEN_COOL_SCALE = 288.1221695283
const GREEN_COOL_EXPONENT = -0.0755148492
const BLUE_WARM_SCALE = 138.5177312231
const BLUE_WARM_OFFSET = 305.0447927307

const red = step => (step <= WARM_LIMIT ? MAX_CHANNEL : RED_COOL_SCALE * Math.pow(step - COOL_OFFSET, RED_COOL_EXPONENT))

const green = step => (step <= WARM_LIMIT
  ? GREEN_WARM_SCALE * Math.log(step) - GREEN_WARM_OFFSET
  : GREEN_COOL_SCALE * Math.pow(step - COOL_OFFSET, GREEN_COOL_EXPONENT))

function blue(step) {
  if (step >= WARM_LIMIT) return MAX_CHANNEL
  if (step <= NO_BLUE_LIMIT) return 0
  return BLUE_WARM_SCALE * Math.log(step - BLUE_LOG_OFFSET) - BLUE_WARM_OFFSET
}

export function mirekToRgb(mirek) {
  const step = MIREKS_PER_KELVIN_RECIPROCAL / mirek / KELVIN_PER_STEP
  return [red(step), green(step), blue(step)].map(channel => Math.min(MAX_CHANNEL, Math.max(0, channel)) / MAX_CHANNEL)
}
