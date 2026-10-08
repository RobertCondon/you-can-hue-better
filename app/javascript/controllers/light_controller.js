import { Controller } from "@hotwired/stimulus"
import { hold, release } from "lib/busy"
import { previewLevel } from "lib/light_preview"

export default class extends Controller {
  submit(event) {
    release(this.element)
    event.target.form.requestSubmit()
  }

  preview(event) {
    hold(this.element)
    previewLevel(this.element.dataset.lightId, Number(event.target.value))
  }
}
