import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
    this.dialogTarget.querySelector(".is-current")?.scrollIntoView({ block: "nearest" })
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  // A click that lands on the dialog itself is on its backdrop, outside the sheet.
  closeFromBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
