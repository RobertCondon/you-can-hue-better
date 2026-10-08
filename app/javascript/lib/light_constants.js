const META_SELECTOR = 'meta[name="light-constants"]'
let constants

export function lightConstants() {
  constants ??= JSON.parse(document.querySelector(META_SELECTOR).content)
  return constants
}
