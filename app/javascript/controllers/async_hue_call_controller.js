import { Controller } from "@hotwired/stimulus"
import { asyncHueCall } from "lib/hue_calls"
import { previewPower } from "lib/light_preview"

const POWER_FIELDS = [ "light[on]", "room[on]" ]
const TRUE = "true"
const PENDING_CLASS = "is-pending"

export default class extends Controller {
  static values = { lightIds: Array }

  async submit(event) {
    event.preventDefault()
    const form = this.element
    const fields = new FormData(form, event.submitter)
    form.classList.add(PENDING_CLASS)
    const accepted = await asyncHueCall(form.action, fields, this.lightIdsValue, { method: form.method.toUpperCase(), guess: () => this.guess(fields) })
    if (!accepted) {
      form.classList.remove(PENDING_CLASS)
      form.reset()
    }
  }

  freed(event) {
    if (event.detail.lightIds.some(lightId => this.lightIdsValue.includes(lightId))) this.element.classList.remove(PENDING_CLASS)
  }

  guess(fields) {
    const power = POWER_FIELDS.flatMap(name => fields.getAll(name)).at(-1)
    if (power === undefined) return
    for (const lightId of this.lightIdsValue) previewPower(lightId, power === TRUE)
  }
}
