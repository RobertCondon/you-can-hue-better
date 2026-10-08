import { Controller } from "@hotwired/stimulus"
import { patch, formDataFrom } from "lib/requests"

const EDITING_CLASS = "is-editing"
const ROOM_SELECTOR = ".room"
const EARLIER = -1
const LATER = 1

export default class extends Controller {
  static targets = ["list", "editButton"]
  static values = { url: String, editLabel: String, doneLabel: String }

  toggleEditing() {
    const editing = !this.element.classList.contains(EDITING_CLASS)
    this.element.classList.toggle(EDITING_CLASS, editing)
    this.editButtonTarget.setAttribute("aria-pressed", String(editing))
    this.editButtonTarget.textContent = editing ? this.doneLabelValue : this.editLabelValue
  }

  moveUp(event) {
    this.move(event.target.closest(ROOM_SELECTOR), EARLIER)
  }

  moveDown(event) {
    this.move(event.target.closest(ROOM_SELECTOR), LATER)
  }

  move(section, direction) {
    const sections = this.sections()
    const neighbour = sections[sections.indexOf(section) + direction]
    if (!neighbour) return
    direction === EARLIER ? neighbour.before(section) : neighbour.after(section)
    this.saveOrder()
  }

  sections() {
    return [...this.listTarget.querySelectorAll(`:scope > ${ROOM_SELECTOR}`)]
  }

  saveOrder() {
    const body = formDataFrom({})
    for (const section of this.sections()) body.append("ids[]", section.dataset.roomId)
    return patch(this.urlValue, body)
  }
}
