import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 8000 }
  }

  connect() {
    setTimeout(() => {
      this.element.remove()
    }, this.timeoutValue)
  }
}
