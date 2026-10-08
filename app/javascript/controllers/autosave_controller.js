import { Controller } from "@hotwired/stimulus"

// A form that saves itself when one of its controls changes.
export default class extends Controller {
  save() { this.element.requestSubmit() }
}
