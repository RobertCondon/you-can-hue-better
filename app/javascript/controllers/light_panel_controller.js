import { Controller } from "@hotwired/stimulus"

// Pins a light: fetches its bar and panel into the dock at the top of the page, where it stays
// while the room scrolls. One pinned light at a time; tapping the same tile again unpins it, a
// swipe on the bar moves to the next light in that room.
export default class extends Controller {
  static targets = ["dock"]

  async toggle(event) {
    const { id, pinUrl, room } = event.params
    if (this.openId === id) return this.close()
    await this.pin(id, pinUrl, room)
  }

  async pin(id, url, room) {
    const res = await fetch(url, { headers: { Accept: "text/html" } })
    if (!res.ok) return
    this.dockTarget.innerHTML = await res.text()
    this.dockTarget.hidden = false
    this.dockTarget.dataset.room = room || ""
    this.openId = id
    for (const t of this.element.querySelectorAll(".tile")) {
      const on = t.dataset.lightId === id
      t.classList.toggle("is-pinned", on)
      t.querySelector(".tile__open")?.setAttribute("aria-expanded", String(on))
    }
  }

  close() {
    this.dockTarget.innerHTML = ""
    this.dockTarget.hidden = true
    this.dockTarget.classList.remove("is-expanded")
    this.openId = null
    for (const t of this.element.querySelectorAll(".tile.is-pinned")) {
      t.classList.remove("is-pinned")
      t.querySelector(".tile__open")?.setAttribute("aria-expanded", "false")
    }
  }

  // A swipe on the bar: the next or previous light in the room the pinned one came from.
  swipe(event) {
    const room = this.dockTarget.dataset.room
    const scope = room ? this.element.querySelector(`#room_${CSS.escape(room)}`) : this.element
    const ids = [...(scope || this.element).querySelectorAll(".tile[data-light-id]")].map(t => t.dataset.lightId)
    const i = ids.indexOf(this.openId)
    if (i < 0 || ids.length < 2) return
    const next = ids[(i + event.detail.dir + ids.length) % ids.length]
    const tile = this.element.querySelector(`.tile[data-light-id="${next}"] .tile__open`)
    if (tile) this.pin(next, tile.dataset.lightPanelPinUrlParam, room)
  }
}
