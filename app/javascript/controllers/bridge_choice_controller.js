import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["address"]

  choose(event) {
    this.addressTarget.value = event.target.value
  }
}
