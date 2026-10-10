const TEMPLATE_SELECTOR = "template[data-toast-template]"

const template = () => document.querySelector(TEMPLATE_SELECTOR)

export function showToast(message) {
  const toastTemplate = template()
  if (!toastTemplate) return
  const toast = toastTemplate.content.firstElementChild.cloneNode(true)
  toast.textContent = message
  document.getElementById(toastTemplate.dataset.toastTarget)?.replaceChildren(toast)
}

export function clearToasts() {
  const toastTemplate = template()
  if (toastTemplate) document.getElementById(toastTemplate.dataset.toastTarget)?.replaceChildren()
}

export const showStillChanging = () => showToast(template()?.dataset.stillChanging)
