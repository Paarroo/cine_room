import { Controller } from "@hotwired/stimulus"

// Main Admin Controller - Coordinates admin interface and global admin functionality
export default class extends Controller {
  static targets = ["body", "content", "sidebar", "modals"]

  static values = {
    theme: { type: String, default: "dark" },
    sidebarCollapsed: { type: Boolean, default: false },
    realTimeEnabled: { type: Boolean, default: true }
  }

  // Lifecycle
  connect() {
    console.log("🎬 Admin Panel connected")
    this.initializeTheme()
    this.setupGlobalKeyboardShortcuts()
    this.setupRealTimeUpdates()
    this.setupTurboListeners()
    this.checkUserPermissions()
  }

  disconnect() {
    this.teardownListeners()
  }

  // Theme Management
  initializeTheme() {
    const savedTheme = localStorage.getItem('admin-theme') || this.themeValue
    this.applyTheme(savedTheme)
  }

  applyTheme(theme) {
    this.themeValue = theme
    this.bodyTarget.classList.remove('theme-light', 'theme-dark', 'theme-auto')
    this.bodyTarget.classList.add(`theme-${theme}`)

    // Save to localStorage
    localStorage.setItem('admin-theme', theme)

    // Update meta theme-color for mobile browsers
    const metaTheme = document.querySelector('meta[name="theme-color"]')
    if (metaTheme) {
      metaTheme.content = theme === 'light' ? '#ffffff' : '#0a0a0a'
    }
  }

  toggleTheme() {
    const newTheme = this.themeValue === 'dark' ? 'light' : 'dark'
    this.applyTheme(newTheme)
    this.showToast(`Thème ${newTheme === 'dark' ? 'sombre' : 'clair'} activé`, 'success')
  }

  // Global Keyboard Shortcuts
  setupGlobalKeyboardShortcuts() {
    this.keyboardHandler = this.handleGlobalKeyboard.bind(this)
    document.addEventListener('keydown', this.keyboardHandler)
  }

  handleGlobalKeyboard(event) {
    // Only handle shortcuts when not in input fields
    if (this.isInputFocused()) return

    // Ctrl+/ - Show shortcuts help
    if (event.ctrlKey && event.key === '/') {
      event.preventDefault()
      this.showShortcutsModal()
    }

    // Ctrl+Shift+T - Toggle theme
    if (event.ctrlKey && event.shiftKey && event.key === 'T') {
      event.preventDefault()
      this.toggleTheme()
    }

    // Ctrl+Shift+D - Toggle debug mode
    if (event.ctrlKey && event.shiftKey && event.key === 'D') {
      event.preventDefault()
      this.toggleDebugMode()
    }

    // Esc - Close modals/dropdowns
    if (event.key === 'Escape') {
      this.closeAllModals()
      this.closeAllDropdowns()
    }
  }

  // Real-time Updates
  setupRealTimeUpdates() {
    if (!this.realTimeEnabledValue) return

    // ActionCable or WebSocket connection would go here
    this.connectToUpdates()
  }

  connectToUpdates() {
    // Simulate real-time updates for demo
    this.updateInterval = setInterval(() => {
      this.checkForUpdates()
    }, 30000) // Check every 30 seconds
  }

  async checkForUpdates() {
    try {
      const response = await fetch('/admin/updates', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const updates = await response.json()
        this.processUpdates(updates)
      }
    } catch (error) {
      console.error('Failed to check for updates:', error)
    }
  }

  processUpdates(updates) {
    updates.forEach(update => {
      this.dispatch('realtime-update', {
        detail: { type: update.type, data: update.data }
      })
    })
  }

  // Turbo Integration
  setupTurboListeners() {
    // Handle Turbo navigation
    document.addEventListener('turbo:visit', this.handleTurboVisit.bind(this))
    document.addEventListener('turbo:load', this.handleTurboLoad.bind(this))
    document.addEventListener('turbo:before-fetch-request', this.handleTurboRequest.bind(this))
  }

  handleTurboVisit(event) {
    // Show loading indicator
    this.showLoadingIndicator()
  }

  handleTurboLoad(event) {
    // Hide loading indicator
    this.hideLoadingIndicator()

    // Reinitialize any necessary components
    this.reinitializeComponents()
  }

  handleTurboRequest(event) {
    // Add admin-specific headers
    event.detail.fetchOptions.headers['X-Admin-Request'] = 'true'
    event.detail.fetchOptions.headers['X-Admin-Version'] = '1.0'
  }

  // Modal Management
  openModal(modalId, options = {}) {
    const modal = document.getElementById(modalId)
    if (!modal) {
      console.error(`Modal ${modalId} not found`)
      return
    }

    // Set modal content if provided
    if (options.content) {
      const modalBody = modal.querySelector('.modal-body')
      if (modalBody) {
        modalBody.innerHTML = options.content
      }
    }

    // Show modal
    modal.classList.remove('hidden')
    modal.classList.add('modal-open')

    // Add to modals container if not already there
    if (!this.modalsTarget.contains(modal)) {
      this.modalsTarget.appendChild(modal)
    }

    // Focus management
    this.trapFocus(modal)

    // Prevent body scroll
    document.body.classList.add('modal-open')

    // Dispatch event
    this.dispatch('modal-opened', { detail: { modalId, options } })
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId)
    if (!modal) return

