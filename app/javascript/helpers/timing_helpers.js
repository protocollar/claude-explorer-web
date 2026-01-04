export function debounce(fn, delay = 300) {
  let timeoutId = null

  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn.apply(this, args), delay)
  }
}

export function nextEvent(element, eventName) {
  return new Promise(resolve => element.addEventListener(eventName, resolve, { once: true }))
}

export function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}
