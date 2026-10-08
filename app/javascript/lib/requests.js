const TURBO_STREAM = "text/vnd.turbo-stream.html"
const HTML = "text/html"

const csrfToken = () => document.querySelector('meta[name="csrf-token"]').content

export function formDataFrom(fields) {
  const body = new FormData()
  for (const [name, value] of Object.entries(fields)) body.append(name, value)
  return body
}

export async function patchAndRenderStreams(url, fields) {
  const response = await fetch(url, { method: "PATCH", body: formDataFrom(fields), headers: { Accept: TURBO_STREAM, "X-CSRF-Token": csrfToken() } })
  if (response.ok) window.Turbo.renderStreamMessage(await response.text())
  return response
}

export function patch(url, body) {
  return fetch(url, { method: "PATCH", body, headers: { "X-CSRF-Token": csrfToken() } })
}

export async function fetchHtml(url) {
  const response = await fetch(url, { headers: { Accept: HTML } })
  return response.ok ? response.text() : null
}