    modal.classList.add('modal-closing')

    setTimeout(() => {
      modal.classList.remove('modal-open', 'modal-closing')
      modal.classList.add('hidden')

      // Restore body scroll if no other modals
      if (!document.querySelector('.modal-open')) {
        document.body.classList.remove('modal-open')
      }

      // Restore focus
      this.restoreFocus()

      // Dispatch event
      this.dispatch('modal-closed', { detail: { modalId } })
    }, 300)
  }

  closeAllModals() {
    const openModals = document.querySelectorAll('.modal-open')
    openModals.forEach(modal => {
      this.closeModal(modal.id)
    })
  }

  // Dropdown Management
  closeAllDropdowns() {
    const openDropdowns = document.querySelectorAll('.dropdown-open')
    openDropdowns.forEach(dropdown => {
      dropdown.classList.remove('dropdown-open')
    })
  }

  // Loading Indicators
  showLoadingIndicator() {
    const existingLoader = document.querySelector('.admin-loader')
    if (existingLoader) return

    const loader = document.createElement('div')
    loader.className = 'admin-loader fixed top-0 left-0 w-full h-1 z-50'
    loader.innerHTML = `
      <div class="loader-bar h-full bg-primary animate-pulse" style="width: 0; animation: loading 2s ease-in-out infinite"></div>
    `

    document.body.appendChild(loader)

    // Animate to 90% width
    setTimeout(() => {
      const bar = loader.querySelector('.loader-bar')
      bar.style.width = '90%'
      bar.style.transition = 'width 0.5s ease'
    }, 100)
  }

  hideLoadingIndicator() {
    const loader = document.querySelector('.admin-loader')
    if (!loader) return

    const bar = loader.querySelector('.loader-bar')
    bar.style.width = '100%'

    setTimeout(() => {
      loader.remove()
    }, 300)
  }

  // Component Reinitialization
  reinitializeComponents() {
    // Reinitialize tooltips, date pickers, etc.
    this.initializeTooltips()
    this.initializeDatePickers()
    this.updatePageMetadata()
  }

  // Tooltip Initialization
  initializeTooltips() {
    const tooltipElements = document.querySelectorAll('[data-tooltip]')
    tooltipElements.forEach(element => {
      if (!element.hasAttribute('data-tooltip-initialized')) {
        this.setupTooltip(element)
        element.setAttribute('data-tooltip-initialized', 'true')
      }
    })
  }

  setupTooltip(element) {
    let tooltip = null

    element.addEventListener('mouseenter', () => {
      const text = element.getAttribute('data-tooltip')
      tooltip = this.createTooltip(text)
      document.body.appendChild(tooltip)
      this.positionTooltip(tooltip, element)
    })

    element.addEventListener('mouseleave', () => {
      if (tooltip) {
        tooltip.remove()
        tooltip = null
      }
    })
  }

  createTooltip(text) {
    const tooltip = document.createElement('div')
    tooltip.className = 'admin-tooltip fixed z-50 px-2 py-1 text-xs bg-surface border border-white/20 rounded-lg text-content shadow-lg pointer-events-none'
    tooltip.textContent = text
    return tooltip
  }

  positionTooltip(tooltip, element) {
    const rect = element.getBoundingClientRect()
    const tooltipRect = tooltip.getBoundingClientRect()

    let top = rect.top - tooltipRect.height - 8
    let left = rect.left + (rect.width - tooltipRect.width) / 2

    // Adjust if tooltip goes off screen
    if (top < 0) {
      top = rect.bottom + 8
    }

    if (left < 0) {
      left = 8
    } else if (left + tooltipRect.width > window.innerWidth) {
      left = window.innerWidth - tooltipRect.width - 8
    }

    tooltip.style.top = `${top}px`
    tooltip.style.left = `${left}px`
  }

  // Date Picker Initialization
  initializeDatePickers() {
    const dateInputs = document.querySelectorAll('input[type="date"], input[type="datetime-local"]')
    dateInputs.forEach(input => {
      if (!input.hasAttribute('data-datepicker-initialized')) {
        this.setupDatePicker(input)
        input.setAttribute('data-datepicker-initialized', 'true')
      }
    })
  }

  setupDatePicker(input) {
    // Add custom styling and behavior for date inputs
    input.classList.add('admin-datepicker')

    // Add calendar icon
    const wrapper = document.createElement('div')
    wrapper.className = 'relative'
    input.parentNode.insertBefore(wrapper, input)
    wrapper.appendChild(input)

    const icon = document.createElement('i')
    icon.className = 'fas fa-calendar-alt absolute right-3 top-1/2 transform -translate-y-1/2 text-muted pointer-events-none'
    wrapper.appendChild(icon)
  }

  // Page Metadata Update
  updatePageMetadata() {
    // Update page title if specified
    const titleElement = document.querySelector('[data-page-title]')
    if (titleElement) {
      const title = titleElement.getAttribute('data-page-title')
      document.title = `🎬 ${title} - CinéRoom Admin`
    }

    // Update breadcrumb if header controller exists
    const headerController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="admin-header"]'),
      'admin-header'
    )

    if (headerController) {
      const breadcrumbData = this.extractBreadcrumbData()
      if (breadcrumbData.length > 0) {
        headerController.updateBreadcrumb(breadcrumbData)
      }
    }
  }

  extractBreadcrumbData() {
    const breadcrumbElements = document.querySelectorAll('[data-breadcrumb]')
    return Array.from(breadcrumbElements).map(element => ({
      label: element.textContent.trim(),
      path: element.getAttribute('href') || element.getAttribute('data-breadcrumb-path')
    }))
  }

  // User Permissions Check
  checkUserPermissions() {
    const userRole = document.body.getAttribute('data-user-role')
    const requiredPermissions = document.body.getAttribute('data-required-permissions')

    if (requiredPermissions && userRole) {
      const permissions = requiredPermissions.split(',')
      const hasAccess = this.userHasPermissions(userRole, permissions)

      if (!hasAccess) {
        this.showAccessDeniedMessage()
      }
    }
  }

  userHasPermissions(userRole, requiredPermissions) {
    const rolePermissions = {
      'admin': ['read', 'write', 'delete', 'manage'],
      'moderator': ['read', 'write'],
      'viewer': ['read']
    }

    const userPermissions = rolePermissions[userRole] || []
    return requiredPermissions.every(permission => userPermissions.includes(permission))
  }

  showAccessDeniedMessage() {
    this.showToast('Accès non autorisé à cette section', 'error')

    // Redirect to safe page after delay
    setTimeout(() => {
      window.location.href = '/admin'
    }, 3000)
  }

  // Debug Mode
  toggleDebugMode() {
    const isDebug = this.bodyTarget.classList.toggle('debug-mode')

    if (isDebug) {
      this.enableDebugMode()
      this.showToast('Mode debug activé', 'info')
    } else {
      this.disableDebugMode()
      this.showToast('Mode debug désactivé', 'info')
    }

    localStorage.setItem('admin-debug', isDebug)
  }

  enableDebugMode() {
    // Add debug indicators to elements
    document.querySelectorAll('[data-controller]').forEach(element => {
      element.style.outline = '1px dashed #f59e0b'
      element.setAttribute('title', `Controller: ${element.getAttribute('data-controller')}`)
    })

    // Log controller connections
    console.log('🐛 Debug mode enabled - Controllers will be logged')
  }

  disableDebugMode() {
    // Remove debug indicators
    document.querySelectorAll('[data-controller]').forEach(element => {
      element.style.outline = ''
      element.removeAttribute('title')
    })
  }

  // Shortcuts Modal
  showShortcutsModal() {
    const shortcuts = [
      { key: 'Ctrl + /', description: 'Afficher cette aide' },
      { key: 'Ctrl + K', description: 'Recherche rapide' },
      { key: 'Ctrl + Shift + S', description: 'Basculer la sidebar' },
      { key: 'Ctrl + Shift + T', description: 'Changer le thème' },
      { key: 'Ctrl + Shift + D', description: 'Mode debug' },
      { key: 'Escape', description: 'Fermer modales/dropdowns' }
    ]

    const content = `
      <div class="shortcuts-modal p-6">
        <h3 class="text-xl font-bold mb-4">Raccourcis clavier</h3>
        <div class="space-y-3">
          ${shortcuts.map(shortcut => `
            <div class="flex items-center justify-between">
              <span class="text-muted">${shortcut.description}</span>
              <kbd class="px-2 py-1 bg-white/10 rounded text-xs font-mono">${shortcut.key}</kbd>
            </div>
          `).join('')}
        </div>
      </div>
    `

    this.openModal('shortcuts-modal', { content })
  }

  // Utility Methods
  isInputFocused() {
    const activeElement = document.activeElement
    return activeElement && (
      activeElement.tagName === 'INPUT' ||
      activeElement.tagName === 'TEXTAREA' ||
      activeElement.contentEditable === 'true'
    )
  }

  trapFocus(modal) {
    const focusableElements = modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )

    if (focusableElements.length === 0) return

    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]

    firstElement.focus()

    modal.addEventListener('keydown', (e) => {
      if (e.key === 'Tab') {
        if (e.shiftKey && document.activeElement === firstElement) {
          e.preventDefault()
          lastElement.focus()
        } else if (!e.shiftKey && document.activeElement === lastElement) {
          e.preventDefault()
          firstElement.focus()
        }
      }
    })
  }

  restoreFocus() {
    // Restore focus to previously focused element
    if (this.previousFocus) {
      this.previousFocus.focus()
      this.previousFocus = null
    }
  }

  showToast(message, type = 'info') {
    this.dispatch('toast', {
      detail: { message, type }
    })
  }

  // Cleanup
  teardownListeners() {
    if (this.keyboardHandler) {
      document.removeEventListener('keydown', this.keyboardHandler)
    }

    if (this.updateInterval) {
      clearInterval(this.updateInterval)
    }
  }
}
