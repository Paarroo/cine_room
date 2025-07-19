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
