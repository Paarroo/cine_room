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
