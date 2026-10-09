import { request, renderStreams, ACCEPT } from "lib/requests"
import { anyPending, markPending, free, checkInAfter } from "lib/light_intents"
import { showStillChanging } from "lib/toasts"

const PATCH = "PATCH"
const ACCEPTED = 202
const CHECK_IN_HEADER = "Check-In-After"

export async function asyncHueCall(url, fields, lightIds, { method = PATCH, guess } = {}) {
  if (anyPending(lightIds)) {
    showStillChanging()
    return false
  }
  guess?.()
  markPending(lightIds)
  try {
    const response = await request(method, url, { fields, accept: ACCEPT.turboStream })
    if (response.status === ACCEPTED) {
      checkInAfter(lightIds, Number(response.headers.get(CHECK_IN_HEADER)))
    } else {
      free(lightIds)
    }
    await renderStreams(response)
    return response.status === ACCEPTED
  } catch (error) {
    free(lightIds)
    throw error
  }
}

export async function directHueCall(url, fields, { method = PATCH } = {}) {
  return renderStreams(await request(method, url, { fields, accept: ACCEPT.turboStream }))
}
