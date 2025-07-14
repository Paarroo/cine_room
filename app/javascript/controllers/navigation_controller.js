// app/javascript/controllers/navigation_controller.js
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
      case "venues":
        window.location.href = "/venues"
        break
      case "events":
        window.location.href = "/events"
        break
      default:
        break
    }
  }
}
