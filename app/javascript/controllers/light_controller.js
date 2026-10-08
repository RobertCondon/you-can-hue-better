import { Controller } from "@hotwired/stimulus"
import { release } from "lib/busy"

// The panel's switch and brightness slider. Dragging previews the level on the panel and on every
// tile showing this light; releasing tells the bridge. While dragging, the panel is marked busy so
// a live update from the bridge can't replace it under the pointer.
export default class extends Controller {
  submit(event) {
    release(this.element)
    event.target.form.requestSubmit()
  }

  preview(event) {
    this.element.dataset.busy = "1"
    const value = Number(event.target.value)
    const id = this.element.dataset.lightId
    for (const el of document.querySelectorAll(`[data-light-id="${id}"]`)) {
      el.dataset.brightness = value
      el.style.setProperty("--bri", value / 100)
      el.style.setProperty("--fill", `${value}%`)
      el.classList.remove("is-off"); el.classList.add("is-on")
      for (const level of el.querySelectorAll("[data-level]")) level.textContent = `${value}%`
    }
  }
}
