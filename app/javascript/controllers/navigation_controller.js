import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu"]

  navigate(event) {
    const target = event.currentTarget.dataset.target

    switch (target) {
      case "home":
        window.location.href = "/"
        break
      case "creators":
        window.location.href = "/creators"
        break
      case "about":
        window.location.href = "/about"
        break
      case "events":
        window.location.href = "/events"
        break
      case "movies":
        window.location.href = "/movies"
        break
      default:
        break
    }
    
    if (window.innerWidth < 1024) {
      this.toggleMenu()
    }
  }
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
