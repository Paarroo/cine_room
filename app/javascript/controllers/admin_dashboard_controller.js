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
