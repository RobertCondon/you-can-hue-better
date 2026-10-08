// Live updates and the hand. While an element is "busy" (a drag, a preview) a Turbo stream aimed at
// it is held back instead of dropped, and lands when the element is released, so nothing that
// changed on the bridge meanwhile is lost.
const pending = new Map()

export function hold(el) { el.dataset.busy = "1" }

export function release(el) {
  delete el.dataset.busy
  const html = el.id && pending.get(el.id)
  if (!html) return
  pending.delete(el.id)
  window.Turbo?.renderStreamMessage(html)
}

export function releaseAll(els) { for (const el of els) release(el) }

// Called from the turbo:before-stream-render listener: keep the newest stream for a busy target.
export function defer(streamElement) {
  const id = streamElement.getAttribute("target")
  if (id) pending.set(id, streamElement.outerHTML)
}
