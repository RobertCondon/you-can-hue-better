import { Controller } from "@hotwired/stimulus"

const VISIBLE_FOR_MILLISECONDS = 7000

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => this.dismiss(), VISIBLE_FOR_MILLISECONDS)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.remove()
  }
}
