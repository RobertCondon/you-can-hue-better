import { Controller } from "@hotwired/stimulus"
import { fetchHtml } from "lib/requests"

const PINNED_CLASS = "is-pinned"
const EXPANDED_CLASS = "is-expanded"
const TILE_SELECTOR = ".tile[data-light-id]"
const TILE_OPENER_SELECTOR = ".tile__open"

export default class extends Controller {
  static targets = ["dock"]

  async toggle(event) {
    const { id, pinUrl, room } = event.params
    if (this.pinnedLightId === id) return this.close()
    await this.pin(id, pinUrl, room)
  }

  async pin(lightId, pinUrl, roomId) {
    const pinHtml = await fetchHtml(pinUrl)
    if (!pinHtml) return
    this.dockTarget.innerHTML = pinHtml
    this.dockTarget.hidden = false
    this.dockTarget.dataset.room = roomId || ""
    this.pinnedLightId = lightId
    this.markPinnedTile(lightId)
  }

  close() {
    this.dockTarget.innerHTML = ""
    this.dockTarget.hidden = true
    this.dockTarget.classList.remove(EXPANDED_CLASS)
    this.pinnedLightId = null
    this.markPinnedTile(null)
  }

  swipe(event) {
    const roomId = this.dockTarget.dataset.room
    const lightIds = this.lightIdsIn(roomId)
    const position = lightIds.indexOf(this.pinnedLightId)
    if (position < 0 || lightIds.length < 2) return
    const nextLightId = lightIds[(position + event.detail.direction + lightIds.length) % lightIds.length]
    const opener = this.element.querySelector(`.tile[data-light-id="${nextLightId}"] ${TILE_OPENER_SELECTOR}`)
    if (opener) this.pin(nextLightId, opener.dataset.lightPanelPinUrlParam, roomId)
  }

  lightIdsIn(roomId) {
    const room = roomId && this.element.querySelector(`#room_${CSS.escape(roomId)}`)
    return [...(room || this.element).querySelectorAll(TILE_SELECTOR)].map(tile => tile.dataset.lightId)
  }

  markPinnedTile(lightId) {
    for (const tile of this.element.querySelectorAll(TILE_SELECTOR)) {
      const pinned = tile.dataset.lightId === lightId
      tile.classList.toggle(PINNED_CLASS, pinned)
      tile.querySelector(TILE_OPENER_SELECTOR)?.setAttribute("aria-expanded", String(pinned))
    }
  }
}
