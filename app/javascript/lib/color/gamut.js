export const GAMUT_C = { red: { x: 0.6915, y: 0.3083 }, green: { x: 0.17, y: 0.7 }, blue: { x: 0.1532, y: 0.0475 } }

const offset = (from, to) => ({ x: to.x - from.x, y: to.y - from.y })
const distance = (from, to) => Math.hypot(from.x - to.x, from.y - to.y)
const cross = (first, second) => first.x * second.y - first.y * second.x

function insideTriangle(point, { red, green, blue }) {
  const towardBlue = offset(red, blue), towardGreen = offset(red, green), towardPoint = offset(red, point)
  const area = cross(towardBlue, towardGreen)
  const blueWeight = cross(towardPoint, towardGreen) / area
  const greenWeight = cross(towardBlue, towardPoint) / area
  return blueWeight >= 0 && greenWeight >= 0 && blueWeight + greenWeight <= 1
}

function closestOnEdge(start, end, point) {
  const along = offset(start, end), toPoint = offset(start, point)
  const position = Math.min(1, Math.max(0, (toPoint.x * along.x + toPoint.y * along.y) / (along.x * along.x + along.y * along.y)))
  return { x: start.x + along.x * position, y: start.y + along.y * position }
}

export function clampToGamut(point, gamut = GAMUT_C) {
  if (insideTriangle(point, gamut)) return point
  const { red, green, blue } = gamut
  const candidates = [closestOnEdge(red, green, point), closestOnEdge(blue, red, point), closestOnEdge(green, blue, point)]
  return candidates.reduce((closest, candidate) => (distance(point, candidate) < distance(point, closest) ? candidate : closest))
}
