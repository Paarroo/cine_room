import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabButton", "panel"]

  connect() {
    this.showPanel("user") // Show user dashboard by default
  }

  switch(event) {
    const selectedTab = event.currentTarget.dataset.tab

    this.tabButtonTargets.forEach((btn) => {
      btn.classList.remove("bg-cinema-blue", "bg-gold-500", "text-white")
      btn.classList.add("bg-dark-300")
    })

    event.currentTarget.classList.add(selectedTab === "user" ? "bg-gold-500" : "bg-cinema-blue", "text-white")

    this.panelTargets.forEach((panel) => {
      panel.classList.add("hidden")
    })

    this.showPanel(selectedTab)
  }

  showPanel(name) {
    const panel = this.panelTargets.find((el) => el.dataset.panel === name)
    if (panel) panel.classList.remove("hidden")
  }
}
