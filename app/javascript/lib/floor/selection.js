const SELECTED_CLASS = "is-selected"

export class FloorSelection {
  constructor(floor) {
    this.floor = floor
    this.object = null
    this.net = null
  }

  selectObject(object) {
    this.clear()
    this.object = object
    for (const candidate of this.floor.objectTargets) candidate.classList.toggle(SELECTED_CLASS, candidate === object)
    if (!object || !this.floor.hasSelectionTarget) return
    this.floor.selectionTarget.hidden = false
    this.floor.selectionNameTarget.textContent = object.getAttribute("aria-label")
  }

  selectNet(net, name) {
    this.clear()
    this.net = net
    net.classList.add(SELECTED_CLASS)
    this.floor.selectionTarget.hidden = false
    this.floor.selectionNameTarget.textContent = name
    this.floor.netRoomTarget.hidden = false
    this.floor.netRoomTarget.value = net.dataset.groupId || ""
  }

  clear() {
    if (this.net) {
      this.net.classList.remove(SELECTED_CLASS)
      this.floor.nets.unmountVertices()
    }
    for (const candidate of this.floor.objectTargets) candidate.classList.remove(SELECTED_CLASS)
    this.object = null
    this.net = null
    if (!this.floor.hasSelectionTarget) return
    this.floor.selectionTarget.hidden = true
    if (this.floor.hasNetRoomTarget) this.floor.netRoomTarget.hidden = true
  }
}
