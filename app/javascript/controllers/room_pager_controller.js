import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "rooms:current"
const CURRENT_CLASS = "is-current"
const CARD_GAP = 10
const STEERING_MS = 700
const TAB_INSET = 16

export default class extends Controller {
  static targets = ["pager", "card", "tab", "tabs", "body", "dot"]

  connect() {
    const remembered = this.cardTargets.findIndex(card => card.dataset.roomId === this.rememberedRoomId())
    this.show(Math.max(remembered, 0))
    this.scrollPagerTo(this.index, false)
  }

  scrolled() {
    if (this.steering || !this.hasCardTarget) return
    const index = Math.round(this.pagerTarget.scrollLeft / this.cardStep)
    if (index !== this.index && this.cardTargets[index]) this.show(index)
  }

  select(event) {
    const index = this.cardTargets.findIndex(card => card.dataset.roomId === event.params.room)
    if (index < 0) return
    this.show(index)
    this.scrollPagerTo(index, true)
  }

  show(index) {
    const changed = this.index !== undefined && this.index !== index
    this.index = index
    this.roomId = this.cardTargets[index]?.dataset.roomId
    this.bodyTargets.forEach(body => this.showBody(body))
    this.tabTargets.forEach(tab => this.markTab(tab))
    this.dotTargets.forEach((dot, dotIndex) => dot.classList.toggle(CURRENT_CLASS, dotIndex === index))
    this.revealTab()
    this.remember(this.roomId)
    if (changed) this.dispatch("changed", { detail: { roomId: this.roomId } })
  }

  bodyTargetConnected(body) {
    if (this.roomId) this.showBody(body)
  }

  tabTargetConnected(tab) {
    if (this.roomId) this.markTab(tab)
  }

  showBody(body) {
    body.hidden = body.dataset.roomId !== this.roomId
  }

  markTab(tab) {
    tab.setAttribute("aria-selected", String(tab.dataset.roomId === this.roomId))
  }

  follow() {
    const index = this.cardTargets.findIndex(card => card.dataset.roomId === this.roomId)
    if (index < 0) return
    this.show(index)
    this.scrollPagerTo(index, false)
  }

  scrollPagerTo(index, smooth) {
    if (!this.hasPagerTarget || !this.hasCardTarget) return
    this.steering = true
    clearTimeout(this.steeringTimer)
    this.pagerTarget.scrollTo({ left: index * this.cardStep, behavior: smooth ? "smooth" : "instant" })
    this.steeringTimer = setTimeout(() => { this.steering = false }, smooth ? STEERING_MS : 0)
  }

  revealTab() {
    const tab = this.tabTargets.find(candidate => candidate.dataset.roomId === this.roomId)
    if (tab && this.hasTabsTarget) this.tabsTarget.scrollTo({ left: tab.offsetLeft - TAB_INSET, behavior: "smooth" })
  }

  get cardStep() {
    return this.cardTargets[0].offsetWidth + CARD_GAP
  }

  rememberedRoomId() {
    try {
      return localStorage.getItem(STORAGE_KEY)
    } catch {
      return null
    }
  }

  remember(roomId) {
    try {
      if (roomId) localStorage.setItem(STORAGE_KEY, roomId)
    } catch {}
  }
}
