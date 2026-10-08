// The floor's camera: a translate + scale over a world the same size as the viewport.
// Pure maths; the controller applies the result. k is the zoom (1 = fit), tx/ty are pixels.

export const MIN_K = 1, MAX_K = 6
export const LEVELS = { far: 0, mid: 1.6, near: 3 }   // label detail by zoom

// Keep the world covering the viewport: at k = 1 it fits exactly, zoomed in it may only overflow.
export function clamp(cam, view) {
  const k = Math.min(MAX_K, Math.max(MIN_K, cam.k))
  const tx = Math.min(0, Math.max(view.w - view.w * k, cam.tx))
  const ty = Math.min(0, Math.max(view.h - view.h * k, cam.ty))
  return { k, tx, ty }
}

// Zoom by a factor about a viewport point, so what is under the pointer stays under it.
export function zoomAt(cam, factor, px, py, view) {
  const k = Math.min(MAX_K, Math.max(MIN_K, cam.k * factor))
  const f = k / cam.k
  return clamp({ k, tx: px - (px - cam.tx) * f, ty: py - (py - cam.ty) * f }, view)
}

export function pan(cam, dx, dy, view) {
  return clamp({ k: cam.k, tx: cam.tx + dx, ty: cam.ty + dy }, view)
}

export const fit = () => ({ k: 1, tx: 0, ty: 0 })

// Frame a rectangle given in world percent (x, y, w, h), leaving a margin.
export function frame(rect, view, margin = 0.12) {
  const k = Math.min(MAX_K, Math.max(MIN_K, Math.min(100 / rect.w, 100 / rect.h) * (1 - margin)))
  const cx = (rect.x + rect.w / 2) / 100 * view.w * k, cy = (rect.y + rect.h / 2) / 100 * view.h * k
  return clamp({ k, tx: view.w / 2 - cx, ty: view.h / 2 - cy }, view)
}

export function levelFor(k) {
  return k >= LEVELS.near ? "near" : k >= LEVELS.mid ? "mid" : "far"
}

// Viewport pixel -> world percent.
export function toWorld(cam, px, py, view) {
  return { x: (px - cam.tx) / (view.w * cam.k) * 100, y: (py - cam.ty) / (view.h * cam.k) * 100 }
}
