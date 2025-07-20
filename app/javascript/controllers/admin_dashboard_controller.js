import { Controller } from "@hotwired/stimulus"

// Admin Dashboard Controller - Handles dashboard functionality and real-time updates
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

  // Lifecycle
  connect() {
    console.log("📊 Admin Dashboard connected")
    this.initializeDashboard()
    this.setupAutoRefresh()
    this.setupRealTimeUpdates()
    this.animateMetrics()
  }

  disconnect() {
    this.teardownAutoRefresh()
  }

  // Dashboard initialization
  initializeDashboard() {
    this.updateLastRefreshTime()
    this.initializeCharts()
    this.setupKeyboardShortcuts()
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

    // Show loading state
    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Actualisation...'
    button.disabled = true

    try {
      // Fetch fresh dashboard data
      const response = await fetch('/admin/dashboard/refresh', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateDashboardData(data)
        this.showToast('Dashboard actualisé avec succès', 'success')
      } else {
        throw new Error('Failed to refresh dashboard')
      }
    } catch (error) {
      console.error('Dashboard refresh failed:', error)
      this.showToast('Erreur lors de l\'actualisation', 'error')
    } finally {
      // Restore button state
      button.innerHTML = originalText
      button.disabled = false
      this.updateLastRefreshTime()
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

  // Metrics update
  updateMetrics(metrics) {
    if (!metrics) return

    // Update revenue metric
    const revenueElement = document.querySelector('[data-metric="revenue"] .metric-value')
    if (revenueElement && metrics.revenue) {
      this.animateValueChange(revenueElement, metrics.revenue.total)
    }

    // Update events metric
    const eventsElement = document.querySelector('[data-metric="events"] .metric-value')
    if (eventsElement && metrics.events) {
      this.animateValueChange(eventsElement, metrics.events.upcoming)
    }

    // Update users metric
    const usersElement = document.querySelector('[data-metric="users"] .metric-value')
    if (usersElement && metrics.users) {
      this.animateValueChange(usersElement, metrics.users.total)
    }

    // Update satisfaction metric
    const satisfactionElement = document.querySelector('[data-metric="satisfaction"] .metric-value')
    if (satisfactionElement && metrics.satisfaction) {
      this.animateValueChange(satisfactionElement, `${metrics.satisfaction.average}/5`)
    }
  }

  // Animate value changes
  animateValueChange(element, newValue) {
    element.classList.add('value-updating')

    setTimeout(() => {
      element.textContent = newValue
      element.classList.remove('value-updating')
      element.classList.add('value-updated')

      setTimeout(() => {
        element.classList.remove('value-updated')
      }, 1000)
    }, 200)
  }

  // Charts management
  initializeCharts() {
    if (this.hasRevenueChartTarget) {
      this.initializeRevenueChart()
    }

    if (this.hasEventsChartTarget) {
      this.initializeEventsChart()
    }
  }

  initializeRevenueChart() {
    // Revenue chart is handled by admin-chart controller
    // We just ensure it's properly initialized
    const chartController = this.application.getControllerForElementAndIdentifier(
      this.revenueChartTarget,
      'admin-chart'
    )

    if (chartController) {
      chartController.refreshData()
    }
  }

  initializeEventsChart() {
    // Events chart is handled by admin-chart controller
    const chartController = this.application.getControllerForElementAndIdentifier(
      this.eventsChartTarget,
      'admin-chart'
    )

    if (chartController) {
      chartController.refreshData()
    }
  }

  updateCharts(chartData) {
    if (!chartData) return

    // Update revenue chart
    if (chartData.revenue && this.hasRevenueChartTarget) {
      const chartController = this.application.getControllerForElementAndIdentifier(
        this.revenueChartTarget,
        'admin-chart'
      )

      if (chartController) {
        chartController.updateData(chartData.revenue)
      }
    }

    // Update events chart
    if (chartData.events && this.hasEventsChartTarget) {
      const chartController = this.application.getControllerForElementAndIdentifier(
        this.eventsChartTarget,
        'admin-chart'
      )

      if (chartController) {
        chartController.updateData(chartData.events)
      }
    }
  }

  // Recent activity updates
  updateRecentActivity(activities) {
    if (!activities) return

    const activityContainer = document.querySelector('.recent-activity .space-y-4')
    if (!activityContainer) return

    // Create new activity items
    const newActivities = activities.slice(0, 5).map(activity => this.createActivityItem(activity))

    // Animate out old activities and animate in new ones
    this.replaceActivityItems(activityContainer, newActivities)
  }

  createActivityItem(activity) {
    const div = document.createElement('div')
    div.className = 'flex items-center space-x-4 p-3 bg-white/5 rounded-xl activity-item-new'

    div.innerHTML = `
      <div class="w-10 h-10 bg-${activity.color}/20 rounded-xl flex items-center justify-center">
        <i class="fas fa-${activity.icon} text-${activity.color}"></i>
      </div>
      <div class="flex-1">
        <p class="text-sm font-medium text-white">${activity.title}</p>
        <p class="text-xs text-gray-400">${activity.description}</p>
      </div>
      <div class="text-xs text-gray-500">${activity.time_ago}</div>
    `

    return div
  }

  replaceActivityItems(container, newItems) {
    // Fade out existing items
    const existingItems = container.querySelectorAll('.activity-item, .activity-item-new')
    existingItems.forEach((item, index) => {
      setTimeout(() => {
        item.style.transition = 'all 0.3s ease'
        item.style.opacity = '0'
        item.style.transform = 'translateX(-20px)'
      }, index * 50)
    })

    // Remove old items and add new ones
    setTimeout(() => {
      container.innerHTML = ''
      newItems.forEach((item, index) => {
        setTimeout(() => {
          item.style.opacity = '0'
          item.style.transform = 'translateX(20px)'
          container.appendChild(item)

          // Animate in
          setTimeout(() => {
            item.style.transition = 'all 0.3s ease'
            item.style.opacity = '1'
            item.style.transform = 'translateX(0)'
            item.classList.remove('activity-item-new')
            item.classList.add('activity-item')
          }, 50)
        }, index * 100)
      })
    }, 500)
  }

  // Quick actions
  async exportData(event) {
    const button = event.currentTarget
    const dataType = button.dataset.type
    const originalText = button.innerHTML

    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Export...'
    button.disabled = true

    try {
      // Simulate export process
      await this.simulateExport(dataType)

      this.showToast(`Export ${dataType} terminé avec succès`, 'success')

      // Trigger download (in real app, this would be actual file)
      this.triggerDownload(dataType)

    } catch (error) {
      console.error('Export failed:', error)
      this.showToast('Erreur lors de l\'export', 'error')
    } finally {
      button.innerHTML = originalText
      button.disabled = false
    }
  }

  async backupDatabase() {
    if (!confirm('Lancer une sauvegarde de la base de données ?')) {
      return
    }

    this.showToast('💾 Sauvegarde en cours...', 'info')

    try {
      // Simulate backup process
      await this.simulateBackup()
      this.showToast('✅ Sauvegarde terminée avec succès !', 'success')
    } catch (error) {
      console.error('Backup failed:', error)
      this.showToast('Erreur lors de la sauvegarde', 'error')
    }
  }

  // Real-time updates setup
  setupRealTimeUpdates() {
    // In a real app, this would connect to ActionCable or WebSocket
    this.pollForUpdates()
  }

  pollForUpdates() {
    // Poll for notifications every minute
    setInterval(async () => {
      try {
        const response = await fetch('/admin/notifications/poll', {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        })

        if (response.ok) {
          const notifications = await response.json()
          this.processNotifications(notifications)
        }
      } catch (error) {
        console.error('Failed to poll for notifications:', error)
      }
    }, 60000)
  }

  processNotifications(notifications) {
    notifications.forEach(notification => {
      switch (notification.type) {
        case 'new_participation':
          this.handleNewParticipation(notification)
          break
        case 'movie_validation_needed':
          this.handleMovieValidation(notification)
          break
        case 'event_sold_out':
          this.handleEventSoldOut(notification)
          break
      }
    })
  }

  handleNewParticipation(notification) {
    this.showToast(`Nouvelle réservation: ${notification.event_title}`, 'info')
    this.updateMetricValue('participations', '+1')
  }

  handleMovieValidation(notification) {
    this.showToast(`Nouveau film à valider: "${notification.movie_title}"`, 'warning')
    this.updateMetricValue('pending_movies', '+1')
  }

  handleEventSoldOut(notification) {
    this.showToast(`Événement complet: ${notification.event_title}`, 'success')
  }

  // Keyboard shortcuts
  setupKeyboardShortcuts() {
    document.addEventListener('keydown', this.handleKeyboardShortcut.bind(this))
  }

  handleKeyboardShortcut(event) {
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

  updateMetricValue(metricType, change) {
    const metricElement = document.querySelector(`[data-metric="${metricType}"] .metric-value`)
    if (!metricElement) return

    const currentValue = parseInt(metricElement.textContent) || 0
    const changeValue = parseInt(change) || 0
    const newValue = currentValue + changeValue

    this.animateValueChange(metricElement, newValue.toString())
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

      this.lastUpdatedTarget.textContent = `Dernière mise à jour: ${timeString}`
    }
  }

  // Utility methods
  async simulateExport(dataType) {
    // Simulate API call for export
    return new Promise(resolve => {
      setTimeout(() => {
        console.log(`Exporting ${dataType} data...`)
        resolve()
      }, 2000)
    })
  }

  async simulateBackup() {
    // Simulate backup process
    return new Promise(resolve => {
      setTimeout(() => {
        console.log('Database backup completed')
        resolve()
      }, 3000)
    })
  }

  triggerDownload(dataType) {
    // Create a mock download
    const data = `${dataType}_export_${new Date().toISOString().split('T')[0]}.csv`
    const blob = new Blob([`# CinéRoom ${dataType} Export\n# Generated: ${new Date().toISOString()}\n`], {
      type: 'text/csv'
    })

    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.style.display = 'none'
    a.href = url
    a.download = data
    document.body.appendChild(a)
    a.click()
    window.URL.revokeObjectURL(url)
    document.body.removeChild(a)
  }

  // Toast notifications
  showToast(message, type = 'info') {
    // Create toast element
    const toast = document.createElement('div')
    toast.className = `fixed top-20 right-6 z-50 p-4 rounded-xl shadow-lg transform transition-all duration-300 max-w-sm ${this.getToastClasses(type)}`

    toast.innerHTML = `
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0">
          <i class="${this.getToastIcon(type)}"></i>
        </div>
        <div class="flex-1 min-w-0">
          <div class="text-sm font-medium">${message}</div>
        </div>
        <button class="flex-shrink-0 ml-3 p-1 hover:bg-white/10 rounded-lg transition-colors" onclick="this.parentElement.parentElement.remove()">
          <i class="fas fa-times text-xs"></i>
        </button>
      </div>
    `

    // Add to DOM with animation
    document.body.appendChild(toast)

    // Animate in
    setTimeout(() => {
      toast.style.transform = 'translateX(0)'
      toast.style.opacity = '1'
    }, 100)

    // Auto-remove after 5 seconds (unless it's an error)
    if (type !== 'error') {
      setTimeout(() => {
        toast.style.transform = 'translateX(100%)'
        toast.style.opacity = '0'
        setTimeout(() => {
          if (toast.parentNode) {
            toast.remove()
          }
        }, 300)
      }, 5000)
    }
  }

  getToastClasses(type) {
    const baseClasses = 'glass-effect border'

    switch (type) {
      case 'success':
        return `${baseClasses} border-green-500/30 bg-green-500/10 text-green-300`
      case 'error':
        return `${baseClasses} border-red-500/30 bg-red-500/10 text-red-300`
      case 'warning':
        return `${baseClasses} border-yellow-500/30 bg-yellow-500/10 text-yellow-300`
      case 'info':
        return `${baseClasses} border-blue-500/30 bg-blue-500/10 text-blue-300`
      default:
        return `${baseClasses} border-white/20 bg-white/5 text-white`
    }
  }

  getToastIcon(type) {
    const baseClasses = 'fas'

    switch (type) {
      case 'success':
        return `${baseClasses} fa-check-circle text-green-400`
      case 'error':
        return `${baseClasses} fa-exclamation-circle text-red-400`
      case 'warning':
        return `${baseClasses} fa-exclamation-triangle text-yellow-400`
      case 'info':
        return `${baseClasses} fa-info-circle text-blue-400`
      default:
        return `${baseClasses} fa-bell text-white`
    }
  }

  // Performance monitoring
  trackPerformance(action) {
    const startTime = performance.now()

    return {
      end: () => {
        const endTime = performance.now()
        const duration = endTime - startTime
        console.log(`Dashboard action "${action}" took ${duration.toFixed(2)}ms`)

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

    // Show user-friendly error message
    this.showToast(
      'Une erreur est survenue. Veuillez réessayer ou contacter le support.',
      'error'
    )

    // Track error for monitoring (in production, send to error tracking service)
    if (window.trackError) {
      window.trackError(error, { context, timestamp: new Date().toISOString() })
    }
  }

  // Cleanup
  teardown() {
    this.teardownAutoRefresh()

    // Remove event listeners
    document.removeEventListener('keydown', this.handleKeyboardShortcut)

    // Clear any remaining timeouts
    if (this.animationTimeout) {
      clearTimeout(this.animationTimeout)
    }
  }
}
