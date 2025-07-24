import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "selectAll",
    "movieCheckbox",
    "validateBtn",
    "rejectBtn"
  ]

  static values = {
    bulkValidateUrl: String,
    bulkRejectUrl: String
  }

  connect() {
    console.log("🎬 Admin Movies controller connected")
    this.updateBulkActions()
  }

  // Toggle select all checkboxes
  toggleSelectAll() {
    const isChecked = this.selectAllTarget.checked

    this.movieCheckboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })

    this.updateBulkActions()
  }

  // Update bulk actions visibility and count
  updateBulkActions() {
    const checkedBoxes = this.movieCheckboxTargets.filter(cb => cb.checked)
    const bulkActionsDiv = document.getElementById('bulk-actions')

    if (checkedBoxes.length > 0) {
      bulkActionsDiv.classList.remove('hidden')
      bulkActionsDiv.classList.add('flex', 'space-x-3')

      // Update button text with count
      const validateBtn = bulkActionsDiv.querySelector('[data-action*="bulkValidate"]')
      const rejectBtn = bulkActionsDiv.querySelector('[data-action*="bulkReject"]')

      if (validateBtn) {
        validateBtn.innerHTML = `
          <i class="fas fa-check mr-2"></i>
          Valider (${checkedBoxes.length})
        `
      }

      if (rejectBtn) {
        rejectBtn.innerHTML = `
          <i class="fas fa-times mr-2"></i>
          Rejeter (${checkedBoxes.length})
        `
      }
    } else {
      bulkActionsDiv.classList.add('hidden')
      bulkActionsDiv.classList.remove('flex', 'space-x-3')
    }

    // Update select all state
    if (this.hasSelectAllTarget) {
      const totalCheckboxes = this.movieCheckboxTargets.length
      const checkedCount = checkedBoxes.length

      this.selectAllTarget.checked = checkedCount === totalCheckboxes && totalCheckboxes > 0
      this.selectAllTarget.indeterminate = checkedCount > 0 && checkedCount < totalCheckboxes
    }
  }

  // Bulk validate selected movies
  async bulkValidate() {
    const selectedIds = this.getSelectedMovieIds()

    if (selectedIds.length === 0) {
      this.showToast('Aucun film sélectionné', 'warning')
      return
    }

    if (!confirm(`Valider ${selectedIds.length} film(s) sélectionné(s) ?`)) {
      return
    }

    // Pour les actions bulk, on traite les films un par un
    await this.performBulkValidation(selectedIds)
  }

  // Bulk reject selected movies
  async bulkReject() {
    const selectedIds = this.getSelectedMovieIds()

    if (selectedIds.length === 0) {
      this.showToast('Aucun film sélectionné', 'warning')
      return
    }

    if (!confirm(`Rejeter ${selectedIds.length} film(s) sélectionné(s) ?`)) {
      return
    }

    // Pour les actions bulk, on traite les films un par un
    await this.performBulkRejection(selectedIds)
  }

  // Individual movie validation
  async validateMovie(event) {
    const button = event.currentTarget
    const movieId = button.dataset.movieId
    const originalHtml = button.innerHTML

    // Show loading state
    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Validation...'
    button.disabled = true

    try {
      const response = await fetch(`/admin/movies/${movieId}/validate`, {
        method: 'PATCH',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const result = await response.json()

      if (response.ok) {
        this.showToast(result.message, 'success')
        this.refreshMovieCard(movieId, 'approved')
      } else {
        throw new Error(result.message || 'Erreur de validation')
      }
    } catch (error) {
      console.error('Validation error:', error)
      this.showToast(error.message, 'error')
      button.innerHTML = originalHtml
      button.disabled = false
    }
  }

  // Individual movie rejection
  async rejectMovie(event) {
    const button = event.currentTarget
    const movieId = button.dataset.movieId
    const originalHtml = button.innerHTML

    // Show loading state
    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Rejet...'
    button.disabled = true

    try {
      const response = await fetch(`/admin/movies/${movieId}/reject`, {
        method: 'PATCH',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const result = await response.json()

      if (response.ok) {
        this.showToast(result.message, 'success')
        this.refreshMovieCard(movieId, 'rejected')
      } else {
        throw new Error(result.message || 'Erreur de rejet')
      }
    } catch (error) {
      console.error('Rejection error:', error)
      this.showToast(error.message, 'error')
      button.innerHTML = originalHtml
      button.disabled = false
    }
  }

  // Helper methods
  getSelectedMovieIds() {
    return this.movieCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.dataset.movieId)
  }

  async performBulkValidation(movieIds) {
    let successCount = 0
    let errorCount = 0

    for (const movieId of movieIds) {
      try {
        const response = await fetch(`/admin/movies/${movieId}/validate`, {
          method: 'PATCH',
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'X-CSRF-Token': this.getCSRFToken()
          }
        })

        if (response.ok) {
          successCount++
          this.refreshMovieCard(movieId, 'approved')
        } else {
          errorCount++
        }
      } catch (error) {
        console.error('Validation error:', error)
        errorCount++
      }
    }

    if (successCount > 0) {
      this.showToast(`${successCount} film(s) validé(s) avec succès`, 'success')
    }
    if (errorCount > 0) {
      this.showToast(`${errorCount} erreur(s) lors de la validation`, 'error')
    }
  }

  async performBulkRejection(movieIds) {
    let successCount = 0
    let errorCount = 0

    for (const movieId of movieIds) {
      try {
        const response = await fetch(`/admin/movies/${movieId}/reject`, {
          method: 'PATCH',
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'X-CSRF-Token': this.getCSRFToken()
          }
        })

        if (response.ok) {
          successCount++
          this.refreshMovieCard(movieId, 'rejected')
        } else {
          errorCount++
        }
      } catch (error) {
        console.error('Rejection error:', error)
        errorCount++
      }
    }

    if (successCount > 0) {
      this.showToast(`${successCount} film(s) rejeté(s) avec succès`, 'success')
    }
    if (errorCount > 0) {
      this.showToast(`${errorCount} erreur(s) lors du rejet`, 'error')
    }
  }

  refreshMovieCard(movieId, newStatus) {
    const movieCard = document.querySelector(`[data-movie-id="${movieId}"]`).closest('.movie-card')

    if (movieCard) {
      // Update status badge
      const statusBadge = movieCard.querySelector('.status-badge span')
      if (statusBadge) {
        if (newStatus === 'approved') {
          statusBadge.className = 'px-3 py-1 bg-green-500/20 text-green-300 rounded-full text-xs font-medium'
          statusBadge.innerHTML = '<i class="fas fa-check mr-1"></i>Validé'
        } else if (newStatus === 'rejected') {
          statusBadge.className = 'px-3 py-1 bg-red-500/20 text-red-300 rounded-full text-xs font-medium'
          statusBadge.innerHTML = '<i class="fas fa-times mr-1"></i>Rejeté'
        }
      }

      // Remove action buttons and show processed status
      const actionsDiv = movieCard.querySelector('.flex.space-x-2')
      if (actionsDiv) {
        actionsDiv.innerHTML = `
          <span class="text-xs text-gray-500 flex items-center">
            <i class="fas fa-info-circle mr-1"></i>
            Traité par vous
          </span>
        `
      }

      // Uncheck the checkbox
      const checkbox = movieCard.querySelector('[data-admin-movies-target="movieCheckbox"]')
      if (checkbox) {
        checkbox.checked = false
      }

      // Update bulk actions
      this.updateBulkActions()
    }
  }

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
}
