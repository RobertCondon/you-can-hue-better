const ANGLE_NUDGE = 1e-4
const PARALLEL_TOLERANCE = 1e-12
const HIT_TOLERANCE = 1e-9
const SIGHT_TOLERANCE = 1e-6
const DEGREES_TO_RADIANS = Math.PI / 180
const BOUNDS_WALL = "bounds"

const centreOf = rectangle => ({ x: rectangle.x + rectangle.width / 2, y: rectangle.y + rectangle.height / 2 })
const unit = (deltaX, deltaY) => { const length = Math.hypot(deltaX, deltaY) || 1; return { x: deltaX / length, y: deltaY / length } }

export function corners(rectangle) {
  const centre = centreOf(rectangle), angle = (rectangle.rotation || 0) * DEGREES_TO_RADIANS
  const cos = Math.cos(angle), sin = Math.sin(angle)
  const halfWidth = rectangle.width / 2, halfHeight = rectangle.height / 2
  return [[-halfWidth, -halfHeight], [halfWidth, -halfHeight], [halfWidth, halfHeight], [-halfWidth, halfHeight]].map(([alongX, alongY]) => ({
    x: centre.x + alongX * cos - alongY * sin, y: centre.y + alongX * sin + alongY * cos
  }))
}

export function wallEdges(rectangle, wallId) {
  const points = corners(rectangle), centre = centreOf(rectangle)
  return points.map((start, index) => {
    const end = points[(index + 1) % points.length]
    return { a: start, b: end, n: unit((start.x + end.x) / 2 - centre.x, (start.y + end.y) / 2 - centre.y), wall: wallId }
  })
}

export function boundsEdges(size) {
  return wallEdges({ x: 0, y: 0, width: size.width, height: size.height, rotation: 0 }, BOUNDS_WALL)
}

export function polygonEdges(points, wallId) {
  const centre = {
    x: points.reduce((sum, point) => sum + point.x, 0) / points.length,
    y: points.reduce((sum, point) => sum + point.y, 0) / points.length
  }
  return points.map((start, index) => {
    const end = points[(index + 1) % points.length]
    return { a: start, b: end, n: unit(centre.x - (start.x + end.x) / 2, centre.y - (start.y + end.y) / 2), wall: wallId }
  })
}

export function rayHit(origin, direction, segment) {
  const along = { x: segment.b.x - segment.a.x, y: segment.b.y - segment.a.y }
  const denominator = direction.x * along.y - direction.y * along.x
  if (Math.abs(denominator) < PARALLEL_TOLERANCE) return null
  const toStart = { x: segment.a.x - origin.x, y: segment.a.y - origin.y }
  const distance = (toStart.x * along.y - toStart.y * along.x) / denominator
  const position = (toStart.x * direction.y - toStart.y * direction.x) / denominator
  return distance > HIT_TOLERANCE && position >= -HIT_TOLERANCE && position <= 1 + HIT_TOLERANCE ? distance : null
}

function nearestHit(origin, direction, segments) {
  let nearest = Infinity
  for (const segment of segments) {
    const distance = rayHit(origin, direction, segment)
    if (distance !== null && distance < nearest) nearest = distance
  }
  return nearest
}

export function visibility(origin, segments) {
  const angles = segments.flatMap(segment => [segment.a, segment.b]).flatMap(point => {
    const angle = Math.atan2(point.y - origin.y, point.x - origin.x)
    return [angle - ANGLE_NUDGE, angle, angle + ANGLE_NUDGE]
  })
  return angles.flatMap(angle => {
    const direction = { x: Math.cos(angle), y: Math.sin(angle) }
    const distance = nearestHit(origin, direction, segments)
    return distance === Infinity ? [] : [{ angle, x: origin.x + direction.x * distance, y: origin.y + direction.y * distance }]
  }).sort((first, second) => first.angle - second.angle)
}

export function reflect(point, edge) {
  const along = unit(edge.b.x - edge.a.x, edge.b.y - edge.a.y)
  const projection = (point.x - edge.a.x) * along.x + (point.y - edge.a.y) * along.y
  const foot = { x: edge.a.x + along.x * projection, y: edge.a.y + along.y * projection }
  return { x: 2 * foot.x - point.x, y: 2 * foot.y - point.y }
}

export function facing(point, edge) {
  return (point.x - edge.a.x) * edge.n.x + (point.y - edge.a.y) * edge.n.y > 0
}

export function canSee(origin, target, segments) {
  const distance = Math.hypot(target.x - origin.x, target.y - origin.y)
  if (distance < HIT_TOLERANCE) return true
  const direction = { x: (target.x - origin.x) / distance, y: (target.y - origin.y) / distance }
  return nearestHit(origin, direction, segments) >= distance - SIGHT_TOLERANCE
}

export function inside(point, rectangle) {
  const centre = centreOf(rectangle), angle = -(rectangle.rotation || 0) * DEGREES_TO_RADIANS
  const offsetX = point.x - centre.x, offsetY = point.y - centre.y
  const localX = offsetX * Math.cos(angle) - offsetY * Math.sin(angle)
  const localY = offsetX * Math.sin(angle) + offsetY * Math.cos(angle)
  return Math.abs(localX) < rectangle.width / 2 && Math.abs(localY) < rectangle.height / 2
}

export function pointInPolygon(point, vertices) {
  let insidePolygon = false
  for (let index = 0, previous = vertices.length - 1; index < vertices.length; previous = index++) {
    const [currentX, currentY] = vertices[index], [previousX, previousY] = vertices[previous]
    const crossesRay = (currentY > point.y) !== (previousY > point.y)
    if (crossesRay && point.x < (previousX - currentX) * (point.y - currentY) / (previousY - currentY) + currentX) insidePolygon = !insidePolygon
  }
  return insidePolygon
}

export function boundingBox(vertices) {
  const xValues = vertices.map(([vertexX]) => vertexX), yValues = vertices.map(([, vertexY]) => vertexY)
  const left = Math.min(...xValues), top = Math.min(...yValues)
  return { x: left, y: top, width: Math.max(...xValues) - left, height: Math.max(...yValues) - top }
}
