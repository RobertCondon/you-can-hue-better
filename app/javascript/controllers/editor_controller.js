import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "title", "name", "nickname", "error"]

  open(event) {
    const { url, title, kind, name, nickname } = event.params
    this.formTarget.action = url
    this.titleTarget.textContent = title
    if (this.hasNameTarget) {
      this.nameTarget.name = `${kind}[name]`
      this.nameTarget.value = name || ""
    }
    this.nicknameTarget.name = `${kind}[nickname]`
    this.nicknameTarget.value = nickname || ""
    this.errorTarget.textContent = ""
    this.dialogTarget.showModal()
    this.firstField.select()
  }

  close() {
    this.dialogTarget.close()
  }

  submitted(event) {
    if (event.detail.success) this.close()
  }

  get firstField() {
    return this.hasNameTarget ? this.nameTarget : this.nicknameTarget
  }
}
