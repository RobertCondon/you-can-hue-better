import { hueTab, HUE_TAB_HEADER } from "lib/hue_tab"

const CSRF_TOKEN_SELECTOR = 'meta[name="csrf-token"]'
const GET = "GET"
const POST = "POST"
const PATCH = "PATCH"
const DELETE = "DELETE"
const HTML = "text/html"
const JSON_TYPE = "application/json"
const BRACKETED_NAME = /[^[\]]+/g
const SKIPPED_FIELDS = new Set(["_method", "authenticity_token"])

const csrfToken = () => document.querySelector(CSRF_TOKEN_SELECTOR).content

function headersAccepting(accept) {
  const headers = { "X-CSRF-Token": csrfToken(), Accept: accept }
  const tab = hueTab()
  if (tab) headers[HUE_TAB_HEADER] = tab
  return headers
}

function nestedFields(fields) {
  const nested = {}
  for (const [name, value] of fields instanceof FormData ? fields.entries() : Object.entries(fields)) {
    if (SKIPPED_FIELDS.has(name)) continue
    const path = name.match(BRACKETED_NAME)
    const parent = path.slice(0, -1).reduce((node, key) => (node[key] ??= {}), nested)
    parent[path.at(-1)] = value
  }
  return nested
}

export function sendJson(method, url, fields = {}) {
  const headers = { ...headersAccepting(JSON_TYPE), "Content-Type": JSON_TYPE }
  return fetch(url, { method, headers, body: JSON.stringify(nestedFields(fields)) })
}

export async function readJson(response) {
  try {
    return await response.json()
  } catch {
    return {}
  }
}

export const post = (url, fields) => sendJson(POST, url, fields)

export const patch = (url, fields) => sendJson(PATCH, url, fields)

export const destroy = url => sendJson(DELETE, url)

export async function getHtml(url) {
  const response = await fetch(url, { method: GET, headers: headersAccepting(HTML) })
  return response.ok ? response.text() : null
}

export async function getJson(url) {
  const response = await fetch(url, { method: GET, headers: headersAccepting(JSON_TYPE) })
  return response.ok ? response.json() : null
}
