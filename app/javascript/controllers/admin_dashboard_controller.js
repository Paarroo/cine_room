import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "revenueChart",
    "eventsChart",
    "refreshButton",
    "lastUpdated",
    "metrics"
  ]

  static values = {
    refreshInterval: { type: Number, default: 30000 },
    autoRefresh: { type: Boolean, default: true }
  }

  // Lifecycle hooks
  connect() {
    this.initializeDashboard()
    this.setupAutoRefresh()
    this.setupKeyboardShortcuts()
    this.animateMetrics()
  }

  disconnect() {
    this.teardownAutoRefresh()
    this.removeKeyboardListeners()
  }

  // Dashboard initialization
  initializeDashboard() {
    this.updateLastRefreshTime()
    this.initializeCharts()
  }

  // Auto-refresh functionality
  setupAutoRefresh() {
    if (!this.autoRefreshValue) return

    this.refreshInterval = setInterval(() => {
      this.refreshDashboard()
    }, this.refreshIntervalValue)
  }

  teardownAutoRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  // Manual refresh dashboard
  async refreshDashboard() {
    if (!this.hasRefreshButtonTarget) return

    const button = this.refreshButtonTarget
    const originalText = button.innerHTML
    const performance = this.trackPerformance('dashboard_refresh')

    // Show loading state
    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Actualisation...'
    button.disabled = true

    try {
      const response = await fetch('/admin/dashboard/refresh', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateDashboardData(data)
        this.showToast('Dashboard actualisé avec succès', 'success')
      } else {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
    } catch (error) {
      console.error('Dashboard refresh failed:', error)
      this.showToast('Erreur lors de l\'actualisation', 'error')
      this.handleError(error, 'Dashboard Refresh')
    } finally {
      // Restore button state
      button.innerHTML = originalText
      button.disabled = false
      this.updateLastRefreshTime()
      performance.end()
    }
  }

  // Update dashboard with fresh data
  updateDashboardData(data) {
    // Update metrics
    this.updateMetrics(data.metrics)

    // Update charts
    this.updateCharts(data.charts)

    // Update activity feed
    this.updateRecentActivity(data.activities)

    // Animate updated elements
    this.animateUpdatedElements()
  }

  // Metrics update with smooth animations
  updateMetrics(metrics) {
    if (!metrics) return

    // Update revenue metric
    const revenueElement = document.querySelector('[data-metric="revenue"]')
    if (revenueElement && metrics.total_revenue !== undefined) {
      this.animateValueChange(revenueElement, this.formatCurrency(metrics.total_revenue))
    }

    // Update events metric
    const eventsElement = document.querySelector('[data-metric="events"]')
    if (eventsElement && metrics.upcoming_events !== undefined) {
      this.animateValueChange(eventsElement, metrics.upcoming_events.toString())
    }

    // Update users metric
    const usersElement = document.querySelector('[data-metric="users"]')
    if (usersElement && metrics.total_users !== undefined) {
      this.animateValueChange(usersElement, metrics.total_users.toString())
    }

    // Update satisfaction metric
    const satisfactionElement = document.querySelector('[data-metric="satisfaction"]')
    if (satisfactionElement && metrics.satisfaction !== undefined) {
      this.animateValueChange(satisfactionElement, `${metrics.satisfaction}/5`)
    }
  }

  // Animate value changes with smooth transitions
  animateValueChange(element, newValue) {
    element.classList.add('value-updating')

    // Fade out
    element.style.opacity = '0.5'
    element.style.transform = 'scale(0.95)'

    setTimeout(() => {
      element.textContent = newValue
      element.style.opacity = '1'
      element.style.transform = 'scale(1)'
      element.classList.remove('value-updating')
      element.classList.add('value-updated')

      // Remove updated class after animation
      setTimeout(() => {
        element.classList.remove('value-updated')
      }, 1000)
    }, 200)
  }

  // Charts management
  initializeCharts() {
    if (this.hasRevenueChartTarget) {
      this.initializeChart(this.revenueChartTarget, 'admin-chart')
    }

    if (this.hasEventsChartTarget) {
      this.initializeChart(this.eventsChartTarget, 'admin-chart')
    }
  }

  initializeChart(chartElement, controllerName) {
    const chartController = this.application.getControllerForElementAndIdentifier(
      chartElement,
      controllerName
    )

    if (chartController) {
      chartController.refreshData()
    }
  }

  updateCharts(chartData) {
    if (!chartData) return

    // Update revenue chart
    if (chartData.revenue && this.hasRevenueChartTarget) {
      this.updateChart(this.revenueChartTarget, chartData.revenue)
    }

    // Update events chart
    if (chartData.events && this.hasEventsChartTarget) {
      this.updateChart(this.eventsChartTarget, chartData.events)
    }
  }

  updateChart(chartElement, newData) {
    const chartController = this.application.getControllerForElementAndIdentifier(
      chartElement,
      'admin-chart'
    )

    if (chartController) {
      chartController.updateData(newData)
    }
  }

  // Export functionality
  async exportData(event) {
    const button = event.currentTarget
    const dataType = button.dataset.type
    const originalText = button.innerHTML
    const performance = this.trackPerformance('export_data')

    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Export...'
    button.disabled = true

    try {
      const response = await fetch(`/admin/exports?type=${dataType}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (response.ok) {
        const result = await response.json()
        this.showToast(`Export ${dataType} terminé avec succès`, 'success')
        this.triggerDownload(result.filename, result.data)
      } else {
        throw new Error(`HTTP ${response.status}`)
      }

    } catch (error) {
      console.error('Export failed:', error)
      this.showToast('Erreur lors de l\'export', 'error')
      this.handleError(error, 'Data Export')
    } finally {
      button.innerHTML = originalText
      button.disabled = false
      performance.end()
    }
  }

  async backupDatabase() {
    if (!confirm('Lancer une sauvegarde de la base de données ?')) {
      return
    }

    const performance = this.trackPerformance('database_backup')
    this.showToast('💾 Sauvegarde en cours...', 'info')

    try {
      const response = await fetch('/admin/dashboard/backup', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (response.ok) {
        const result = await response.json()
        this.showToast('✅ Sauvegarde terminée avec succès !', 'success')
      } else {
        throw new Error(`HTTP ${response.status}`)
      }
    } catch (error) {
      console.error('Backup failed:', error)
      this.showToast('Erreur lors de la sauvegarde', 'error')
      this.handleError(error, 'Database Backup')
    } finally {
      performance.end()
    }
  }

  async toggleMaintenanceMode() {
    if (!confirm('Basculer le mode maintenance ?')) {
      return
    }

    this.showToast('🔧 Basculement du mode maintenance...', 'info')

    try {
      // Implementation would depend on your maintenance mode setup
      await this.simulateMaintenanceToggle()
      this.showToast('Mode maintenance basculé', 'success')
    } catch (error) {
      this.showToast('Erreur lors du basculement', 'error')
      this.handleError(error, 'Maintenance Mode')
    }
  }

  // Keyboard shortcuts
  setupKeyboardShortcuts() {
    this.keyboardHandler = this.handleKeyboardShortcut.bind(this)
    document.addEventListener('keydown', this.keyboardHandler)
  }

  removeKeyboardListeners() {
    if (this.keyboardHandler) {
      document.removeEventListener('keydown', this.keyboardHandler)
    }
  }

  handleKeyboardShortcut(event) {
    // Only handle shortcuts when not in input fields
    if (this.isInputFocused()) return

    // Ctrl+R - Refresh dashboard
    if (event.ctrlKey && event.key === 'r') {
      event.preventDefault()
      this.refreshDashboard()
    }

    // Ctrl+E - Export data
    if (event.ctrlKey && event.key === 'e') {
      event.preventDefault()
      this.exportData({ currentTarget: { dataset: { type: 'users' } } })
    }

    // Ctrl+B - Backup database
    if (event.ctrlKey && event.key === 'b') {
      event.preventDefault()
      this.backupDatabase()
    }
  }

  // Animation helpers
  animateMetrics() {
    const metricCards = document.querySelectorAll('.metric-card')
    metricCards.forEach((card, index) => {
      setTimeout(() => {
        card.style.animation = 'fadeInUp 0.6s ease-out'
      }, index * 100)
    })
  }

  animateUpdatedElements() {
    const updatedElements = document.querySelectorAll('.value-updated, .chart-updated')
    updatedElements.forEach(element => {
      element.style.animation = 'pulse 1s ease-out'
    })
  }

  // Time management
  updateLastRefreshTime() {
    if (this.hasLastUpdatedTarget) {
      const now = new Date()
      const timeString = now.toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })

      this.lastUpdatedTarget.textContent = timeString
    }
  }

  // Utility methods
  async simulateExport(dataType) {
    // Simulate API call delay
    return new Promise(resolve => {
      setTimeout(() => {
        resolve()
      }, 2000)
    })
  }

  async simulateBackup() {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve()
      }, 3000)
    })
  }

  async simulateMaintenanceToggle() {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve()
      }, 1000)
    })
  }

  triggerDownload(filename, data) {
    // Create actual CSV content
    const csvContent = this.formatDataAsCSV(data)
    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)

    const link = document.createElement('a')
    link.style.display = 'none'
    link.href = url
    link.download = filename

    document.body.appendChild(link)
    link.click()

    window.URL.revokeObjectURL(url)
    document.body.removeChild(link)
  }

  formatDataAsCSV(data) {
    if (!data || data.length === 0) return ''

    const headers = Object.keys(data[0])
    const csvRows = [
      headers.join(','),
      ...data.map(row =>
        headers.map(header =>
          `"${String(row[header] || '').replace(/"/g, '""')}"`
        ).join(',')
      )
    ]

    return csvRows.join('\n')
  }

  // Toast notifications
  showToast(message, type = 'info') {
    this.dispatch('toast', {
      detail: { message, type }
    })
  }

  // Performance monitoring
  trackPerformance(action) {
    const startTime = performance.now()

    return {
      end: () => {
        const endTime = performance.now()
        const duration = endTime - startTime

        // Log slow operations
        if (duration > 1000) {
          console.warn(`Slow dashboard operation detected: ${action} (${duration.toFixed(2)}ms)`)
        }
      }
    }
  }

  // Error handling
  handleError(error, context = 'Dashboard') {
    console.error(`${context} error:`, error)

    // Track error for monitoring (in production, send to error tracking service)
    if (window.trackError) {
      window.trackError(error, {
        context,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent
      })
    }
  }

  // Helper methods
  getCSRFToken() {
    const token = document.querySelector('[name="csrf-token"]')
    return token ? token.content : ''
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  isInputFocused() {
    const activeElement = document.activeElement
    return activeElement && (
      activeElement.tagName === 'INPUT' ||
      activeElement.tagName === 'TEXTAREA' ||
      activeElement.contentEditable === 'true'
    )
  }
}
