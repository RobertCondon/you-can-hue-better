import { Controller } from "@hotwired/stimulus"

// Edit mode: up/down buttons move a room section, and the full order is saved on the server
// so every device shares it. The server renders rooms in that order on the next load.
export default class extends Controller {
  static targets = ["list", "editButton"]
  static values = { url: String }

  // Edit mode reveals reorder buttons and the pencil on each room and light.
  toggleEditing() {
    const on = !this.element.classList.contains("is-editing")
    this.element.classList.toggle("is-editing", on)
    this.editButtonTarget.setAttribute("aria-pressed", String(on))
    this.editButtonTarget.textContent = on ? "Done" : "Edit"
  }

  moveUp(event)   { this.move(event.target.closest(".room"), -1) }
  moveDown(event) { this.move(event.target.closest(".room"), +1) }

  move(section, delta) {
    const sections = this.sections()
    const i = sections.indexOf(section), j = i + delta
    if (j < 0 || j >= sections.length) return
    const ref = sections[j]
    delta < 0 ? ref.before(section) : ref.after(section)
    this.save()
  }

  sections() { return [...this.listTarget.querySelectorAll(":scope > .room")] }

  async save() {
    const body = new FormData()
    for (const s of this.sections()) body.append("ids[]", s.dataset.roomId)
    await fetch(this.urlValue, {
      method: "PATCH", body,
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
  }
}
