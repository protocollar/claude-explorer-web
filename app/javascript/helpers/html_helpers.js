export function createElement(name, properties) {
  const element = document.createElement(name)

  for (const key in properties) {
    element.setAttribute(key, properties[key])
  }

  return element
}
