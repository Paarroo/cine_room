import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    timeout: { type: Number, default: 8000 },
    isAdmin: { type: Boolean, default: false }
  }

  connect() {
    if (this.isAdminValue) {
      console.log("💬 Admin Flash connected")
      this.setupGlobalToastListener()
    } else {
      // Simple flash message with auto-remove
      setTimeout(() => {
        this.element.remove()
      }, this.timeoutValue)
    }
  }

  setupGlobalToastListener() {
    // Listen for toast events from other controllers
    document.addEventListener('admin-dashboard:toast', (event) => {
      const { message, type } = event.detail
      this.showToast(message, type)
    })
  }

  showToast(message, type = 'info') {
    const toast = this.createToast(message, type)
    document.body.appendChild(toast)

    // Animate in
    setTimeout(() => {
      toast.classList.add('show')
    }, 100)

    // Auto-remove after 5 seconds (unless it's an error)
    if (type !== 'error') {
      setTimeout(() => {
        this.removeToast(toast)
      }, 5000)
    }
  }

  createToast(message, type) {
    const toast = document.createElement('div')
    toast.className = `admin-toast ${type}`

    toast.innerHTML = `
      <div class="flex items-center space-x-3">
        <div class="flex-shrink-0">
          <i class="${this.getToastIcon(type)}"></i>
        </div>
        <div class="flex-1 min-w-0">
          <div class="text-sm font-medium">${message}</div>
          <div class="text-xs opacity-75 mt-1">${new Date().toLocaleTimeString()}</div>
        </div>
        <button class="flex-shrink-0 ml-3 p-1 hover:bg-white/10 rounded-lg transition-colors"
                onclick="this.parentElement.parentElement.remove()">
          <i class="fas fa-times text-xs"></i>
        </button>
      </div>
    `

    return toast
  }

  removeToast(toast) {
    toast.classList.add('removing')
    setTimeout(() => {
      if (toast.parentNode) {
        toast.remove()
      }
    }, 300)
  }

  getToastIcon(type) {
    const icons = {
      success: 'fas fa-check-circle text-green-400',
      error: 'fas fa-exclamation-circle text-red-400',
      warning: 'fas fa-exclamation-triangle text-yellow-400',
      info: 'fas fa-info-circle text-blue-400'
    }
    return icons[type] || 'fas fa-bell text-white'
  }
}