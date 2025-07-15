import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu"]

  toggleMenu() {
    this.mobileMenuTarget.classList.toggle("hidden")
  }

  // Fermer le menu mobile quand on clique sur un lien
  connect() {
    this.element.addEventListener('click', (e) => {
      if (e.target.closest('a') && !this.mobileMenuTarget.classList.contains('hidden')) {
        this.mobileMenuTarget.classList.add('hidden')
      }
    })
  }
}
