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
