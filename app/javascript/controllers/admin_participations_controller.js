import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "selectAll",
    "participationCheckbox",
    "confirmBtn",
    "cancelBtn"
  ]

  connect() {
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
    const selectedCountSpan = document.getElementById('selected-count')

    if (checkedBoxes.length > 0) {
      bulkActionsDiv.classList.remove('hidden')

      // Update count display
      if (selectedCountSpan) {
        selectedCountSpan.textContent = checkedBoxes.length
      }

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

    // Show loading state
    this.setLoadingState(true, 'confirm')

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


      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()

      if (result.status === 'success') {
        this.showToast(result.message || 'Participations confirmées avec succès', 'success')
        
        // Update UI locally without page reload
        this.updateParticipationStatuses(selectedIds, 'confirmed')
        this.clearSelections()
      } else {
        throw new Error(result.message || result.error || 'Erreur lors de la confirmation')
      }
    } catch (error) {
      console.error('🎫 Bulk confirm error:', error)
      this.showToast(error.message || 'Erreur de connexion', 'error')
    } finally {
      // Remove loading state
      this.setLoadingState(false, 'confirm')
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

    // Show loading state
    this.setLoadingState(true, 'cancel')

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


      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()

      if (result.status === 'success') {
        this.showToast(result.message || 'Participations annulées avec succès', 'success')
        
        // Update UI locally without page reload
        this.updateParticipationStatuses(selectedIds, 'cancelled')
        this.clearSelections()
      } else {
        throw new Error(result.message || result.error || 'Erreur lors de l\'annulation')
      }
    } catch (error) {
      console.error('🎫 Bulk cancel error:', error)
      this.showToast(error.message || 'Erreur de connexion', 'error')
    } finally {
      // Remove loading state
      this.setLoadingState(false, 'cancel')
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
    // Dispatch global event for unified flash controller
    const event = new CustomEvent('admin-dashboard:toast', {
      detail: { message, type }
    })
    document.dispatchEvent(event)
  }

  updateParticipationStatuses(participationIds, newStatus) {
    participationIds.forEach(id => {
      const checkbox = document.querySelector(`[data-participation-id="${id}"]`)
      if (checkbox) {
        const row = checkbox.closest('tr')
        if (row) {
          // Find status cell (8th column)
          const statusCell = row.children[7] // 0-indexed, so 8th column is index 7
          if (statusCell) {
            let iconClass = ''
            let colorClass = ''
            
            switch (newStatus) {
              case 'confirmed':
                iconClass = 'fas fa-check'
                colorClass = 'bg-green-500/20 text-green-300'
                break
              case 'cancelled':
                iconClass = 'fas fa-times'
                colorClass = 'bg-red-500/20 text-red-300'
                break
              case 'pending':
                iconClass = 'fas fa-clock'
                colorClass = 'bg-yellow-500/20 text-yellow-300'
                break
            }
            
            const statusHtml = `<span class="px-1 py-0.5 ${colorClass} rounded text-xs">
              <i class="${iconClass}"></i>
            </span>`
            
            statusCell.innerHTML = statusHtml
            
            // Add visual feedback with animation
            statusCell.classList.add('animate-pulse')
            setTimeout(() => {
              statusCell.classList.remove('animate-pulse')
            }, 1000)
          }
        }
      }
    })
  }

  // Handle single participation status update
  async updateSingleStatus(event) {
    const button = event.currentTarget
    const participationId = button.dataset.participationId
    const newStatus = button.dataset.newStatus
    const confirmMessage = button.dataset.confirmMessage

    if (!confirm(confirmMessage)) {
      return
    }

    // Show loading on button
    const originalHtml = button.innerHTML
    button.disabled = true
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'

    try {
      const response = await fetch(`/admin/participations/${participationId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          status: newStatus
        })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()

      if (result.status === 'success') {
        this.showToast(result.message || 'Statut mis à jour', 'success')
        // Update UI locally
        this.updateParticipationStatuses([participationId], newStatus)
      } else {
        throw new Error(result.message || 'Erreur lors de la mise à jour')
      }
    } catch (error) {
      console.error('Single status update error:', error)
      this.showToast(error.message || 'Erreur de connexion', 'error')
    } finally {
      // Reset button
      button.disabled = false
      button.innerHTML = originalHtml
    }
  }

  setLoadingState(isLoading, action) {
    const bulkActionsDiv = document.getElementById('bulk-actions')
    const confirmBtn = bulkActionsDiv?.querySelector('[data-action*="bulkConfirm"]')
    const cancelBtn = bulkActionsDiv?.querySelector('[data-action*="bulkCancel"]')
    
    if (isLoading) {
      if (action === 'confirm' && confirmBtn) {
        confirmBtn.disabled = true
        confirmBtn.innerHTML = `
          <i class="fas fa-spinner fa-spin mr-2"></i>
          Confirmation...
        `
      } else if (action === 'cancel' && cancelBtn) {
        cancelBtn.disabled = true
        cancelBtn.innerHTML = `
          <i class="fas fa-spinner fa-spin mr-2"></i>
          Annulation...
        `
      }
    } else {
      // Reset buttons to normal state
      const checkedBoxes = this.participationCheckboxTargets.filter(cb => cb.checked)
      
      if (confirmBtn) {
        confirmBtn.disabled = false
        confirmBtn.innerHTML = `
          <i class="fas fa-check mr-2"></i>
          Confirmer (${checkedBoxes.length})
        `
      }
      
      if (cancelBtn) {
        cancelBtn.disabled = false
        cancelBtn.innerHTML = `
          <i class="fas fa-times mr-2"></i>
          Annuler (${checkedBoxes.length})
        `
      }
    }
  }

  clearSelections() {
    // Uncheck all checkboxes
    this.participationCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    
    // Update select all checkbox
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    }
    
    // Hide bulk actions
    this.updateBulkActions()
  }
}