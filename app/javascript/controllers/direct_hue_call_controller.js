import { Controller } from "@hotwired/stimulus"
import { directHueCall } from "lib/hue_calls"

const METHOD_FIELD = "_method"

export default class extends Controller {
  async submit(event) {
    event.preventDefault()
    const form = this.element
    const fields = new FormData(form, event.submitter)
    const method = (fields.get(METHOD_FIELD) || form.method).toUpperCase()
    const { response, reply } = await directHueCall(form.action, fields, { method })
    this.dispatch("end", { detail: { success: response.ok, error: reply.error } })
  }
}
