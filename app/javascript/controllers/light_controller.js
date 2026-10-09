import { Controller } from "@hotwired/stimulus"
import { hold, release } from "lib/busy"
import { isPending } from "lib/light_intents"
import { previewLevel } from "lib/light_preview"

export default class extends Controller {
  submit(event) {
    if (!isPending(this.element.dataset.lightId)) release(this.element)
    event.target.form.requestSubmit()
  }

  preview(event) {
    if (isPending(this.element.dataset.lightId)) return
    hold(this.element)
    previewLevel(this.element.dataset.lightId, Number(event.target.value))
  }
}
