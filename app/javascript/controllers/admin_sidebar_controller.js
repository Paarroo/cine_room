import { Controller } from "@hotwired/stimulus"

// Admin Sidebar Controller
  static targets = [
    "sidebar",
    "overlay",
    "nav",
    "navItem",
    "section",
    "quickAction",
    "logoutBtn"
  ]

  static values = {
    collapsed: { type: Boolean, default: false },
    mobile: { type: Boolean, default: false }
  }

  // Lifecycle
  connect() {
    console.log("🎬 Admin Sidebar connected")
    this.setupResponsive()
    this.setupKeyboardShortcuts()
    this.initializeCollapsedState()
  }

  disconnect() {
    this.removeKeyboardListeners()
  }

  // Responsive handling
  setupResponsive() {
    this.checkMobile()
    window.addEventListener('resize', this.handleResize.bind(this))
  }

  handleResize() {
    this.checkMobile()
  }

  checkMobile() {
    const wasMobile = this.mobileValue
    this.mobileValue = window.innerWidth < 1024

    if (wasMobile !== this.mobileValue) {
      if (this.mobileValue) {
        this.hideSidebar()
      } else {
        this.showSidebar()
      }
    }
  }

  // Sidebar Toggle
  toggleSidebar() {
    if (this.mobileValue) {
      this.isOpen ? this.closeSidebar() : this.openSidebar()
    } else {
      this.collapsedValue ? this.expandSidebar() : this.collapseSidebar()
    }
  }

  openSidebar() {
    if (!this.mobileValue) return

    this.sidebarTarget.classList.remove('-translate-x-full')
    this.overlayTarget.classList.remove('hidden')
    this.isOpen = true

    // Accessibility
    this.sidebarTarget.setAttribute('aria-hidden', 'false')
    document.body.classList.add('overflow-hidden')
  }

  closeSidebar() {
    if (!this.mobileValue) return

    this.sidebarTarget.classList.add('-translate-x-full')
    this.overlayTarget.classList.add('hidden')
    this.isOpen = false

    // Accessibility
    this.sidebarTarget.setAttribute('aria-hidden', 'true')
    document.body.classList.remove('overflow-hidden')
  }

  // Desktop Collapse/Expand
  collapseSidebar() {
    if (this.mobileValue) return

    this.collapsedValue = true
    this.sidebarTarget.classList.add('sidebar-collapsed')
    this.sidebarTarget.style.width = '80px'

    // Hide text elements
    this.navTarget.querySelectorAll('.nav-label').forEach(label => {
      label.classList.add('hidden')
    })

    this.persistCollapsedState()
  }

  expandSidebar() {
    if (this.mobileValue) return

    this.collapsedValue = false
    this.sidebarTarget.classList.remove('sidebar-collapsed')
    this.sidebarTarget.style.width = '256px'

    // Show text elements
    this.navTarget.querySelectorAll('.nav-label').forEach(label => {
      label.classList.remove('hidden')
    })

    this.persistCollapsedState()
  }

  // State Persistence
  initializeCollapsedState() {
    const saved = localStorage.getItem('admin-sidebar-collapsed')
    if (saved === 'true' && !this.mobileValue) {
      this.collapseSidebar()
    }
  }

  persistCollapsedState() {
    localStorage.setItem('admin-sidebar-collapsed', this.collapsedValue)
  }

  // Quick Actions
  exportData(event) {
    event.preventDefault()
    this.showToast('📊 Export des données en cours...', 'info')

    // Simulate API call
    setTimeout(() => {
      this.showToast('✅ Export terminé avec succès !', 'success')
      // Here you would trigger actual download
    }, 2000)
  }

  backupDatabase(event) {
    event.preventDefault()

    if (!confirm('Lancer une sauvegarde de la base de données ?')) {
      return
    }

    this.showToast('💾 Sauvegarde en cours...', 'info')

    // Simulate backup
    setTimeout(() => {
      this.showToast('✅ Sauvegarde terminée !', 'success')
    }, 3000)
  }

  // Navigation Enhancement
  highlightActiveSection() {
    const currentPath = window.location.pathname

    this.navItemTargets.forEach(item => {
      const link = item.getAttribute('href')
      const isActive = currentPath.includes(link)

      if (isActive) {
        item.classList.add('nav-active')
        // Scroll into view if needed
        item.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
      } else {
        item.classList.remove('nav-active')
      }
    })
  }

  // Keyboard Shortcuts
  setupKeyboardShortcuts() {
    this.keyboardHandler = this.handleKeyboard.bind(this)
    document.addEventListener('keydown', this.keyboardHandler)
  }

  removeKeyboardListeners() {
    if (this.keyboardHandler) {
      document.removeEventListener('keydown', this.keyboardHandler)
    }
  }

  handleKeyboard(event) {
    // Ctrl+Shift+S - Toggle Sidebar
    if (event.ctrlKey && event.shiftKey && event.key === 'S') {
      event.preventDefault()
      this.toggleSidebar()
    }

    // Escape - Close mobile sidebar
    if (event.key === 'Escape' && this.mobileValue && this.isOpen) {
      this.closeSidebar()
    }
  }

  // Utility Methods
  showToast(message, type = 'info') {
    // Dispatch custom event for toast notifications
    this.dispatch('toast', {
      detail: { message, type }
    })
  }

  // Hide sidebar for mobile
  hideSidebar() {
    if (this.mobileValue) {
      this.sidebarTarget.classList.add('-translate-x-full')
    }
  }

  // Show sidebar for desktop
  showSidebar() {
    if (!this.mobileValue) {
      this.sidebarTarget.classList.remove('-translate-x-full')
    }
  }

  // Navigation item click handler
  handleNavClick(event) {
    const navItem = event.currentTarget

    // Add loading state
    navItem.classList.add('nav-loading')

    // Remove loading after navigation
    setTimeout(() => {
      navItem.classList.remove('nav-loading')
    }, 500)

    // Close mobile sidebar after navigation
    if (this.mobileValue) {
      this.closeSidebar()
    }
  }

  // Section collapse/expand
  toggleSection(event) {
    const section = event.currentTarget.closest('[data-admin-sidebar-target="section"]')
    const isCollapsed = section.classList.contains('section-collapsed')

    if (isCollapsed) {
      section.classList.remove('section-collapsed')
    } else {
      section.classList.add('section-collapsed')
    }
  }
}
