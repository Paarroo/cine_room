import { Controller } from "@hotwired/stimulus"

// Admin Chart Controller - Handles chart rendering and updates for dashboard
export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: { type: Object, default: {} }
  }

  // Lifecycle
  connect() {
    console.log("📊 Admin Chart connected:", this.typeValue)
    this.initializeChart()
  }

  disconnect() {
    this.destroyChart()
  }

  // Chart initialization
  initializeChart() {
    // For now, create a placeholder chart visualization
    // In a real implementation, you'd use Chart.js, D3.js, or similar
    this.createPlaceholderChart()
  }

  // Create placeholder chart visualization
  createPlaceholderChart() {
    const chartContainer = this.element
    chartContainer.innerHTML = '' // Clear existing content

    switch (this.typeValue) {
      case 'line':
        this.createLineChart()
        break
      case 'doughnut':
        this.createDoughnutChart()
        break
      case 'bar':
        this.createBarChart()
        break
      default:
        this.createDefaultChart()
    }
  }

  createLineChart() {
    const data = this.dataValue || []
    const maxRevenue = Math.max(...data.map(d => d.revenue || 0))

    this.element.innerHTML = `
      <div class="chart-line-placeholder w-full h-full flex flex-col">
        <div class="chart-header mb-4">
          <div class="flex justify-between text-sm text-muted">
            <span>€0</span>
            <span>€${maxRevenue.toFixed(0)}</span>
          </div>
        </div>

        <div class="chart-body flex-1 relative">
          <svg class="w-full h-full" viewBox="0 0 400 200">
            <!-- Grid lines -->
            <defs>
              <pattern id="grid" width="40" height="20" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 20" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid)" />

            <!-- Revenue line -->
            <polyline
              fill="none"
              stroke="url(#gradient)"
              stroke-width="3"
              points="${this.generateLinePoints(data)}"
            />

            <!-- Gradient definition -->
            <defs>
              <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" style="stop-color:#f59e0b;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#2563eb;stop-opacity:1" />
              </linearGradient>
            </defs>

            <!-- Data points -->
            ${data.map((point, index) => {
              const x = (index / (data.length - 1)) * 380 + 10
              const y = 180 - ((point.revenue || 0) / maxRevenue) * 160
              return `<circle cx="${x}" cy="${y}" r="4" fill="#f59e0b" class="chart-point"/>`
            }).join('')}
          </svg>

          <!-- Hover tooltip (hidden by default) -->
          <div class="chart-tooltip absolute bg-surface border border-white/20 rounded-lg p-2 text-xs hidden">
            <div class="tooltip-content"></div>
          </div>
        </div>

        <div class="chart-footer mt-4">
          <div class="flex justify-between text-xs text-muted">
            ${data.slice(0, 5).map(d => `<span>${d.date || ''}</span>`).join('')}
            <span>...</span>
            ${data.slice(-2).map(d => `<span>${d.date || ''}</span>`).join('')}
          </div>
        </div>
      </div>
    `

    this.addLineChartInteractivity()
  }
