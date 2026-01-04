import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["children"]

  expandAll() {
    this.childrenTargets.forEach(el => el.hidden = false)
  }

  collapseAll() {
    this.childrenTargets.forEach(el => el.hidden = true)
  }
}
