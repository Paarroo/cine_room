import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "selectAll",
    "participationCheckbox",
    "confirmBtn",
    "cancelBtn"
  ]

  connect() {
    console.log("🎫 Admin Participations controller connected")
    this.updateBulkActions()
  }

  // Toggle select all checkboxes
  toggleSelectAll() {
    const isChecked = this.selectAllTarget.checked

    this.participationCheckboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })

    this.updateBulkActions()
  }

  // Update bulk actions visibility and count
  updateBulkActions() {
    const checkedBoxes = this.participationCheckboxTargets.filter(cb => cb.checked)
    const bulkActionsDiv = document.getElementById('bulk-actions')

    if (checkedBoxes.length > 0) {
      bulkActionsDiv.classList.remove('hidden')
      bulkActionsDiv.classList.add('flex', 'space-x-3')

      // Update button text with count
      const confirmBtn = bulkActionsDiv.querySelector('[data-action*="bulkConfirm"]')
      const cancelBtn = bulkActionsDiv.querySelector('[data-action*="bulkCancel"]')

      if (confirmBtn) {
        confirmBtn.innerHTML = `
          <i class="fas fa-check mr-2"></i>
          Confirmer (${checkedBoxes.length})
        `
      }

      if (cancelBtn) {
        cancelBtn.innerHTML = `
          <i class="fas fa-times mr-2"></i>
          Annuler (${checkedBoxes.length})
        `
      }
    } else {
      bulkActionsDiv.classList.add('hidden')
      bulkActionsDiv.classList.remove('flex', 'space-x-3')
    }

    // Update select all state
    if (this.hasSelectAllTarget) {
      const totalCheckboxes = this.participationCheckboxTargets.length
      const checkedCount = checkedBoxes.length

      this.selectAllTarget.checked = checkedCount === totalCheckboxes && totalCheckboxes > 0
      this.selectAllTarget.indeterminate = checkedCount > 0 && checkedCount < totalCheckboxes
    }
  }

  // Bulk confirm selected participations
  async bulkConfirm() {
    const selectedIds = this.getSelectedParticipationIds()

    if (selectedIds.length === 0) {
      this.showToast('Aucune participation sélectionnée', 'warning')
      return
    }

    if (!confirm(`Confirmer ${selectedIds.length} participation(s) sélectionnée(s) ?`)) {
      return
    }

    try {
      const response = await fetch('/admin/participations/bulk_confirm', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          participation_ids: selectedIds
        })
      })

      const result = await response.json()

      if (response.ok) {
        this.showToast(result.message, 'success')
        // Refresh the page to show updated data
        window.location.reload()
      } else {
        throw new Error(result.error || 'Erreur lors de la confirmation')
      }
    } catch (error) {
      console.error('Bulk confirm error:', error)
      this.showToast(error.message, 'error')
    }
  }

  // Bulk cancel selected participations
  async bulkCancel() {
    const selectedIds = this.getSelectedParticipationIds()

    if (selectedIds.length === 0) {
      this.showToast('Aucune participation sélectionnée', 'warning')
      return
    }

    if (!confirm(`Annuler ${selectedIds.length} participation(s) sélectionnée(s) ?`)) {
      return
    }

    try {
      const response = await fetch('/admin/participations/bulk_cancel', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          participation_ids: selectedIds
        })
      })

      const result = await response.json()

      if (response.ok) {
        this.showToast(result.message, 'success')
        // Refresh the page to show updated data
        window.location.reload()
      } else {
        throw new Error(result.error || 'Erreur lors de l\'annulation')
      }
    } catch (error) {
      console.error('Bulk cancel error:', error)
      this.showToast(error.message, 'error')
    }
  }

  // Helper methods
  getSelectedParticipationIds() {
    return this.participationCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.dataset.participationId)
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