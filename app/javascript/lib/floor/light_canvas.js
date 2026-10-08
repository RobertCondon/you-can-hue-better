import { drawFloorLight } from "lib/floor_light"
import { styleNumber } from "lib/floor/element_style"
import { lightConstants } from "lib/light_constants"

const OFF_CLASS = "is-off"
const MUTED_CLASS = "is-muted"
const WALL = "wall"
const OUTLINE = "outline"

export class FloorLightCanvas {
  constructor(floor) {
    this.floor = floor
  }

  scheduleRedraw() {
    cancelAnimationFrame(this.pendingFrame)
    this.pendingFrame = requestAnimationFrame(() => this.redraw())
  }

  redraw() {
    if (!this.floor.hasCanvasTarget) return
    const canvas = this.floor.canvasTarget, bounds = this.floor.floorTarget.getBoundingClientRect()
    if (bounds.width === 0) return
    const devicePixelRatio = window.devicePixelRatio || 1
    canvas.width = Math.round(bounds.width * devicePixelRatio)
    canvas.height = Math.round(bounds.height * devicePixelRatio)
    const aspect = this.floor.viewport.aspectRatio()
    drawFloorLight(canvas, {
      lights: this.lights(aspect), walls: this.walls(aspect), outline: this.outline(aspect),
      aspect, camera: this.floor.viewport.camera, devicePixelRatio
    })
  }

  lights(aspect) {
    return this.floor.lightTargets
      .filter(lamp => !lamp.classList.contains(OFF_CLASS) && !lamp.classList.contains(MUTED_CLASS))
      .map(lamp => ({
        x: styleNumber(lamp, "--x"), y: styleNumber(lamp, "--y") / aspect,
        hex: lamp.style.getPropertyValue("--hue").trim() || lightConstants().warmWhite, bri: styleNumber(lamp, "--bri")
      }))
  }

  walls(aspect) {
    return this.floor.objectTargets.filter(object => object.dataset.kind === WALL).map(wall => ({
      x: styleNumber(wall, "--x"), y: styleNumber(wall, "--y") / aspect,
      width: styleNumber(wall, "--w"), height: styleNumber(wall, "--h") / aspect, rotation: styleNumber(wall, "--r")
    }))
  }

  outline(aspect) {
    const outline = this.floor.hasNetsTarget && this.floor.netTargets.find(net => net.dataset.kind === OUTLINE)
    return outline ? JSON.parse(outline.dataset.points).map(([pointX, pointY]) => ({ x: pointX, y: pointY / aspect })) : null
  }
}
