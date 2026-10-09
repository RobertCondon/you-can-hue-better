import { getHtml } from "lib/requests"

const DOCK_MAX_WIDTH = 900
const PHONE_MAX_WIDTH = 640
const OPEN_CLASS = "is-open"
const EXPANDED_CLASS = "is-expanded"
const PANEL_PATH_END = /panel$/
const PIN_PATH_END = "pin"
const EDGE_MARGIN = 12
const DOT_CENTRE_FROM_TOP = 7
const GAP_FROM_DOT = 18
const RISE_ABOVE_DOT = 24

export class FloorLampPanel {
  constructor(floor) {
    this.floor = floor
    this.openLamp = null
  }

  async toggle(lamp, panelUrl) {
    if (this.openLamp === lamp) return this.close()
    const docked = window.innerWidth < DOCK_MAX_WIDTH && this.floor.hasDockTarget
    const html = await getHtml(docked ? panelUrl.replace(PANEL_PATH_END, PIN_PATH_END) : panelUrl)
    if (!html) return
    this.close()
    if (docked) this.showIn(this.floor.dockTarget, this.floor.dockTarget, html)
    else this.showIn(this.floor.popoverTarget, this.floor.popoverBodyTarget, html)
    this.openLamp = lamp
    for (const candidate of this.floor.lightTargets) candidate.classList.toggle(OPEN_CLASS, candidate === lamp)
    if (!docked) this.reposition()
  }

  showIn(container, body, html) {
    body.innerHTML = html
    container.hidden = false
  }

  close() {
    if (this.floor.hasDockTarget) {
      this.floor.dockTarget.innerHTML = ""
      this.floor.dockTarget.hidden = true
      this.floor.dockTarget.classList.remove(EXPANDED_CLASS)
    }
    if (this.floor.hasPopoverTarget) {
      this.floor.popoverTarget.hidden = true
      this.floor.popoverBodyTarget.innerHTML = ""
    }
    this.openLamp = null
    for (const lamp of this.floor.lightTargets) lamp.classList.remove(OPEN_CLASS)
  }

  reposition() {
    if (!this.openLamp || !this.floor.hasPopoverTarget || this.floor.popoverTarget.hidden || window.innerWidth < PHONE_MAX_WIDTH) return
    const wrapper = this.floor.element.getBoundingClientRect(), floorBounds = this.floor.floorTarget.getBoundingClientRect()
    const lampBounds = this.openLamp.getBoundingClientRect(), popover = this.floor.popoverTarget
    const dot = { x: lampBounds.left + lampBounds.width / 2, y: lampBounds.top + DOT_CENTRE_FROM_TOP }
    let left = dot.x + GAP_FROM_DOT
    if (left + popover.offsetWidth > floorBounds.right - EDGE_MARGIN) left = dot.x - GAP_FROM_DOT - popover.offsetWidth
    left = Math.max(floorBounds.left + EDGE_MARGIN, left)
    const top = Math.min(Math.max(floorBounds.top + EDGE_MARGIN, dot.y - RISE_ABOVE_DOT), floorBounds.bottom - popover.offsetHeight - EDGE_MARGIN)
    popover.style.left = `${left - wrapper.left}px`
    popover.style.top = `${top - wrapper.top}px`
  }
}
