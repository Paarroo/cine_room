import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "selectAll",
    "reviewCheckbox"
  ]

  connect() {
    console.log("📝 Admin Reviews controller connected")
    this.updateBulkActions()
  }

  // Toggle select all checkboxes
  toggleSelectAll() {
    const isChecked = this.selectAllTarget.checked

    this.reviewCheckboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })

    this.updateBulkActions()
  }

  // Update bulk actions visibility and count
  updateBulkActions() {
    const checkedBoxes = this.reviewCheckboxTargets.filter(cb => cb.checked)
    const bulkActionsDiv = document.getElementById('bulk-actions')

    if (checkedBoxes.length > 0) {
      bulkActionsDiv.classList.remove('hidden')
      bulkActionsDiv.classList.add('flex', 'space-x-3')

      // Update button text with count
      this.updateBulkButtonText(bulkActionsDiv, checkedBoxes.length)
    } else {
      bulkActionsDiv.classList.add('hidden')
      bulkActionsDiv.classList.remove('flex', 'space-x-3')
    }

    // Update select all state
    this.updateSelectAllState(checkedBoxes.length)
  }

  // Bulk operations
  async bulkApprove() {
    const selectedIds = this.getSelectedReviewIds()

    if (selectedIds.length === 0) {
      this.showToast('Aucun avis sélectionné', 'warning')
      return
    }

    if (!confirm(`Approuver ${selectedIds.length} avis sélectionné(s) ?`)) {
      return
    }

    await this.performBulkAction('/admin/reviews/bulk_approve', selectedIds, 'approbation')
  }

  async bulkReject() {
    const selectedIds = this.getSelectedReviewIds()

    if (selectedIds.length === 0) {
      this.showToast('Aucun avis sélectionné', 'warning')
      return
    }

    if (!confirm(`Rejeter ${selectedIds.length} avis sélectionné(s) ?`)) {
      return
    }

    await this.performBulkAction('/admin/reviews/bulk_reject', selectedIds, 'rejet')
  }

  // Helper methods
  getSelectedReviewIds() {
    return this.reviewCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.dataset.reviewId)
  }

  async performBulkAction(url, reviewIds, actionType) {
    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ review_ids: reviewIds })
      })

      const result = await response.json()

      if (response.ok) {
        this.showToast(result.message, 'success')
        setTimeout(() => {
          window.location.reload()
        }, 1500)
      } else {
        throw new Error(result.message || `Erreur lors du ${actionType}`)
      }
    } catch (error) {
      console.error(`Bulk ${actionType} error:`, error)
      this.showToast(error.message, 'error')
    }
  }

  updateBulkButtonText(bulkActionsDiv, count) {
    const approveBtn = bulkActionsDiv.querySelector('[data-action*="bulkApprove"]')
    const rejectBtn = bulkActionsDiv.querySelector('[data-action*="bulkReject"]')

    if (approveBtn) {
      approveBtn.innerHTML = `
        <i class="fas fa-check mr-2"></i>
        Approuver (${count})
      `
    }

    if (rejectBtn) {
      rejectBtn.innerHTML = `
        <i class="fas fa-times mr-2"></i>
        Rejeter (${count})
      `
    }
  }

  updateSelectAllState(checkedCount) {
    if (this.hasSelectAllTarget) {
      const totalCheckboxes = this.reviewCheckboxTargets.length

      this.selectAllTarget.checked = checkedCount === totalCheckboxes && totalCheckboxes > 0
      this.selectAllTarget.indeterminate = checkedCount > 0 && checkedCount < totalCheckboxes
    }
  }

  getCSRFToken() {
    const token = document.querySelector('[name="csrf-token"]')
    return token ? token.content : ''
  }

  showToast(message, type = 'info') {
    this.dispatch('toast', {
      detail: { message, type }
    })
  }
}
