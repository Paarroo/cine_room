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
