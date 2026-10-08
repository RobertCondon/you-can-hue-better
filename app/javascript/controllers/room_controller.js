import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "rooms:collapsed"
const COLLAPSED_CLASS = "is-collapsed"
const TITLE_SELECTOR = ".room__title"

export default class extends Controller {
  connect() {
    this.show(this.collapsedRoomIds().includes(this.roomId))
  }

  toggle() {
    const collapsedIds = new Set(this.collapsedRoomIds())
    const collapsed = !collapsedIds.has(this.roomId)
    collapsed ? collapsedIds.add(this.roomId) : collapsedIds.delete(this.roomId)
    this.remember([...collapsedIds])
    this.show(collapsed)
  }

  show(collapsed) {
    this.element.classList.toggle(COLLAPSED_CLASS, collapsed)
    this.element.querySelector(TITLE_SELECTOR)?.setAttribute("aria-expanded", String(!collapsed))
  }

  get roomId() {
    return this.element.dataset.roomId
  }

  collapsedRoomIds() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]")
    } catch {
      return []
    }
  }

  remember(roomIds) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(roomIds))
    } catch {}
  }
}
