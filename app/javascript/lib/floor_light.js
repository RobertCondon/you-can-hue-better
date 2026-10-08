// Light on the floor. Pure geometry + canvas drawing; no DOM knowledge.
//
// Units: x runs 0..100 across the floor's width, y runs 0..100/aspect down its height, so one
// unit is the same distance both ways. Walls are rectangles {x, y, w, h, r} where r is degrees
// clockwise about the rectangle's centre.
// Each light fills its visibility polygon (what it can see past the walls) with a glow that
// grows and strengthens with brightness, and every wall face it can see bounces light back:
// a mirrored virtual source clipped to the beam through that face, so the floor brightens next
// to a wall. Furniture is ignored.

const EPS = 1e-4, FAR = 1e4, BOUNCE = 0.6

export function floorSize(aspect) { return { w: 100, h: 100 / aspect } }

// The four corners of a (possibly rotated) rectangle, clockwise from top-left.
export function corners({ x, y, w, h, r = 0 }) {
  const cx = x + w / 2, cy = y + h / 2, a = (r * Math.PI) / 180, cos = Math.cos(a), sin = Math.sin(a)
  return [[-w / 2, -h / 2], [w / 2, -h / 2], [w / 2, h / 2], [-w / 2, h / 2]].map(([dx, dy]) => ({
    x: cx + dx * cos - dy * sin, y: cy + dx * sin + dy * cos
  }))
}

// A wall as four edges with outward normals.
export function wallEdges(wall, id) {
  const c = corners(wall), cx = wall.x + wall.w / 2, cy = wall.y + wall.h / 2
  return c.map((a, i) => {
    const b = c[(i + 1) % 4]
    const mx = (a.x + b.x) / 2 - cx, my = (a.y + b.y) / 2 - cy, len = Math.hypot(mx, my) || 1
    return { a, b, n: { x: mx / len, y: my / len }, wall: id }
  })
}

export function boundsEdges(size) {
  return wallEdges({ x: 0, y: 0, w: size.w, h: size.h }, "bounds")
}

// A closed polygon (the house outline) as edges whose normals point inward, so a light inside
// sees every edge as a wall face and bounces off it.
export function polygonEdges(points, id) {
  const cx = points.reduce((s, p) => s + p.x, 0) / points.length, cy = points.reduce((s, p) => s + p.y, 0) / points.length
  return points.map((a, i) => {
    const b = points[(i + 1) % points.length]
    const mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
    const nx = cx - mx, ny = cy - my, len = Math.hypot(nx, ny) || 1
    return { a, b, n: { x: nx / len, y: ny / len }, wall: id }
  })
}

// Distance along a ray (p + r t, t > 0) to a segment, or null.
export function rayHit(p, r, seg) {
  const s = { x: seg.b.x - seg.a.x, y: seg.b.y - seg.a.y }
  const rxs = r.x * s.y - r.y * s.x
  if (Math.abs(rxs) < 1e-12) return null
  const qp = { x: seg.a.x - p.x, y: seg.a.y - p.y }
  const t = (qp.x * s.y - qp.y * s.x) / rxs
  const u = (qp.x * r.y - qp.y * r.x) / rxs
  return t > 1e-9 && u >= -1e-9 && u <= 1 + 1e-9 ? t : null
}

function nearest(p, r, segs) {
  let best = Infinity
  for (const seg of segs) { const t = rayHit(p, r, seg); if (t !== null && t < best) best = t }
  return best
}

// The polygon a point can see, given blocking segments (which must include the floor bounds).
export function visibility(origin, segs) {
  const angles = []
  for (const seg of segs) for (const pt of [seg.a, seg.b]) {
    const a = Math.atan2(pt.y - origin.y, pt.x - origin.x)
    angles.push(a - EPS, a, a + EPS)
  }
  const points = []
  for (const a of angles) {
    const r = { x: Math.cos(a), y: Math.sin(a) }
    const t = nearest(origin, r, segs)
    if (t === Infinity) continue
    points.push({ angle: a, x: origin.x + r.x * t, y: origin.y + r.y * t })
  }
  points.sort((p, q) => p.angle - q.angle)
  return points
}

export function reflect(p, edge) {
  const dx = edge.b.x - edge.a.x, dy = edge.b.y - edge.a.y, len = Math.hypot(dx, dy) || 1
  const ux = dx / len, uy = dy / len
  const vx = p.x - edge.a.x, vy = p.y - edge.a.y
  const d = vx * ux + vy * uy
  const fx = edge.a.x + ux * d, fy = edge.a.y + uy * d
  return { x: 2 * fx - p.x, y: 2 * fy - p.y }
}

function facing(p, edge) {
  return (p.x - edge.a.x) * edge.n.x + (p.y - edge.a.y) * edge.n.y > 0
}

function canSee(p, target, segs) {
  const dx = target.x - p.x, dy = target.y - p.y, dist = Math.hypot(dx, dy)
  if (dist < 1e-9) return true
  const t = nearest(p, { x: dx / dist, y: dy / dist }, segs)
  return t >= dist - 1e-6
}

