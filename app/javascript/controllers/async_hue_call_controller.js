import { Controller } from "@hotwired/stimulus"
import { asyncHueCall } from "lib/hue_calls"
import { previewPower } from "lib/light_preview"

const POWER_FIELD = "light[on]"
const TRUE = "true"

export default class extends Controller {
  static values = { lightIds: Array }

  async submit(event) {
    event.preventDefault()
    const form = this.element
    const fields = new FormData(form, event.submitter)
    const accepted = await asyncHueCall(form.action, fields, this.lightIdsValue, { method: form.method.toUpperCase(), guess: () => this.guess(fields) })
    if (!accepted) form.reset()
  }

  guess(fields) {
    const power = fields.getAll(POWER_FIELD).at(-1)
    if (power === undefined) return
    for (const lightId of this.lightIdsValue) previewPower(lightId, power === TRUE)
  }
}
