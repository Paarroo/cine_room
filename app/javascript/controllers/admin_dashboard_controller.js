import { Controller } from "@hotwired/stimulus"

// Admin Dashboard Controller - Manages dashboard functionality and real-time updates
export default class extends Controller {
  static targets = [
    "metrics",
    "revenueChart",
    "eventsChart",
    "quickActions",
    "recentActivity",
    "refreshButton",
    "lastUpdated"
  ]

  static values = {
    refreshInterval: { type: Number, default: 30000 },
    autoRefresh: { type: Boolean, default: true },
    lastUpdate: { type: String, default: "" }
  }

  // Lifecycle
  connect() {
    console.log("📊 Admin Dashboard connected")
    this.setupAutoRefresh()
    this.setupRealtimeUpdates()
    this.initializeCharts()
    this.setupKeyboardShortcuts()
    this.updateLastRefreshTime()
  }

  disconnect() {
    this.teardownAutoRefresh()
    this.teardownRealtimeUpdates()
  }

  // Auto Refresh Setup
  setupAutoRefresh() {
    if (!this.autoRefreshValue) return

    this.refreshTimer = setInterval(() => {
      this.refreshDashboard()
    }, this.refreshIntervalValue)
  }

  teardownAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  // Manual Refresh
  async refreshDashboard() {
    this.showRefreshIndicator()

    try {
      const response = await fetch('/admin/dashboard/refresh', {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        // Turbo Stream will handle the updates
        this.updateLastRefreshTime()
        this.showToast('Dashboard mis à jour', 'success')
      } else {
        throw new Error('Refresh failed')
      }
    } catch (error) {
      console.error('Dashboard refresh failed:', error)
      this.showToast('Erreur lors de la mise à jour', 'error')
    } finally {
      this.hideRefreshIndicator()
    }
  }

  // Refresh Indicators
  showRefreshIndicator() {
    if (this.hasRefreshButtonTarget) {
      const icon = this.refreshButtonTarget.querySelector('i')
      if (icon) {
        icon.classList.add('fa-spin')
      }
    }

    // Add subtle loading state to metrics
    this.metricsTarget.classList.add('refreshing')
  }

  hideRefreshIndicator() {
    if (this.hasRefreshButtonTarget) {
      const icon = this.refreshButtonTarget.querySelector('i')
      if (icon) {
        icon.classList.remove('fa-spin')
      }
    }

    this.metricsTarget.classList.remove('refreshing')
  }

  updateLastRefreshTime() {
    const now = new Date()
    this.lastUpdateValue = now.toISOString()

    if (this.hasLastUpdatedTarget) {
      this.lastUpdatedTarget.textContent = `Dernière mise à jour: ${now.toLocaleTimeString('fr-FR')}`
    }
  }

  // Charts Initialization
  initializeCharts() {
    // Charts are handled by separate chart controllers
    // This method coordinates their initialization
    this.dispatchChartEvent('initialize-charts')
  }

  dispatchChartEvent(eventName, data = {}) {
    this.dispatch(eventName, { detail: data })
  }

  // Real-time Updates
  setupRealtimeUpdates() {
    // Listen for WebSocket/ActionCable updates
    document.addEventListener('admin:realtime-update', this.handleRealtimeUpdate.bind(this))
  }

  teardownRealtimeUpdates() {
    document.removeEventListener('admin:realtime-update', this.handleRealtimeUpdate.bind(this))
  }

  handleRealtimeUpdate(event) {
    const { type, data } = event.detail

    switch (type) {
      case 'new_participation':
        this.updateParticipationMetrics(data)
        this.addRecentActivity('participation', data)
        break

      case 'movie_validation':
        this.updateMovieMetrics(data)
        this.addRecentActivity('movie', data)
        break

      case 'user_registration':
        this.updateUserMetrics(data)
        this.addRecentActivity('user', data)
        break

      case 'revenue_update':
        this.updateRevenueMetrics(data)
        this.refreshChart('revenue')
        break
    }
  }

  // Metrics Updates
  updateParticipationMetrics(data) {
    const participationCard = this.metricsTarget.querySelector('[data-metric="participations"]')
    if (participationCard) {
      const valueElement = participationCard.querySelector('.metric-value')
      const trendElement = participationCard.querySelector('.metric-trend')

      if (valueElement) {
        const currentValue = parseInt(valueElement.textContent)
        this.animateValueChange(valueElement, currentValue, currentValue + 1)
      }

      if (trendElement) {
        this.highlightTrendUpdate(trendElement)
      }
    }
  }

  updateRevenueMetrics(data) {
    const revenueCard = this.metricsTarget.querySelector('[data-metric="revenue"]')
    if (revenueCard) {
      const valueElement = revenueCard.querySelector('.metric-value')

      if (valueElement && data.newTotal) {
        this.animateValueChange(valueElement, data.oldTotal, data.newTotal, true)
      }
    }
  }

  updateUserMetrics(data) {
    const userCard = this.metricsTarget.querySelector('[data-metric="users"]')
    if (userCard) {
      const valueElement = userCard.querySelector('.metric-value')

      if (valueElement) {
        const currentValue = parseInt(valueElement.textContent)
        this.animateValueChange(valueElement, currentValue, currentValue + 1)
      }
    }
  }

  // Value Animation
  animateValueChange(element, fromValue, toValue, isCurrency = false) {
    const duration = 1000
    const startTime = performance.now()
    const difference = toValue - fromValue

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)

      // Easing function (ease-out)
      const easeOut = 1 - Math.pow(1 - progress, 3)
      const currentValue = fromValue + (difference * easeOut)

      if (isCurrency) {
        element.textContent = new Intl.NumberFormat('fr-FR', {
          style: 'currency',
          currency: 'EUR'
        }).format(currentValue)
      } else {
        element.textContent = Math.round(currentValue)
      }

      if (progress < 1) {
        requestAnimationFrame(animate)
      }
    }

