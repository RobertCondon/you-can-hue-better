import { hold, release } from "lib/busy"
import { roomIdsOf, snapshotAppearance, restoreAppearance, setStyles } from "lib/floor/element_style"
import { getJson } from "lib/requests"

const MUTED_CLASS = "is-muted"
const ON_CLASS = "is-on"
const OFF_CLASS = "is-off"
const PREVIEWING_CLASS = "is-previewing"
const CHIP_ROW_SELECTOR = ".chips"
const SET_FORM_SELECTOR = "[data-floor-target=setForm]"

export class FloorScenePreview {
  constructor(floor) {
    this.floor = floor
    this.chosenRoomId = ""
    this.originalAppearances = null
  }

  pickRoom(roomId) {
    this.end()
    this.chosenRoomId = roomId
    for (const chip of this.floor.roomChipTargets) chip.setAttribute("aria-pressed", String(chip.dataset.floorRoomParam === roomId))
    for (const row of this.floor.sceneRowTargets) row.hidden = row.dataset.room !== roomId
    this.muteOutsideChosenRoom()
  }

  async pickScene(chip, { url, setUrl, palette, lightIds }) {
    const alreadyShowing = chip.getAttribute("aria-pressed") === "true"
    this.end()
    this.muteOutsideChosenRoom()
    if (alreadyShowing) return

    const states = await getJson(url)
    if (!states) return
    const statesByLight = Object.fromEntries(states.map(state => [state.light_id, state]))
    this.originalAppearances = Object.fromEntries(this.floor.lightTargets.map(lamp => [lamp.dataset.lightId, snapshotAppearance(lamp)]))
    for (const lamp of this.floor.lightTargets) this.showSceneState(lamp, statesByLight[lamp.dataset.lightId])
    chip.setAttribute("aria-pressed", "true")
    this.floor.element.classList.add(PREVIEWING_CLASS)
    this.floor.paint.showScenePalette(palette || [])
    const setForm = chip.closest(CHIP_ROW_SELECTOR).querySelector(SET_FORM_SELECTOR)
    if (setForm) {
      setForm.action = setUrl
      setForm.dataset.asyncHueCallLightIdsValue = JSON.stringify(lightIds || [])
      setForm.hidden = false
    }
  }

  showSceneState(lamp, state) {
    if (state) {
      setStyles(lamp, { "--hue": state.hex, "--bri": state.bri })
      lamp.classList.toggle(ON_CLASS, state.on)
      lamp.classList.toggle(OFF_CLASS, !state.on)
    }
    lamp.classList.toggle(MUTED_CLASS, !state)
    hold(lamp)
  }

  muteOutsideChosenRoom() {
    if (!this.chosenRoomId) return
    for (const lamp of this.floor.lightTargets) {
      lamp.classList.toggle(MUTED_CLASS, !roomIdsOf(lamp).includes(this.chosenRoomId))
      hold(lamp)
    }
  }

  end() {
    for (const lamp of this.floor.lightTargets) {
      const original = this.originalAppearances?.[lamp.dataset.lightId]
      if (original) restoreAppearance(lamp, original)
      lamp.classList.remove(MUTED_CLASS)
      release(lamp)
    }
    this.originalAppearances = null
    this.floor.element.classList.remove(PREVIEWING_CLASS)
    for (const chip of this.floor.sceneChipTargets) chip.setAttribute("aria-pressed", "false")
    for (const setForm of this.floor.setFormTargets) setForm.hidden = true
    this.floor.paint.showScenePalette([])
  }
}
