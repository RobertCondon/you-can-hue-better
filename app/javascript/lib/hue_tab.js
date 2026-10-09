const HUE_TAB_SELECTOR = 'meta[name="hue-tab"]'

export const HUE_TAB_HEADER = "X-Hue-Tab"

export const hueTab = () => document.querySelector(HUE_TAB_SELECTOR)?.content

export function sendHueTabWithTurboRequests() {
  document.addEventListener("turbo:before-fetch-request", event => {
    const tab = hueTab()
    if (tab) event.detail.fetchOptions.headers[HUE_TAB_HEADER] = tab
  })
}
