import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu"]

  toggleMenu() {
    this.mobileMenuTarget.classList.toggle("hidden")
  }
}