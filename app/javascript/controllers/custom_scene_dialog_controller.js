import { Controller } from "@hotwired/stimulus"
import { getHtml } from "lib/requests"

export default class extends Controller {
  static targets = ["dialog", "content"]

  async open(event) {
    const html = await getHtml(event.params.url)
    if (!html) return
    this.contentTarget.innerHTML = html
    this.dialogTarget.showModal()
    this.dialogTarget.querySelector("input[type=text]")?.focus()
  }

  close() {
    this.dialogTarget.close()
  }

  submitted(event) {
    if (event.detail.success) this.close()
  }
}
