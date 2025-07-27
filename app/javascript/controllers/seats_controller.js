import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["price"]
  static values = {
    unitPrice: Number
  }

  connect() {
  }

  updatePrice(event) {
    const seats = parseInt(event.target.value) || 1
    const total = this.unitPriceValue * seats
    this.priceTarget.innerText = `${total.toFixed(2)} €`
  }
}
