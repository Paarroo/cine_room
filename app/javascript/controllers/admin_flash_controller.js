import { Controller } from "@hotwired/stimulus"

// Admin Flash Messages Controller - Handles flash message display and auto-dismiss
export default class extends Controller {
  static targets = ["message", "dismissBtn", "progressBar"]

  static values = {
    autoDismiss: { type: Boolean, default: true },
    dismissDelay: { type: Number, default: 5000 }
  }

  // Lifecycle
  connect() {
    console.log("💬 Admin Flash connected")
    this.setupAutoDismiss()
    this.setupAccessibility()
  }

  disconnect() {
    this.clearTimers()
  }

  // Auto-dismiss setup
  setupAutoDismiss() {
    if (!this.autoDismissValue) return

    this.messageTargets.forEach(message => {
      const type = message.dataset.flashType

      // Don't auto-dismiss error messages
      if (type === 'error') return

      const delay = this.dismissDelayValue
      const progressBar = message.querySelector('[data-admin-flash-target="progressBar"]')

      // Set up auto-dismiss timer
      const timer = setTimeout(() => {
        this.dismissMessage({ currentTarget: message })
      }, delay)

      // Store timer reference for cleanup
      message.dataset.dismissTimer = timer

      // Animate progress bar
      if (progressBar) {
        progressBar.style.animation = `progressShrink ${delay}ms linear`
      }
    })
  }

  // Accessibility setup
  setupAccessibility() {
    this.messageTargets.forEach(message => {
      // Add ARIA attributes
      message.setAttribute('role', 'alert')
      message.setAttribute('aria-live', 'polite')

      // Add keyboard support
      message.setAttribute('tabindex', '0')
      message.addEventListener('keydown', this.handleKeydown.bind(this))
    })
  }

  // Manual dismiss
  dismissMessage(event) {
    const message = event.currentTarget.closest('[data-admin-flash-target="message"]') ||
                   event.currentTarget

    // Clear auto-dismiss timer
    const timerId = message.dataset.dismissTimer
    if (timerId) {
      clearTimeout(parseInt(timerId))
    }

    // Add dismissing animation
    message.classList.add('dismissing')

    // Remove from DOM after animation
    setTimeout(() => {
      if (message.parentNode) {
        message.remove()
      }

      // Check if all messages are dismissed
      if (this.messageTargets.length === 0) {
        this.element.remove()
      }
    }, 300)

    // Announce to screen readers
    this.announceToScreenReader('Message dismissed')
  }

  // Dismiss all messages
  dismissAll() {
    this.messageTargets.forEach(message => {
      this.dismissMessage({ currentTarget: message })
    })
  }

  // Keyboard handling
  handleKeydown(event) {
    // Enter or Space to dismiss
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.dismissMessage(event)
    }

    // Escape to dismiss
    if (event.key === 'Escape') {
      this.dismissMessage(event)
    }
  }

  // Add new flash message dynamically
  addMessage(type, content, options = {}) {
    const container = this.element
    const autoClose = options.autoClose !== false
    const delay = options.delay || this.dismissDelayValue

    // Create message HTML
    const messageHtml = this.createMessageHTML(type, content, autoClose)

    // Insert into container
    container.insertAdjacentHTML('beforeend', messageHtml)

    // Get the newly added message
    const newMessage = container.lastElementChild

    // Set up auto-dismiss if enabled
    if (autoClose && type !== 'error') {
      const timer = setTimeout(() => {
        this.dismissMessage({ currentTarget: newMessage })
      }, delay)

      newMessage.dataset.dismissTimer = timer
    }

    // Add accessibility attributes
    newMessage.setAttribute('role', 'alert')
    newMessage.setAttribute('aria-live', 'polite')

    // Announce to screen readers
    this.announceToScreenReader(content)

    return newMessage
  }

  // Create message HTML
  createMessageHTML(type, content, autoClose) {
    const iconMap = {
      success: 'fas fa-check-circle text-green-400',
      error: 'fas fa-exclamation-circle text-red-400',
      warning: 'fas fa-exclamation-triangle text-yellow-400',
      info: 'fas fa-info-circle text-blue-400'
    }

    const colorMap = {
      success: 'border-green-500/30 bg-green-500/10 text-green-300',
      error: 'border-red-500/30 bg-red-500/10 text-red-300',
      warning: 'border-yellow-500/30 bg-yellow-500/10 text-yellow-300',
      info: 'border-blue-500/30 bg-blue-500/10 text-blue-300'
    }

    const icon = iconMap[type] || 'fas fa-bell text-primary'
    const colors = colorMap[type] || 'border-white/20 bg-white/5 text-content'
    const now = new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })

    return `
      <div
        class="flash-message glass-effect border rounded-xl p-4 shadow-lg transform transition-all duration-300 max-w-md ${colors}"
        data-admin-flash-target="message"
        data-flash-type="${type}"
        style="animation: slideInRight 0.3s ease-out"
      >
        <div class="flex items-start space-x-3">
          <div class="flex-shrink-0 mt-0.5">
            <i class="${icon}"></i>
          </div>

          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium leading-5">
              ${content}
            </div>
            <div class="mt-1 text-xs opacity-75">
              ${now}
            </div>
          </div>

          <button
            class="flex-shrink-0 ml-3 p-1.5 hover:bg-white/10 rounded-lg transition-colors"
            data-action="click->admin-flash#dismissMessage"
            data-admin-flash-target="dismissBtn"
          >
            <i class="fas fa-times text-xs opacity-75 hover:opacity-100"></i>
          </button>
        </div>

        ${autoClose && type !== 'error' ? `
          <div class="progress-bar mt-3 h-1 bg-white/10 rounded-full overflow-hidden">
            <div
              class="progress-fill h-full bg-current rounded-full transition-all duration-linear"
              data-admin-flash-target="progressBar"
              style="animation: progressShrink ${this.dismissDelayValue}ms linear"
            ></div>
          </div>
        ` : ''}
      </div>
    `
  }
