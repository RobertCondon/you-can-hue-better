import { Controller } from "@hotwired/stimulus"
import { hold, release } from "lib/busy"
import { anyPending } from "lib/light_intents"
import { previewLevel, previewPower } from "lib/light_preview"

const CARD_SELECTOR = ".room-card"
const TILE_SELECTOR = ".tile[data-light-id]"
const ON_CLASS = "is-on"
const MIXED_CLASS = "is-mixed"

export default class extends Controller {
  static targets = ["level"]

  preview(event) {
    const tiles = this.tiles()
    if (anyPending(tiles.map(tile => tile.dataset.lightId))) return
    hold(this.card)
    this.dimming ??= this.litOrEveryLight(tiles)
    const level = Number(event.target.value)
    for (const lightId of this.dimming) {
      previewPower(lightId, true)
      previewLevel(lightId, level)
    }
    this.element.classList.remove(MIXED_CLASS)
    this.element.style.setProperty("--fill", `${level}%`)
    this.levelTarget.textContent = `${level}%`
  }

  submit() {
    this.dimming = null
    this.element.requestSubmit()
  }

  freed(event) {
    const roomLightIds = this.tiles().map(tile => tile.dataset.lightId)
    if (event.detail.lightIds.some(lightId => roomLightIds.includes(lightId))) release(this.card)
  }

  get card() {
    return this.element.closest(CARD_SELECTOR)
  }

  tiles() {
    const body = document.getElementById(`room_body_${this.card.dataset.roomId}`)
    return body ? [...body.querySelectorAll(TILE_SELECTOR)] : []
  }

  litOrEveryLight(tiles) {
    const lit = tiles.filter(tile => tile.classList.contains(ON_CLASS))
    return [...new Set((lit.length ? lit : tiles).map(tile => tile.dataset.lightId))]
  }
}
