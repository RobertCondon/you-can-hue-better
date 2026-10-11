import { Controller } from "@hotwired/stimulus"
import { getHtml } from "lib/requests"

const PINNED_CLASS = "is-pinned"
const TILE_SELECTOR = ".tile[data-light-id]"
const TILE_OPENER_SELECTOR = ".tile__open"
const OPEN_DIALOG_SELECTOR = "dialog[open]"

export default class extends Controller {
  static targets = ["dock"]

  async toggle(event) {
    const { id, sheetUrl, room } = event.params
    if (this.pinnedLightId === id) return this.close()
    await this.pin(id, sheetUrl, room)
  }

  async pin(lightId, sheetUrl, roomId) {
    const sheetHtml = await getHtml(sheetUrl)
    if (!sheetHtml) return
    this.dockTarget.innerHTML = sheetHtml
    this.dockTarget.hidden = false
    this.dockTarget.dataset.room = roomId || ""
    this.pinnedLightId = lightId
    this.markPinnedTile(lightId)
  }

  escape() {
    if (this.pinnedLightId && !document.querySelector(OPEN_DIALOG_SELECTOR)) this.close()
  }

  close() {
    this.dockTarget.innerHTML = ""
    this.dockTarget.hidden = true
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
    if (opener) this.pin(nextLightId, opener.dataset.lightPanelSheetUrlParam, roomId)
  }

  lightIdsIn(roomId) {
    const room = roomId && this.element.querySelector(`#room_body_${CSS.escape(roomId)}`)
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
