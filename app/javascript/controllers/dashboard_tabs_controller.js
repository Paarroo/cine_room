import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabButton", "panel"]

  connect() {
    const savedTab = localStorage.getItem("dashboardTab") || "user"
    this.switchTab(savedTab)
  }

  switch(event) {
    const selectedTab = event.currentTarget.dataset.tab
    this.switchTab(selectedTab)
    localStorage.setItem("dashboardTab", selectedTab)
  }

  switchTab(tabName) {
    this.tabButtonTargets.forEach(button => {
      const isActive = button.dataset.tab === tabName
      button.classList.toggle("text-cinema-blue", tabName === "creator" && isActive)
      button.classList.toggle("text-gold-500", tabName === "user" && isActive)
      button.classList.toggle("border-b-2", isActive)
      button.classList.toggle("border-cinema-blue", tabName === "creator" && isActive)
      button.classList.toggle("border-gold-500", tabName === "user" && isActive)
    })

    this.panelTargets.forEach(panel => {
      const isVisible = panel.dataset.panel === tabName
      panel.classList.toggle("hidden", !isVisible)
      panel.classList.toggle("block", isVisible)
    })
  }
}
