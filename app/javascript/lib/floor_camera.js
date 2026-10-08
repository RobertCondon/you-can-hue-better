export const MIN_ZOOM = 1
export const MAX_ZOOM = 6
export const LEVELS = { far: 0, mid: 1.6, near: 3 }
const FULL_WORLD_PERCENT = 100
const DEFAULT_FRAME_MARGIN = 0.12

const clampZoom = zoom => Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, zoom))

export function clamp(camera, view) {
  const zoom = clampZoom(camera.zoom)
  return {
    zoom,
    offsetX: Math.min(0, Math.max(view.width - view.width * zoom, camera.offsetX)),
    offsetY: Math.min(0, Math.max(view.height - view.height * zoom, camera.offsetY))
  }
}

export function zoomAt(camera, factor, pointerX, pointerY, view) {
  const zoom = clampZoom(camera.zoom * factor)
  const scale = zoom / camera.zoom
  return clamp({ zoom, offsetX: pointerX - (pointerX - camera.offsetX) * scale, offsetY: pointerY - (pointerY - camera.offsetY) * scale }, view)
}

export function pan(camera, deltaX, deltaY, view) {
  return clamp({ zoom: camera.zoom, offsetX: camera.offsetX + deltaX, offsetY: camera.offsetY + deltaY }, view)
}

export const fit = () => ({ zoom: MIN_ZOOM, offsetX: 0, offsetY: 0 })

export function frame(rectangle, view, margin = DEFAULT_FRAME_MARGIN) {
  const zoom = clampZoom(Math.min(FULL_WORLD_PERCENT / rectangle.width, FULL_WORLD_PERCENT / rectangle.height) * (1 - margin))
  const centreX = (rectangle.x + rectangle.width / 2) / FULL_WORLD_PERCENT * view.width * zoom
  const centreY = (rectangle.y + rectangle.height / 2) / FULL_WORLD_PERCENT * view.height * zoom
  return clamp({ zoom, offsetX: view.width / 2 - centreX, offsetY: view.height / 2 - centreY }, view)
}

export function levelFor(zoom) {
  if (zoom >= LEVELS.near) return "near"
  return zoom >= LEVELS.mid ? "mid" : "far"
}

export function toWorld(camera, pixelX, pixelY, view) {
  return {
    x: (pixelX - camera.offsetX) / (view.width * camera.zoom) * FULL_WORLD_PERCENT,
    y: (pixelY - camera.offsetY) / (view.height * camera.zoom) * FULL_WORLD_PERCENT
  }
}

export function toScreen(camera, worldPoint, view) {
  return {
    x: worldPoint.x / FULL_WORLD_PERCENT * view.width * camera.zoom + camera.offsetX,
    y: worldPoint.y / FULL_WORLD_PERCENT * view.height * camera.zoom + camera.offsetY
  }
}
