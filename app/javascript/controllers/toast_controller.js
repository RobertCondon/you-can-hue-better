import { Controller } from "@hotwired/stimulus"

// A message that gets out of the way: click to dismiss, or it goes by itself.
export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => this.dismiss(), 7000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.remove()
  }
}