    requestAnimationFrame(animate)

    // Add highlight effect
    element.classList.add('value-updated')
    setTimeout(() => {
      element.classList.remove('value-updated')
    }, 1500)
  }

  highlightTrendUpdate(element) {
    element.classList.add('trend-updated')
    setTimeout(() => {
      element.classList.remove('trend-updated')
    }, 2000)
  }

  // Recent Activity Management
  addRecentActivity(type, data) {
    if (!this.hasRecentActivityTarget) return

    const activityList = this.recentActivityTarget.querySelector('.activity-list')
    if (!activityList) return

    const activityItem = this.createActivityItem(type, data)

    // Add to top of list
    activityList.insertAdjacentHTML('afterbegin', activityItem)

    // Remove oldest item if more than 10
    const items = activityList.querySelectorAll('.activity-item')
    if (items.length > 10) {
      items[items.length - 1].remove()
    }

    // Animate new item
    const newItem = activityList.firstElementChild
    newItem.style.animation = 'slideInFromRight 0.5s ease-out'
  }

  createActivityItem(type, data) {
    const icons = {
      participation: 'fas fa-ticket-alt text-primary',
      movie: 'fas fa-film text-accent',
      user: 'fas fa-user-plus text-success'
    }

    const descriptions = {
      participation: `Nouvelle participation pour "${data.event_title}"`,
      movie: `Film "${data.movie_title}" ${data.status}`,
      user: `Nouvel utilisateur: ${data.user_name}`
    }

    const now = new Date().toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit'
    })

    return `
      <div class="activity-item flex items-center space-x-3 p-3 hover:bg-white/5 rounded-xl transition-colors">
        <div class="activity-icon w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center">
          <i class="${icons[type]} text-sm"></i>
        </div>

        <div class="activity-content flex-1 min-w-0">
          <div class="activity-description text-sm text-content">
            ${descriptions[type]}
          </div>
          <div class="activity-time text-xs text-muted">
            ${now}
          </div>
        </div>

        <div class="activity-actions">
          <button
            class="w-6 h-6 rounded-lg hover:bg-white/10 flex items-center justify-center transition-colors"
            data-action="click->admin-dashboard#viewActivityDetail"
            data-activity-type="${type}"
            data-activity-id="${data.id || ''}"
          >
            <i class="fas fa-external-link-alt text-xs text-muted"></i>
          </button>
        </div>
      </div>
    `
  }

  // Chart Management
  refreshChart(chartType) {
    const chartTargets = {
      revenue: this.revenueChartTarget,
      events: this.eventsChartTarget
    }

    const target = chartTargets[chartType]
    if (!target) return

    // Get chart controller and refresh
    const chartController = this.application.getControllerForElementAndIdentifier(target, 'admin-chart')
    if (chartController) {
      chartController.refreshData()
    }
  }

  // Quick Actions
  handleQuickAction(event) {
    const action = event.currentTarget.dataset.action
    const actionData = event.currentTarget.dataset

    switch (action) {
      case 'export-data':
        this.exportData(actionData.type)
        break

      case 'validate-movies':
        this.bulkValidateMovies()
        break

      case 'send-notifications':
        this.sendBulkNotifications()
        break

      case 'backup-database':
        this.initiateBackup()
        break

      default:
        console.warn(`Unknown quick action: ${action}`)
    }
  }

  async exportData(type) {
    this.showToast(`Export ${type} en cours...`, 'info')

    try {
      const response = await fetch(`/admin/export/${type}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const blob = await response.blob()
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `cineroom_${type}_${new Date().toISOString().split('T')[0]}.csv`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        window.URL.revokeObjectURL(url)

        this.showToast('Export terminé avec succès', 'success')
      } else {
        throw new Error('Export failed')
      }
    } catch (error) {
      console.error('Export error:', error)
      this.showToast('Erreur lors de l\'export', 'error')
    }
  }

  async bulkValidateMovies() {
    const pendingCount = document.querySelectorAll('[data-movie-status="pending"]').length

    if (pendingCount === 0) {
      this.showToast('Aucun film en attente de validation', 'info')
      return
    }

    if (!confirm(`Valider tous les ${pendingCount} films en attente ?`)) {
      return
    }

    try {
      const response = await fetch('/admin/movies/bulk_validate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        this.showToast(`${pendingCount} films validés avec succès`, 'success')
        this.refreshDashboard()
      } else {
        throw new Error('Bulk validation failed')
      }
    } catch (error) {
      console.error('Bulk validation error:', error)
      this.showToast('Erreur lors de la validation', 'error')
    }
  }

  async sendBulkNotifications() {
    const notificationModal = document.getElementById('notification-modal')
    if (notificationModal) {
      // Open notification modal (handled by admin controller)
      this.dispatch('open-modal', { detail: { modalId: 'notification-modal' } })
    }
  }

  async initiateBackup() {
    if (!confirm('Lancer une sauvegarde complète de la base de données ?')) {
      return
    }

    this.showToast('Sauvegarde en cours...', 'info')

    try {
      const response = await fetch('/admin/backup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const result = await response.json()
        this.showToast('Sauvegarde terminée avec succès', 'success')
      } else {
        throw new Error('Backup failed')
      }
    } catch (error) {
      console.error('Backup error:', error)
      this.showToast('Erreur lors de la sauvegarde', 'error')
    }
  }

  // Activity Detail View
  viewActivityDetail(event) {
    const type = event.currentTarget.dataset.activityType
    const id = event.currentTarget.dataset.activityId

    if (!id) return

    const routes = {
      participation: `/admin/participations/${id}`,
      movie: `/admin/movies/${id}`,
      user: `/admin/users/${id}`
    }

    const url = routes[type]
    if (url) {
      // Open in new tab with Ctrl/Cmd click, otherwise navigate
      if (event.ctrlKey || event.metaKey) {
        window.open(url, '_blank')
      } else {
        window.location.href = url
      }
    }
  }

  // Keyboard Shortcuts
  setupKeyboardShortcuts() {
    this.keyboardHandler = this.handleKeyboard.bind(this)
    document.addEventListener('keydown', this.keyboardHandler)
  }

  handleKeyboard(event) {
    // Only handle when dashboard is focused
    if (!this.element.contains(document.activeElement)) return

    // R - Refresh dashboard
    if (event.key === 'r' || event.key === 'R') {
      if (!event.ctrlKey && !event.metaKey) {
        event.preventDefault()
        this.refreshDashboard()
      }
    }

    // E - Export data
    if (event.key === 'e' || event.key === 'E') {
      if (event.ctrlKey || event.metaKey) {
        event.preventDefault()
        this.exportData('all')
      }
    }
  }

  // Auto-refresh Toggle
  toggleAutoRefresh() {
    this.autoRefreshValue = !this.autoRefreshValue

    if (this.autoRefreshValue) {
      this.setupAutoRefresh()
      this.showToast('Actualisation automatique activée', 'success')
    } else {
      this.teardownAutoRefresh()
      this.showToast('Actualisation automatique désactivée', 'info')
    }

    // Update toggle button state
    const toggleButton = this.element.querySelector('[data-action*="toggleAutoRefresh"]')
    if (toggleButton) {
      const icon = toggleButton.querySelector('i')
      if (icon) {
        icon.classList.toggle('text-primary', this.autoRefreshValue)
        icon.classList.toggle('text-muted', !this.autoRefreshValue)
      }
    }
  }

  // Data Filtering
  filterMetrics(event) {
    const period = event.currentTarget.dataset.period
    const filterButtons = this.element.querySelectorAll('[data-period]')

    // Update active button
    filterButtons.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.period === period)
    })

    // Fetch filtered data
    this.fetchFilteredData(period)
  }

  async fetchFilteredData(period) {
    try {
      const response = await fetch(`/admin/dashboard/filter?period=${period}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.updateMetricsWithFilteredData(data)
        this.updateChartsWithFilteredData(data)
      }
    } catch (error) {
      console.error('Filter error:', error)
      this.showToast('Erreur lors du filtrage', 'error')
    }
  }

  updateMetricsWithFilteredData(data) {
    // Update each metric card with filtered data
    Object.entries(data.metrics).forEach(([key, value]) => {
      const card = this.metricsTarget.querySelector(`[data-metric="${key}"]`)
      if (card) {
        const valueElement = card.querySelector('.metric-value')
        const trendElement = card.querySelector('.metric-trend')

        if (valueElement) {
          valueElement.textContent = value.value
        }

        if (trendElement && value.trend) {
          trendElement.textContent = value.trend
          trendElement.className = `metric-trend ${value.trend_type}`
        }
      }
    })
  }
