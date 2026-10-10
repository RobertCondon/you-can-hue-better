import { hold, release } from "lib/busy"
import { getJson } from "lib/requests"
import { SETTLED_EVENT } from "lib/stream_actions"

const PENDING_CLASS = "is-pending"
const LOCKS_PATH = "/locks"
const LIGHT_IDS_PARAM = "light_ids[]"
const checkInTimers = new Map()

export const FREED_EVENT = "hue:freed"

const elementsShowing = lightId => document.querySelectorAll(`[data-light-id="${lightId}"]`)

export const isPending = lightId => checkInTimers.has(lightId)

export const anyPending = lightIds => lightIds.some(isPending)

export function markPending(lightIds) {
  for (const lightId of lightIds) {
    checkInTimers.set(lightId, null)
    for (const element of elementsShowing(lightId)) {
      element.classList.add(PENDING_CLASS)
      hold(element)
    }
  }
}

export function free(lightIds) {
  const freeing = lightIds.filter(isPending)
  for (const lightId of freeing) {
    const timer = checkInTimers.get(lightId)
    checkInTimers.delete(lightId)
    if (![...checkInTimers.values()].includes(timer)) clearTimeout(timer)
    for (const element of elementsShowing(lightId)) {
      element.classList.remove(PENDING_CLASS)
      release(element)
    }
  }
  if (freeing.length) document.dispatchEvent(new CustomEvent(FREED_EVENT, { detail: { lightIds: freeing } }))
}

export function checkInAfter(lightIds, milliseconds) {
  const stillPending = lightIds.filter(isPending)
  if (!stillPending.length) return
  const timer = setTimeout(() => checkIn(stillPending, milliseconds), milliseconds)
  for (const lightId of stillPending) checkInTimers.set(lightId, timer)
}

async function checkIn(lightIdsAtStart, milliseconds) {
  const lightIds = lightIdsAtStart.filter(isPending)
  if (!lightIds.length) return
  const query = new URLSearchParams(lightIds.map(lightId => [LIGHT_IDS_PARAM, lightId]))
  const answer = await getJson(`${LOCKS_PATH}?${query}`)
  const locked = answer ? answer.locked : []
  free(lightIds.filter(lightId => !locked.includes(lightId)))
  checkInAfter(locked, milliseconds)
}

export function freeLightsWhenSettled() {
  document.addEventListener(SETTLED_EVENT, event => free(event.detail.lightIds))
}
