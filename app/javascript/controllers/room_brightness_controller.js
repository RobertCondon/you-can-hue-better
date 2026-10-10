import { Controller } from "@hotwired/stimulus"
import { hold, release } from "lib/busy"
import { anyPending } from "lib/light_intents"
import { previewLevel, previewPower } from "lib/light_preview"

const ROOM_SELECTOR = ".room"
const HEAD_SELECTOR = ".room__head"
const TILE_SELECTOR = ".tile[data-light-id]"
const ON_CLASS = "is-on"
const MIXED_CLASS = "is-mixed"

export default class extends Controller {
  static targets = ["level"]

  preview(event) {
    const tiles = this.tiles()
    if (anyPending(tiles.map(tile => tile.dataset.lightId))) return
    hold(this.head)
    this.dimming ??= this.litOrEveryLight(tiles)
    const level = Number(event.target.value)
    for (const lightId of this.dimming) {
      previewPower(lightId, true)
      previewLevel(lightId, level)
    }
    this.element.classList.remove(MIXED_CLASS)
    this.levelTarget.textContent = `${level}%`
  }

  submit() {
    this.dimming = null
    this.element.requestSubmit()
  }

  freed(event) {
    const roomLightIds = this.tiles().map(tile => tile.dataset.lightId)
    if (event.detail.lightIds.some(lightId => roomLightIds.includes(lightId))) release(this.head)
  }

  get head() {
    return this.element.closest(HEAD_SELECTOR)
  }

  tiles() {
    return [...this.element.closest(ROOM_SELECTOR).querySelectorAll(TILE_SELECTOR)]
  }

  litOrEveryLight(tiles) {
    const lit = tiles.filter(tile => tile.classList.contains(ON_CLASS))
    return [...new Set((lit.length ? lit : tiles).map(tile => tile.dataset.lightId))]
  }
}
