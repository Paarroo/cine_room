import { Controller } from "@hotwired/stimulus"

// Admin Header Controller - Handles header interactions and responsive behavior
export default class extends Controller {
  static targets = [
    "header",
    "mobileToggle",
    "breadcrumb",
    "title",
    "quickStats",
    "search",
    "notifications",
    "userMenu"
  ]

  static values = {
    scrolled: { type: Boolean, default: false }
  }

  // Lifecycle
  connect() {
    console.log("🎬 Admin Header connected")
    this.setupScrollListener()
    this.setupClickOutside()
    this.updateQuickStats()
  }

  disconnect() {
    this.removeScrollListener()
    this.removeClickOutside()
  }

  // Scroll Effects
  setupScrollListener() {
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.scrollHandler, { passive: true })
  }

  removeScrollListener() {
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler)
    }
  }

  handleScroll() {
    const scrollY = window.scrollY
    const wasScrolled = this.scrolledValue
    this.scrolledValue = scrollY > 10

    if (wasScrolled !== this.scrolledValue) {
      this.updateHeaderAppearance()
    }
  }

  updateHeaderAppearance() {
    if (this.scrolledValue) {
      this.headerTarget.classList.add('header-scrolled')
      this.headerTarget.style.backdropFilter = 'blur(20px)'
    } else {
      this.headerTarget.classList.remove('header-scrolled')
      this.headerTarget.style.backdropFilter = 'blur(10px)'
    }
  }

  // Mobile Menu Toggle
  toggleMobileMenu() {
    const sidebarController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="admin-sidebar"]'),
      'admin-sidebar'
    )

    if (sidebarController) {
      sidebarController.toggleSidebar()
    }
  }

  // Quick Stats Update
  updateQuickStats() {
    if (!this.hasQuickStatsTarget) return

    // Fetch fresh stats via Turbo Stream or AJAX
    this.fetchQuickStats()
  }

  async fetchQuickStats() {
    try {
      const response = await fetch('/admin/quick_stats', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.renderQuickStats(data)
      }
    } catch (error) {
      console.error('Failed to fetch quick stats:', error)
    }
  }
