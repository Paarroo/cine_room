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

    await this.performBulkAction('/admin/movies/bulk_validate', selectedIds, 'validation')
  }
