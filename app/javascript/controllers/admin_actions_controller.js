import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actionButton"]
  static values = { 
    url: String,
    method: String,
    confirm: String,
    successMessage: String,
    errorMessage: String,
    params: Object
  }

  connect() {
  }

  // Universal action handler for all admin operations
  async executeAction(event) {
    const button = event.currentTarget
    const url = button.dataset.url
    const method = button.dataset.method || 'PATCH'
    const confirmMessage = button.dataset.confirm
    const successMessage = button.dataset.successMessage
    const errorMessage = button.dataset.errorMessage
    const params = button.dataset.params ? JSON.parse(button.dataset.params) : {}

    // Confirm if required
    if (confirmMessage && !confirm(confirmMessage)) {
      return
    }

    // Show loading state
    this.setLoadingState(button, true)

    try {
      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: Object.keys(params).length > 0 ? JSON.stringify(params) : null
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()

      if (result.status === 'success') {
        this.showToast(successMessage || result.message || 'Action réussie', 'success')
        this.handleSuccessAction(button, result)
      } else {
        throw new Error(result.message || result.error || 'Erreur lors de l\'action')
      }
    } catch (error) {
      console.error('Admin action error:', error)
      this.showToast(errorMessage || error.message || 'Erreur de connexion', 'error')
    } finally {
      this.setLoadingState(button, false)
    }
  }

  // Handle success actions (UI updates, redirects, etc.)
  handleSuccessAction(button, result) {
    const actionType = button.dataset.actionType

    switch (actionType) {
      case 'status-update':
        this.updateStatusDisplay(button, result.new_status)
        break
      case 'role-update':
        this.updateRoleDisplay(button, result.new_role)
        break
      case 'validation':
        this.handleValidationSuccess(button, result)
        break
      case 'deletion':
        this.handleDeletionSuccess(button)
        break
      case 'approval':
        this.handleApprovalSuccess(button, result)
        break
      default:
        // Default behavior - just show success
        break
    }

    // Optional redirect
    if (result.redirect_url) {
      setTimeout(() => {
        window.location.href = result.redirect_url
      }, 1000)
    }
  }

  // Update status displays
  updateStatusDisplay(button, newStatus) {
    const statusElement = button.closest('.status-container')?.querySelector('.status-badge')
    if (statusElement) {
      statusElement.className = `status-badge status-${newStatus}`
      statusElement.textContent = this.getStatusText(newStatus)
    }
  }

  // Update role displays
  updateRoleDisplay(button, newRole) {
    const roleElement = button.closest('.role-container')?.querySelector('.role-badge')
    if (roleElement) {
      roleElement.className = `role-badge role-${newRole}`
      roleElement.textContent = this.getRoleText(newRole)
    }
  }

  // Handle validation success (movies, reviews)
  handleValidationSuccess(button, result) {
    const card = button.closest('.admin-card')
    if (card) {
      card.classList.add('opacity-50', 'pointer-events-none')
      const statusBadge = card.querySelector('.status-badge')
      if (statusBadge) {
        statusBadge.className = 'status-badge status-approved'
        statusBadge.textContent = 'Approuvé'
      }
    }
  }

  // Handle deletion success
  handleDeletionSuccess(button) {
    const card = button.closest('.admin-card')
    if (card) {
      card.style.transition = 'all 0.3s ease'
      card.style.opacity = '0'
      card.style.transform = 'scale(0.95)'
      setTimeout(() => {
        card.remove()
      }, 300)
    }
  }

  // Handle approval success
  handleApprovalSuccess(button, result) {
    const card = button.closest('.admin-card')
    if (card) {
      const statusBadge = card.querySelector('.status-badge')
      if (statusBadge) {
        statusBadge.className = 'status-badge status-approved'
        statusBadge.textContent = 'Approuvé'
      }
    }
  }

  // Loading state management
  setLoadingState(button, isLoading) {
    if (isLoading) {
      button.disabled = true
      button.dataset.originalHtml = button.innerHTML
      button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'
    } else {
      button.disabled = false
      if (button.dataset.originalHtml) {
        button.innerHTML = button.dataset.originalHtml
        delete button.dataset.originalHtml
      }
    }
  }

  // Helper methods
  getCSRFToken() {
    const token = document.querySelector('[name="csrf-token"]')
    return token ? token.content : ''
  }

  showToast(message, type = 'info') {
    // Dispatch event for admin-flash controller
    this.dispatch('toast', {
      detail: { message, type }
    })
  }

  getStatusText(status) {
    const statusTexts = {
      'pending': 'En attente',
      'confirmed': 'Confirmé',
      'cancelled': 'Annulé',
      'approved': 'Approuvé',
      'rejected': 'Rejeté',
      'active': 'Actif',
      'inactive': 'Inactif'
    }
    return statusTexts[status] || status
  }

  getRoleText(role) {
    const roleTexts = {
      'user': 'Utilisateur',
      'creator': 'Créateur',
      'admin': 'Administrateur'
    }
    return roleTexts[role] || role
  }
}