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

  renderQuickStats(data) {
    // Update quick stats display
    const statsContainer = this.quickStatsTarget

    statsContainer.innerHTML = `
      <div class="quick-stat-item flex items-center space-x-2">
        <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
        <span class="text-sm text-muted">${data.online_users} en ligne</span>
      </div>
      <div class="quick-stat-item flex items-center space-x-2">
        <div class="w-2 h-2 bg-accent rounded-full"></div>
        <span class="text-sm text-muted">${data.pending_items} en attente</span>
      </div>
    `
  }

  // Breadcrumb Management
  updateBreadcrumb(items) {
    if (!this.hasBreadcrumbTarget) return

    const breadcrumbHtml = items.map((item, index) => {
      const isLast = index === items.length - 1

      return `
        <div class="breadcrumb-item flex items-center">
          ${index > 0 ? '<i class="fas fa-chevron-right text-xs text-muted mx-2"></i>' : ''}
          ${isLast
            ? `<span class="text-content font-medium">${item.label}</span>`
            : `<a href="${item.path}" class="text-muted hover:text-content transition-colors">${item.label}</a>`
          }
        </div>
      `
    }).join('')

    this.breadcrumbTarget.innerHTML = breadcrumbHtml
  }

  // Page Title Management
  updatePageTitle(title) {
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = title
    }

    // Update document title
    document.title = `🎬 ${title} - CinéRoom Admin`
  }

  // Click Outside Handler
  setupClickOutside() {
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.clickOutsideHandler)
  }

  removeClickOutside() {
    if (this.clickOutsideHandler) {
      document.removeEventListener('click', this.clickOutsideHandler)
    }
  }

  handleClickOutside(event) {
    // Close dropdowns when clicking outside
    const dropdowns = this.element.querySelectorAll('.dropdown-open')

    dropdowns.forEach(dropdown => {
      if (!dropdown.contains(event.target)) {
        dropdown.classList.remove('dropdown-open')
      }
    })
  }

  // Keyboard Shortcuts
  handleKeyboardShortcut(event) {
    // Ctrl+K - Focus search
    if (event.ctrlKey && event.key === 'k') {
      event.preventDefault()
      this.focusSearch()
    }

    // Ctrl+Shift+N - Show notifications
    if (event.ctrlKey && event.shiftKey && event.key === 'N') {
      event.preventDefault()
      this.toggleNotifications()
    }
  }

  // Search Focus
  focusSearch() {
    const searchController = this.application.getControllerForElementAndIdentifier(
      this.searchTarget,
      'admin-search'
    )

    if (searchController) {
      searchController.focusInput()
    }
  }

  // Notifications Toggle
  toggleNotifications() {
    const notificationsController = this.application.getControllerForElementAndIdentifier(
      this.notificationsTarget,
      'admin-notifications'
    )

    if (notificationsController) {
      notificationsController.toggleDropdown()
    }
  }

  // Real-time Updates
  handleRealtimeUpdate(event) {
    const { type, data } = event.detail

    switch (type) {
      case 'new_participation':
        this.updateNotificationBadge(1)
        this.showToast('Nouvelle participation reçue', 'info')
        break

      case 'movie_pending':
        this.updateNotificationBadge(1)
        this.showToast('Nouveau film en attente de validation', 'warning')
        break

      case 'user_registered':
        this.updateQuickStats()
        break
    }
  }

  // Notification Badge Update
  updateNotificationBadge(increment = 0) {
    const badge = this.notificationsTarget.querySelector('.notification-badge')
    if (!badge) return

    const current = parseInt(badge.textContent) || 0
    const newCount = current + increment

    badge.textContent = newCount > 9 ? '9+' : newCount
    badge.classList.toggle('hidden', newCount === 0)
  }

  // Toast Notification
  showToast(message, type = 'info') {
    this.dispatch('toast', {
      detail: { message, type }
    })
  }

  // Responsive Helper
  checkMobile() {
    return window.innerWidth < 1024
  }

  // Animation Helper
  animateElement(element, animation) {
    element.classList.add(animation)

    setTimeout(() => {
      element.classList.remove(animation)
    }, 300)
  }
}
