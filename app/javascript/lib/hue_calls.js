import { sendJson, readJson } from "lib/requests"
import { anyPending, markPending, free, checkInAfter } from "lib/light_intents"
import { snapshotLight, restoreLight } from "lib/light_preview"
import { showToast, showStillChanging, clearToasts } from "lib/toasts"

const PATCH = "PATCH"
const ACCEPTED = 202

export async function asyncHueCall(url, fields, lightIds, { method = PATCH, guess } = {}) {
  if (anyPending(lightIds)) {
    showStillChanging()
    return false
  }
  const before = lightIds.flatMap(snapshotLight)
  guess?.()
  markPending(lightIds)
  try {
    const response = await sendJson(method, url, fields)
    const reply = await readJson(response)
    if (response.status === ACCEPTED) {
      clearToasts()
      checkInAfter(lightIds, reply.check_in_ms)
      return true
    }
    undo(lightIds, before, reply.error)
    return false
  } catch (error) {
    undo(lightIds, before)
    throw error
  }
}

export async function directHueCall(url, fields, { method = PATCH } = {}) {
  const response = await sendJson(method, url, fields)
  return { response, reply: await readJson(response) }
}

function undo(lightIds, before, message) {
  free(lightIds)
  restoreLight(before)
  if (message) showToast(message)
}
