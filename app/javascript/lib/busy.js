const BUSY = "1"
const pendingStreams = new Map()

export function hold(element) {
  element.dataset.busy = BUSY
}

// With discard, a stream held back while the element was busy is dropped: a fresher one is on its way.
export function release(element, { discard = false } = {}) {
  delete element.dataset.busy
  if (discard && element.id) pendingStreams.delete(element.id)
  const streamHtml = element.id && pendingStreams.get(element.id)
  if (!streamHtml) return
  pendingStreams.delete(element.id)
  window.Turbo?.renderStreamMessage(streamHtml)
}

function deferStream(streamElement) {
  const targetId = streamElement.getAttribute("target")
  if (targetId) pendingStreams.set(targetId, streamElement.outerHTML)
}

export function deferStreamsAimedAtBusyElements() {
  document.addEventListener("turbo:before-stream-render", event => {
    const targetId = event.target.getAttribute("target")
    const target = targetId && document.getElementById(targetId)
    if (!target?.dataset.busy) return
    deferStream(event.target)
    event.preventDefault()
  })
}
