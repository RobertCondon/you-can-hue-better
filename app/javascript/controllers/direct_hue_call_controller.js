import { Controller } from "@hotwired/stimulus"
import { directHueCall } from "lib/hue_calls"

export default class extends Controller {
  async submit(event) {
    event.preventDefault()
    const form = this.element
    const response = await directHueCall(form.action, new FormData(form, event.submitter), { method: form.method.toUpperCase() })
    this.dispatch("end", { detail: { success: response.ok } })
  }
}
