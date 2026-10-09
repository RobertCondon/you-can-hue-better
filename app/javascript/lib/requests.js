import { hueTab, HUE_TAB_HEADER } from "lib/hue_tab"

const CSRF_TOKEN_SELECTOR = 'meta[name="csrf-token"]'
const CONTENT_TYPE_HEADER = "Content-Type"
const GET = "GET"
const POST = "POST"
const PATCH = "PATCH"
const DELETE = "DELETE"

export const ACCEPT = { turboStream: "text/vnd.turbo-stream.html", html: "text/html", json: "application/json" }

const csrfToken = () => document.querySelector(CSRF_TOKEN_SELECTOR).content

function formDataFrom(fields) {
  if (fields instanceof FormData) return fields
  const body = new FormData()
  for (const [name, value] of Object.entries(fields)) {
    for (const item of [value].flat()) body.append(name, item)
  }
  return body
}

export function request(method, url, { fields, accept } = {}) {
  const headers = { "X-CSRF-Token": csrfToken() }
  if (accept) headers.Accept = accept
  const tab = hueTab()
  if (tab) headers[HUE_TAB_HEADER] = tab
  return fetch(url, { method, headers, body: fields && formDataFrom(fields) })
}

export const post = (url, fields, options = {}) => request(POST, url, { ...options, fields })

export const patch = (url, fields, options = {}) => request(PATCH, url, { ...options, fields })

export const destroy = url => request(DELETE, url)

const isTurboStream = response => response.headers.get(CONTENT_TYPE_HEADER)?.startsWith(ACCEPT.turboStream)

export async function renderStreams(response) {
  if (isTurboStream(response)) window.Turbo.renderStreamMessage(await response.text())
  return response
}

export async function getHtml(url) {
  const response = await request(GET, url, { accept: ACCEPT.html })
  return response.ok ? response.text() : null
}

export async function getJson(url) {
  const response = await request(GET, url, { accept: ACCEPT.json })
  return response.ok ? response.json() : null
}
