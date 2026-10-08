// Colour maths for the picker. Mirrors app/services/hue/color.rb: sRGB <-> CIE xy, plus the
// gamut clamp Philips publishes, so what the wheel shows is what the bulb can make.

const GAMUT_C = { red: { x: 0.6915, y: 0.3083 }, green: { x: 0.17, y: 0.7 }, blue: { x: 0.1532, y: 0.0475 } }

export function hsvToRgb(h, s, v) {
  const c = v * s, x = c * (1 - Math.abs(((h / 60) % 2) - 1)), m = v - c
  let r = 0, g = 0, b = 0
  if (h < 60) [r, g, b] = [c, x, 0]
  else if (h < 120) [r, g, b] = [x, c, 0]
  else if (h < 180) [r, g, b] = [0, c, x]
  else if (h < 240) [r, g, b] = [0, x, c]
  else if (h < 300) [r, g, b] = [x, 0, c]
  else [r, g, b] = [c, 0, x]
  return [r + m, g + m, b + m]
}

export function rgbToHsv([r, g, b]) {
  const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min
  let h = 0
  if (d > 0) {
    if (max === r) h = 60 * (((g - b) / d) % 6)
    else if (max === g) h = 60 * ((b - r) / d + 2)
    else h = 60 * ((r - g) / d + 4)
  }
  if (h < 0) h += 360
  return [h, max === 0 ? 0 : d / max, max]
}

const decode = c => (c > 0.04045 ? Math.pow((c + 0.055) / 1.055, 2.4) : c / 12.92)
const encode = c => (c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055)

export function rgbToXy([r, g, b]) {
  const [R, G, B] = [r, g, b].map(decode)
  const X = R * 0.4124 + G * 0.3576 + B * 0.1805
  const Y = R * 0.2126 + G * 0.7152 + B * 0.0722
  const Z = R * 0.0193 + G * 0.1192 + B * 0.9505
  const sum = X + Y + Z
  return sum === 0 ? { x: 0.3127, y: 0.329 } : { x: X / sum, y: Y / sum }
}

// Full-brightness sRGB for an xy point (0..1 floats).
export function xyToRgb({ x, y }) {
  if (y === 0) return [0, 0, 0]
  const Y = 1, X = (Y / y) * x, Z = (Y / y) * (1 - x - y)
  let rgb = [
    X * 3.2406 - Y * 1.5372 - Z * 0.4986,
    -X * 0.9689 + Y * 1.8758 + Z * 0.0415,
    X * 0.0557 - Y * 0.204 + Z * 1.057
  ].map(c => Math.max(0, c))
  const max = Math.max(...rgb)
  if (max > 1) rgb = rgb.map(c => c / max)
  return rgb.map(c => Math.min(1, Math.max(0, encode(c))))
}

export function rgbToHex(rgb) {
  return "#" + rgb.map(c => Math.round(c * 255).toString(16).padStart(2, "0")).join("")
}

export function mixHex(a, b, t) {
  const pa = hexToRgb(a), pb = hexToRgb(b)
  return rgbToHex(pa.map((c, i) => c + (pb[i] - c) * t))
}

export function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255].map(c => c / 255)
}

// Nearest point inside the bulb's gamut triangle (Philips' published method).
export function clampToGamut(p, gamut = GAMUT_C) {
  const { red: r, green: g, blue: b } = gamut
  if (inTriangle(p, r, g, b)) return p
  const candidates = [closestOnSegment(r, g, p), closestOnSegment(b, r, p), closestOnSegment(g, b, p)]
  let best = candidates[0], bestD = dist(p, best)
  for (const c of candidates.slice(1)) {
    const d = dist(p, c)
    if (d < bestD) { best = c; bestD = d }
  }
  return best
}

function inTriangle(p, a, b, c) {
  const v1 = { x: c.x - a.x, y: c.y - a.y }, v2 = { x: b.x - a.x, y: b.y - a.y }, q = { x: p.x - a.x, y: p.y - a.y }
  const s = (q.x * v2.y - q.y * v2.x) / (v1.x * v2.y - v1.y * v2.x)
  const t = (v1.x * q.y - v1.y * q.x) / (v1.x * v2.y - v1.y * v2.x)
  return s >= 0 && t >= 0 && s + t <= 1
}

function closestOnSegment(a, b, p) {
  const ab = { x: b.x - a.x, y: b.y - a.y }, ap = { x: p.x - a.x, y: p.y - a.y }
  let t = (ap.x * ab.x + ap.y * ab.y) / (ab.x * ab.x + ab.y * ab.y)
  t = Math.min(1, Math.max(0, t))
  return { x: a.x + ab.x * t, y: a.y + ab.y * t }
}

const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y)

// Approximate sRGB of a white at the given colour temperature (mirek = 1e6 / kelvin).
export function mirekToRgb(mirek) {
  const t = 1e6 / mirek / 100
  let r, g, b
  r = t <= 66 ? 255 : 329.698727446 * Math.pow(t - 60, -0.1332047592)
  g = t <= 66 ? 99.4708025861 * Math.log(t) - 161.1195681661 : 288.1221695283 * Math.pow(t - 60, -0.0755148492)
  b = t >= 66 ? 255 : t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307
  return [r, g, b].map(c => Math.min(255, Math.max(0, c)) / 255)
}

export { GAMUT_C }