// Point inside a (rotated) rectangle: test in the rectangle's own frame.
export function inside(p, wall) {
  const cx = wall.x + wall.w / 2, cy = wall.y + wall.h / 2, a = (-(wall.r || 0) * Math.PI) / 180
  const dx = p.x - cx, dy = p.y - cy
  const lx = dx * Math.cos(a) - dy * Math.sin(a), ly = dx * Math.sin(a) + dy * Math.cos(a)
  return Math.abs(lx) < wall.w / 2 && Math.abs(ly) < wall.h / 2
}

export function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}

// How far and how strongly a light reaches, from its brightness (0..1).
export function reach(bri) {
  return { radius: 8 + 62 * Math.sqrt(bri), alpha: 0.12 + 0.75 * bri }
}

// lights: [{x, y, hex, bri (0..1)}], walls: [{x, y, w, h, r}], all in floor units.
// camera: {k, tx, ty} in CSS pixels over the viewport; dpr scales it to canvas pixels.
export function drawFloorLight(canvas, { lights, walls, aspect, outline = null, camera = { k: 1, tx: 0, ty: 0 }, dpr = 1 }) {
  const size = floorSize(aspect)
  const ctx = canvas.getContext("2d")
  ctx.setTransform(1, 0, 0, 1, 0, 0)
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  const scale = (canvas.width / size.w) * camera.k
  ctx.setTransform(scale, 0, 0, scale, camera.tx * dpr, camera.ty * dpr)

  const wallSegs = walls.flatMap((w, i) => wallEdges(w, i))
  if (outline && outline.length >= 3) wallSegs.push(...polygonEdges(outline, "outline"))
  const bounds = boundsEdges(size)
  const all = [...bounds, ...wallSegs]

  ctx.globalCompositeOperation = "screen"
  for (const light of lights) {
    if (light.bri <= 0 || walls.some(w => inside(light, w))) continue
    const { radius, alpha } = reach(light.bri)
    const rgb = hexToRgb(light.hex)

    glow(ctx, light, radius, alpha, rgb, [visibility(light, all)])
    core(ctx, light, 2 + 3 * light.bri, alpha, rgb)

    for (const edge of wallSegs) {
      if (!facing(light, edge)) continue
      const mid = { x: (edge.a.x + edge.b.x) / 2, y: (edge.a.y + edge.b.y) / 2 }
      if (!canSee(light, mid, all) && !canSee(light, edge.a, all) && !canSee(light, edge.b, all)) continue
      const v = reflect(light, edge)
      const others = all.filter(s => s.wall !== edge.wall)
      const beam = [edge.a, edge.b,
        { x: edge.b.x + (edge.b.x - v.x) * FAR, y: edge.b.y + (edge.b.y - v.y) * FAR },
        { x: edge.a.x + (edge.a.x - v.x) * FAR, y: edge.a.y + (edge.a.y - v.y) * FAR }]
      glow(ctx, v, radius, alpha * BOUNCE, rgb, [visibility(v, others), beam])
    }
  }

  ctx.globalCompositeOperation = "source-over"
  for (const w of walls) {
    const c = corners(w)
    ctx.beginPath()
    c.forEach((p, i) => (i ? ctx.lineTo(p.x, p.y) : ctx.moveTo(p.x, p.y)))
    ctx.closePath()
    ctx.fillStyle = "#3b4154"
    ctx.fill()
    ctx.strokeStyle = "rgba(255,255,255,0.18)"
    ctx.lineWidth = 0.3
    ctx.stroke()
  }
}

// Inverse-square-ish falloff: most of the light lands close to the lamp.
function glow(ctx, at, radius, alpha, [r, g, b], clips) {
  ctx.save()
  for (const poly of clips) {
    if (poly.length < 3) { ctx.restore(); return }
    ctx.beginPath()
    poly.forEach((p, i) => (i ? ctx.lineTo(p.x, p.y) : ctx.moveTo(p.x, p.y)))
    ctx.closePath()
    ctx.clip()
  }
  const grad = ctx.createRadialGradient(at.x, at.y, 0, at.x, at.y, radius)
  for (const t of [0, 0.15, 0.35, 0.6, 0.85, 1]) grad.addColorStop(t, `rgba(${r},${g},${b},${(alpha * (1 - t) ** 2).toFixed(3)})`)
  ctx.fillStyle = grad
  ctx.fillRect(at.x - radius, at.y - radius, radius * 2, radius * 2)
  ctx.restore()
}

// The lamp itself: a small, near-white hot spot.
function core(ctx, at, radius, alpha, [r, g, b]) {
  const grad = ctx.createRadialGradient(at.x, at.y, 0, at.x, at.y, radius)
  grad.addColorStop(0, `rgba(${Math.min(255, r + 120)},${Math.min(255, g + 120)},${Math.min(255, b + 120)},${alpha})`)
  grad.addColorStop(1, `rgba(${r},${g},${b},0)`)
  ctx.fillStyle = grad
  ctx.fillRect(at.x - radius, at.y - radius, radius * 2, radius * 2)
}
