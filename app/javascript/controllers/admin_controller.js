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
