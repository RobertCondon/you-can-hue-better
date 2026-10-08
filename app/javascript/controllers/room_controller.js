import { Controller } from "@hotwired/stimulus"

// Collapses a room. Remembered per device in localStorage, and reapplied whenever the
// section is re-rendered by a broadcast.
const KEY = "rooms:collapsed"

export default class extends Controller {
  connect() {
    this.apply(this.collapsedIds().includes(this.id))
  }

  toggle() {
    const ids = new Set(this.collapsedIds())
    const collapsed = !ids.has(this.id)
    collapsed ? ids.add(this.id) : ids.delete(this.id)
    this.save([...ids])
    this.apply(collapsed)
  }

  apply(collapsed) {
    this.element.classList.toggle("is-collapsed", collapsed)
    const title = this.element.querySelector(".room__title")
    if (title) title.setAttribute("aria-expanded", String(!collapsed))
  }

  get id() { return this.element.dataset.roomId }

  collapsedIds() {
    try { return JSON.parse(localStorage.getItem(KEY) || "[]") } catch { return [] }
  }

  save(ids) {
    try { localStorage.setItem(KEY, JSON.stringify(ids)) } catch {}
  }
}
