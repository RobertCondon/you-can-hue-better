import { boundsEdges, wallEdges, polygonEdges, visibility, reflect, facing, canSee, inside, corners } from "lib/floor_geometry"

const FLOOR_WIDTH = 100
const BEAM_LENGTH = 1e4
const BOUNCE_STRENGTH = 0.6
const MINIMUM_OUTLINE_POINTS = 3
const OUTLINE_WALL = "outline"
const MINIMUM_RADIUS = 8
const RADIUS_PER_BRIGHTNESS = 62
const MINIMUM_ALPHA = 0.12
const ALPHA_PER_BRIGHTNESS = 0.75
const CORE_MINIMUM_RADIUS = 2
const CORE_RADIUS_PER_BRIGHTNESS = 3
const CORE_WHITENING = 120
const MAX_CHANNEL = 255
const GLOW_STOPS = [0, 0.15, 0.35, 0.6, 0.85, 1]
const ALPHA_DECIMAL_PLACES = 3
const HEX_BASE = 16
const RED_SHIFT = 16
const GREEN_SHIFT = 8
const CHANNEL_MASK = 0xff
const WALL_FILL = "#3b4154"
const WALL_STROKE = "rgba(255,255,255,0.18)"
const WALL_STROKE_WIDTH = 0.3
const IDENTITY = [1, 0, 0, 1, 0, 0]

export const floorSize = aspect => ({ width: FLOOR_WIDTH, height: FLOOR_WIDTH / aspect })

export function reach(brightness) {
  return { radius: MINIMUM_RADIUS + RADIUS_PER_BRIGHTNESS * Math.sqrt(brightness), alpha: MINIMUM_ALPHA + ALPHA_PER_BRIGHTNESS * brightness }
}

function channelsOf(hex) {
  const packed = parseInt(hex.slice(1), HEX_BASE)
  return [(packed >> RED_SHIFT) & CHANNEL_MASK, (packed >> GREEN_SHIFT) & CHANNEL_MASK, packed & CHANNEL_MASK]
}

function tracePath(context, points) {
  context.beginPath()
  points.forEach((point, index) => (index ? context.lineTo(point.x, point.y) : context.moveTo(point.x, point.y)))
  context.closePath()
}

function glow(context, source, radius, alpha, [red, green, blue], clipPolygons) {
  context.save()
  for (const polygon of clipPolygons) {
    if (polygon.length < MINIMUM_OUTLINE_POINTS) { context.restore(); return }
    tracePath(context, polygon)
    context.clip()
  }
  const gradient = context.createRadialGradient(source.x, source.y, 0, source.x, source.y, radius)
  for (const stop of GLOW_STOPS) gradient.addColorStop(stop, `rgba(${red},${green},${blue},${(alpha * (1 - stop) ** 2).toFixed(ALPHA_DECIMAL_PLACES)})`)
  context.fillStyle = gradient
  context.fillRect(source.x - radius, source.y - radius, radius * 2, radius * 2)
  context.restore()
}

function hotSpot(context, source, radius, alpha, [red, green, blue]) {
  const whitened = [red, green, blue].map(channel => Math.min(MAX_CHANNEL, channel + CORE_WHITENING))
  const gradient = context.createRadialGradient(source.x, source.y, 0, source.x, source.y, radius)
  gradient.addColorStop(0, `rgba(${whitened.join(",")},${alpha})`)
  gradient.addColorStop(1, `rgba(${red},${green},${blue},0)`)
  context.fillStyle = gradient
  context.fillRect(source.x - radius, source.y - radius, radius * 2, radius * 2)
}

function visibleFaces(light, wallSegments, allSegments) {
  return wallSegments.filter(edge => {
    if (!facing(light, edge)) return false
    const middle = { x: (edge.a.x + edge.b.x) / 2, y: (edge.a.y + edge.b.y) / 2 }
    return [middle, edge.a, edge.b].some(point => canSee(light, point, allSegments))
  })
}

function bounceBeam(edge, mirroredSource) {
  const beyond = point => ({ x: point.x + (point.x - mirroredSource.x) * BEAM_LENGTH, y: point.y + (point.y - mirroredSource.y) * BEAM_LENGTH })
  return [edge.a, edge.b, beyond(edge.b), beyond(edge.a)]
}

function drawLight(context, light, wallSegments, allSegments) {
  const { radius, alpha } = reach(light.bri)
  const channels = channelsOf(light.hex)
  glow(context, light, radius, alpha, channels, [visibility(light, allSegments)])
  hotSpot(context, light, CORE_MINIMUM_RADIUS + CORE_RADIUS_PER_BRIGHTNESS * light.bri, alpha, channels)
  for (const edge of visibleFaces(light, wallSegments, allSegments)) {
    const mirroredSource = reflect(light, edge)
    const otherSegments = allSegments.filter(segment => segment.wall !== edge.wall)
    glow(context, mirroredSource, radius, alpha * BOUNCE_STRENGTH, channels, [visibility(mirroredSource, otherSegments), bounceBeam(edge, mirroredSource)])
  }
}

function drawWalls(context, walls) {
  for (const wall of walls) {
    tracePath(context, corners(wall))
    context.fillStyle = WALL_FILL
    context.fill()
    context.strokeStyle = WALL_STROKE
    context.lineWidth = WALL_STROKE_WIDTH
    context.stroke()
  }
}

export function drawFloorLight(canvas, { lights, walls, aspect, outline = null, camera, devicePixelRatio = 1 }) {
  const size = floorSize(aspect)
  const context = canvas.getContext("2d")
  context.setTransform(...IDENTITY)
  context.clearRect(0, 0, canvas.width, canvas.height)
  const scale = (canvas.width / size.width) * camera.zoom
  context.setTransform(scale, 0, 0, scale, camera.offsetX * devicePixelRatio, camera.offsetY * devicePixelRatio)

  const wallSegments = walls.flatMap((wall, index) => wallEdges(wall, index))
  if (outline && outline.length >= MINIMUM_OUTLINE_POINTS) wallSegments.push(...polygonEdges(outline, OUTLINE_WALL))
  const allSegments = [...boundsEdges(size), ...wallSegments]

  context.globalCompositeOperation = "screen"
  for (const light of lights) {
    if (light.bri <= 0 || walls.some(wall => inside(light, wall))) continue
    drawLight(context, light, wallSegments, allSegments)
  }
  context.globalCompositeOperation = "source-over"
  drawWalls(context, walls)
}
