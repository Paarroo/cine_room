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

  createDoughnutChart() {
    const data = this.dataValue || []
    const total = data.reduce((sum, item) => sum + (item.count || 0), 0)

    let cumulativeAngle = 0
    const radius = 80
    const centerX = 100
    const centerY = 100

    const segments = data.map((item, index) => {
      const angle = (item.count / total) * 360
      const startAngle = cumulativeAngle
      const endAngle = cumulativeAngle + angle

      // Calculate arc path
      const startAngleRad = (startAngle - 90) * Math.PI / 180
      const endAngleRad = (endAngle - 90) * Math.PI / 180

      const x1 = centerX + radius * Math.cos(startAngleRad)
      const y1 = centerY + radius * Math.sin(startAngleRad)
      const x2 = centerX + radius * Math.cos(endAngleRad)
      const y2 = centerY + radius * Math.sin(endAngleRad)

      const largeArcFlag = angle > 180 ? 1 : 0

      const pathData = [
        `M ${centerX} ${centerY}`,
        `L ${x1} ${y1}`,
        `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2}`,
        'Z'
      ].join(' ')

      cumulativeAngle += angle

      return {
        path: pathData,
        color: item.color || this.getSegmentColor(index),
        label: item.status,
        count: item.count,
        percentage: item.percentage
      }
    })

    this.element.innerHTML = `
      <div class="chart-doughnut-placeholder w-full h-full flex items-center">
        <div class="chart-container flex-1">
          <svg class="w-full max-w-xs mx-auto" viewBox="0 0 200 200">
            ${segments.map(segment => `
              <path
                d="${segment.path}"
                fill="${segment.color}"
                stroke="rgba(0,0,0,0.1)"
                stroke-width="2"
                class="chart-segment cursor-pointer hover:opacity-80 transition-opacity"
                data-label="${segment.label}"
                data-count="${segment.count}"
                data-percentage="${segment.percentage}"
              />
            `).join('')}

            <!-- Center hole -->
            <circle cx="100" cy="100" r="50" fill="#0a0a0a"/>

            <!-- Center text -->
            <text x="100" y="95" text-anchor="middle" class="fill-content text-lg font-bold">
              ${total}
            </text>
            <text x="100" y="110" text-anchor="middle" class="fill-muted text-xs">
              Total
            </text>
          </svg>
        </div>

        <div class="chart-legend ml-6 space-y-2">
          ${segments.map(segment => `
            <div class="legend-item flex items-center space-x-2">
              <div class="w-3 h-3 rounded-full" style="background-color: ${segment.color}"></div>
              <span class="text-sm text-content">${segment.label}</span>
              <span class="text-xs text-muted">(${segment.count})</span>
            </div>
          `).join('')}
        </div>
      </div>
    `

    this.addDoughnutChartInteractivity()
  }

  createBarChart() {
    const data = this.dataValue || []
    const maxValue = Math.max(...data.map(d => d.value || 0))

    this.element.innerHTML = `
      <div class="chart-bar-placeholder w-full h-full">
        <svg class="w-full h-full" viewBox="0 0 400 200">
          <!-- Grid lines -->
          <defs>
            <pattern id="barGrid" width="40" height="20" patternUnits="userSpaceOnUse">
              <path d="M 0 20 L 400 20" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#barGrid)" />

          <!-- Bars -->
          ${data.map((item, index) => {
            const barWidth = 300 / data.length - 10
            const barHeight = (item.value / maxValue) * 160
            const x = 50 + index * (300 / data.length)
            const y = 180 - barHeight

            return `
              <rect
                x="${x}"
                y="${y}"
                width="${barWidth}"
                height="${barHeight}"
                fill="url(#barGradient)"
                class="chart-bar cursor-pointer hover:opacity-80 transition-opacity"
                data-label="${item.label}"
                data-value="${item.value}"
              />
            `
          }).join('')}

          <defs>
            <linearGradient id="barGradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" style="stop-color:#f59e0b;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#2563eb;stop-opacity:1" />
            </linearGradient>
          </defs>
        </svg>
      </div>
    `
  }
