import { Controller } from "@hotwired/stimulus"
import { sendJson, readJson } from "lib/requests"

const METHOD_FIELD = "_method"

export default class extends Controller {
  static targets = ["error"]
  static values = { confirm: String }

  async submit(event) {
    event.preventDefault()
    if (this.confirmValue && !window.confirm(this.confirmValue)) return
    const fields = new FormData(this.element, event.submitter)
    const method = (fields.get(METHOD_FIELD) || this.element.method).toUpperCase()
    const response = await sendJson(method, this.element.action, fields)
    const reply = await readJson(response)
    if (response.ok) return this.dispatch("saved", { detail: reply })
    if (this.hasErrorTarget) this.errorTarget.textContent = reply.error || ""
  }
}
