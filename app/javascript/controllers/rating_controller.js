import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rating"
export default class extends Controller {
  static targets = ["star", "input"]

  connect() {
    this.selected = 0
  }

  highlight(event) {
    const value = parseInt(event.currentTarget.dataset.value)
    this.clearHighlight()
    this.starTargets.forEach((star, index) => {
      if (index < value) star.classList.add("hovered")
    })
  }

  reset() {
    this.clearHighlight()
    this.updateSelection(this.selected)
  }

  select(event) {
    const value = parseInt(event.currentTarget.dataset.value)
    this.selected = value
    this.inputTarget.value = value
    this.updateSelection(value)
  }

  updateSelection(value) {
    this.starTargets.forEach((star, index) => {
      star.classList.toggle("selected", index < value)
    })
  }

  clearHighlight() {
    this.starTargets.forEach(star => star.classList.remove("hovered"))
  }
}
