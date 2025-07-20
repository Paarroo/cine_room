import { Controller } from "@hotwired/stimulus"

// Dropdown Controller - Handles dropdown menus throughout admin interface
export default class extends Controller {
  static targets = ["menu", "trigger"]
  static classes = ["open"]

  static values = {
    closeOnClickOutside: { type: Boolean, default: true },
    closeOnEscape: { type: Boolean, default: true }
  }

  // Lifecycle
  connect() {
    console.log("🔽 Dropdown connected")
    this.setupEventListeners()
  }

  disconnect() {
    this.removeEventListeners()
  }

  // Event listeners setup
  setupEventListeners() {
    if (this.closeOnClickOutsideValue) {
      this.clickOutsideHandler = this.handleClickOutside.bind(this)
      document.addEventListener('click', this.clickOutsideHandler)
    }

    if (this.closeOnEscapeValue) {
      this.escapeHandler = this.handleEscape.bind(this)
      document.addEventListener('keydown', this.escapeHandler)
    }
  }

  removeEventListeners() {
    if (this.clickOutsideHandler) {
      document.removeEventListener('click', this.clickOutsideHandler)
    }

    if (this.escapeHandler) {
      document.removeEventListener('keydown', this.escapeHandler)
    }
  }

  // Toggle dropdown
  toggle(event) {
    event?.preventDefault()
    event?.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  // Open dropdown
  open() {
    if (this.isOpen) return

    // Close other dropdowns first
    this.closeOtherDropdowns()

    this.menuTarget.classList.remove('hidden')
    this.menuTarget.classList.add('block')

    if (this.hasOpenClass) {
      this.element.classList.add(this.openClass)
    }

    // Animate in
    this.animateIn()

    // Focus management
    this.manageFocus()

    // Dispatch event
    this.dispatch('opened')
  }

  // Close dropdown
  close() {
    if (!this.isOpen) return

    // Animate out
    this.animateOut(() => {
      this.menuTarget.classList.add('hidden')
      this.menuTarget.classList.remove('block')

      if (this.hasOpenClass) {
        this.element.classList.remove(this.openClass)
      }

      // Dispatch event
      this.dispatch('closed')
    })
  }

  // Animation methods
  animateIn() {
    this.menuTarget.style.opacity = '0'
    this.menuTarget.style.transform = 'translateY(-10px) scale(0.95)'
    this.menuTarget.style.transition = 'all 0.2s ease-out'

    requestAnimationFrame(() => {
      this.menuTarget.style.opacity = '1'
      this.menuTarget.style.transform = 'translateY(0) scale(1)'
    })
  }

  animateOut(callback) {
    this.menuTarget.style.transition = 'all 0.15s ease-in'
    this.menuTarget.style.opacity = '0'
    this.menuTarget.style.transform = 'translateY(-10px) scale(0.95)'

    setTimeout(() => {
      callback()
      // Reset styles
      this.menuTarget.style.opacity = ''
      this.menuTarget.style.transform = ''
      this.menuTarget.style.transition = ''
    }, 150)
  }

  // Focus management
  manageFocus() {
    const firstFocusable = this.menuTarget.querySelector(
      'a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )

    if (firstFocusable) {
      firstFocusable.focus()
    }
  }

  // Event handlers
  handleClickOutside(event) {
    if (!this.isOpen) return

    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === 'Escape' && this.isOpen) {
      this.close()

      // Return focus to trigger
      if (this.hasTriggerTarget) {
        this.triggerTarget.focus()
      }
    }
  }

  // Close other dropdowns
  closeOtherDropdowns() {
    document.querySelectorAll('[data-controller*="dropdown"]').forEach(element => {
      if (element !== this.element) {
        const controller = this.application.getControllerForElementAndIdentifier(element, 'dropdown')
        if (controller && controller.isOpen) {
          controller.close()
        }
      }
    })
  }

  // State getter
  get isOpen() {
    return !this.menuTarget.classList.contains('hidden')
  }

  // Positioning helpers (for complex dropdowns)
  positionMenu() {
    if (!this.hasTriggerTarget) return

    const trigger = this.triggerTarget
    const menu = this.menuTarget
    const triggerRect = trigger.getBoundingClientRect()
    const menuRect = menu.getBoundingClientRect()
    const viewport = {
      width: window.innerWidth,
      height: window.innerHeight
    }

    // Default positioning
    let top = triggerRect.bottom + window.scrollY
    let left = triggerRect.left + window.scrollX

    // Adjust if menu would go off screen
    if (left + menuRect.width > viewport.width) {
      left = triggerRect.right + window.scrollX - menuRect.width
    }

    if (top + menuRect.height > viewport.height + window.scrollY) {
      top = triggerRect.top + window.scrollY - menuRect.height
    }

    // Apply positioning
    menu.style.position = 'absolute'
    menu.style.top = `${top}px`
    menu.style.left = `${left}px`
    menu.style.zIndex = '50'
  }
}
