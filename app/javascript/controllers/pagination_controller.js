import { Controller } from "@hotwired/stimulus"
import { createElement } from "helpers/html_helpers"
import { delay, nextEvent } from "helpers/timing_helpers"
import { keepingScrollPosition } from "helpers/scroll_helpers"

const DELAY_BEFORE_OBSERVING = 400

export default class extends Controller {
  static targets = ["paginationLink"]

  loadPage(event) {
    const linkElement = event.target.closest("a")
    this.#loadPaginationLink(linkElement)
  }

  #loadPaginationLink(linkElement) {
    keepingScrollPosition(
      this.#closestSiblingTo(linkElement) || linkElement.parentNode,
      this.#expandPaginationLink(linkElement)
    )
  }

  #closestSiblingTo(element) {
    return element.nextElementSibling || element.previousElementSibling
  }

  async #expandPaginationLink(linkElement) {
    linkElement.setAttribute("aria-busy", "true")
    await this.#replacePaginationLinkWithFrame(linkElement)
    linkElement.remove()
  }

  #replacePaginationLinkWithFrame(linkElement) {
    const turboFrame = this.#buildTurboFrameFor(linkElement)
    this.#insertTurboFrameAtPosition(linkElement, turboFrame)
  }

  #buildTurboFrameFor(linkElement) {
    const turboFrame = createElement("turbo-frame", {
      id: linkElement.dataset.turboFrame,
      src: linkElement.href,
      refresh: "morph",
      target: "_top"
    })

    this.#keepScrollPositionOnFrameRender(turboFrame, linkElement)

    return turboFrame
  }

  async #keepScrollPositionOnFrameRender(turboFrame, linkElement) {
    await nextEvent(turboFrame, "turbo:before-frame-render")
    keepingScrollPosition(linkElement, nextEvent(turboFrame, "turbo:frame-render"))
  }

  #insertTurboFrameAtPosition(linkElement, turboFrame) {
    const container = linkElement.parentNode.parentNode

    if (linkElement.parentNode.firstElementChild === linkElement) {
      container.prepend(turboFrame)
    } else {
      container.append(turboFrame)
    }
  }
}
