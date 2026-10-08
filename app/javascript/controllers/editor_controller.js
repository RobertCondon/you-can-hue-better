import { Controller } from "@hotwired/stimulus"

// The name/nickname dialog. Opened from a pencil button whose params say which light or room,
// where to send the form, and the current values. Closes itself when the save succeeds; a bridge
// rejection comes back as a 422 with the message rendered into the dialog, so it stays open.
export default class extends Controller {
  static targets = ["dialog", "form", "title", "name", "nickname"]

  open(event) {
    const p = event.params
    this.formTarget.action = p.url
    this.titleTarget.textContent = p.title
    if (this.hasNameTarget) { this.nameTarget.name = `${p.kind}[name]`; this.nameTarget.value = p.name || "" }
    this.nicknameTarget.name = `${p.kind}[nickname]`
    this.nicknameTarget.value = p.nickname || ""
    this.dialogTarget.querySelector("#editor_error").textContent = ""
    this.dialogTarget.showModal()
    ;(this.hasNameTarget ? this.nameTarget : this.nicknameTarget).select()
  }

  close() {
    this.dialogTarget.close()
  }

  submitted(event) {
    if (event.detail.success) this.close()
  }
}
