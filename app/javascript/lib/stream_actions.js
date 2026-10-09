const LIGHT_IDS_ATTRIBUTE = "light-ids"

export const SETTLED_EVENT = "hue:settled"

export function registerStreamActions() {
  window.Turbo.StreamActions.settle = function () {
    const lightIds = (this.getAttribute(LIGHT_IDS_ATTRIBUTE) || "").split(" ").filter(Boolean)
    document.dispatchEvent(new CustomEvent(SETTLED_EVENT, { detail: { lightIds } }))
  }
}
