import { Controller } from "@hotwired/stimulus"
import { sendJson } from "lib/requests"

const EDITING_CLASS = "is-editing"
const CARD_SELECTOR = ".room-card"
const ROOM_PIECES_SELECTOR = ".room-tab, .room__body"
const ROOM_IDS_FIELD = "ids[]"
const PATCH = "PATCH"
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
    this.move(event.target.closest(CARD_SELECTOR), EARLIER)
  }

  moveDown(event) {
    this.move(event.target.closest(CARD_SELECTOR), LATER)
  }

  // The card, its tab and its body all move, so every row keeps the same order.
  move(card, direction) {
    const cards = this.cards()
    const neighbour = cards[cards.indexOf(card) + direction]
    if (!neighbour) return
    for (const [piece, neighbourPiece] of this.piecesOf(card).map((piece, index) => [piece, this.piecesOf(neighbour)[index]])) {
      direction === EARLIER ? neighbourPiece.before(piece) : neighbourPiece.after(piece)
    }
    this.dispatch("moved", { target: card })
    this.saveOrder()
  }

  cards() {
    return [...this.listTarget.querySelectorAll(CARD_SELECTOR)]
  }

  piecesOf(card) {
    const roomId = card.dataset.roomId
    return [card, ...[...this.listTarget.querySelectorAll(ROOM_PIECES_SELECTOR)].filter(piece => piece.dataset.roomId === roomId)]
  }

  saveOrder() {
    return sendJson(PATCH, this.urlValue, { [ROOM_IDS_FIELD]: this.cards().map(card => card.dataset.roomId) })
  }
}
