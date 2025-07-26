import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static values = { 
    type: String, 
    data: Array 
  }
  
  static targets = ["canvas"]

  connect() {
    console.log("📊 Admin Chart controller connected")
    console.log("Chart type:", this.typeValue)
    console.log("Chart data:", this.dataValue)
    
    // Ne créer des graphiques que pour les éléments avec des données
    if (this.typeValue && this.dataValue && this.dataValue.length > 0) {
      this.initChart()
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  initChart() {
    const canvas = this.element.querySelector('canvas') || this.createCanvas()
    const ctx = canvas.getContext('2d')
    
    const chartConfig = this.getChartConfig()
    this.chart = new Chart(ctx, chartConfig)
  }

  createCanvas() {
    const canvas = document.createElement('canvas')
    canvas.style.width = '100%'
    canvas.style.height = '250px'
    this.element.appendChild(canvas)
    return canvas
  }

  getChartConfig() {
    if (this.typeValue === 'line') {
      return this.getLineChartConfig()
    } else if (this.typeValue === 'doughnut') {
      return this.getDoughnutChartConfig()
    }
    
    return this.getDefaultConfig()
  }

  getLineChartConfig() {
    const data = this.dataValue || []
    
    return {
      type: 'line',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Revenus (€)',
          data: data.map(item => item.revenue),
          borderColor: '#3b82f6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderWidth: 2,
          fill: true,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: {
              color: '#e5e7eb'
            }
          }
        },
        scales: {
          x: {
            ticks: {
              color: '#9ca3af'
            },
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            }
          },
          y: {
            ticks: {
              color: '#9ca3af',
              callback: function(value) {
                return value + '€'
              }
            },
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            }
          }
        }
      }
    }
  }

  getDoughnutChartConfig() {
    const data = this.dataValue || []
    
    const colors = [
      '#3b82f6', // blue
      '#10b981', // green  
      '#f59e0b', // yellow
      '#ef4444', // red
      '#8b5cf6'  // purple
    ]

    return {
      type: 'doughnut',
      data: {
        labels: data.map(item => item.status),
        datasets: [{
          data: data.map(item => item.count),
          backgroundColor: colors.slice(0, data.length),
          borderColor: colors.slice(0, data.length),
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#e5e7eb',
              padding: 20,
              usePointStyle: true
            }
          }
        }
      }
    }
  }

  getDefaultConfig() {
    return {
      type: 'bar',
      data: {
        labels: [],
        datasets: []
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    }
  }

  // Method called by dashboard controller to update data
  updateData(newData) {
    if (!this.chart) return
    
    if (this.typeValue === 'line') {
      this.chart.data.labels = newData.map(item => item.date)
      this.chart.data.datasets[0].data = newData.map(item => item.revenue)
    } else if (this.typeValue === 'doughnut') {
      this.chart.data.labels = newData.map(item => item.status)
      this.chart.data.datasets[0].data = newData.map(item => item.count)
    }
    
    this.chart.update('active')
  }

  // Method called by dashboard controller to refresh
  refreshData() {
    if (this.chart) {
      this.chart.update()
    }
  }

  initChart() {
    const canvas = this.element.querySelector('canvas') || this.createCanvas()
    const ctx = canvas.getContext('2d')
    
    const chartConfig = this.getChartConfig()
    this.chart = new Chart(ctx, chartConfig)
  }

  createCanvas() {
    const canvas = document.createElement('canvas')
    canvas.style.width = '100%'
    canvas.style.height = '250px'
    this.element.appendChild(canvas)
    return canvas
  }

  getChartConfig() {
    if (this.typeValue === 'line') {
      return this.getLineChartConfig()
    } else if (this.typeValue === 'doughnut') {
      return this.getDoughnutChartConfig()
    }
    
    return this.getDefaultConfig()
  }

  getLineChartConfig() {
    const data = this.dataValue || []
    
    return {
      type: 'line',
      data: {
        labels: data.map(item => item.date),
        datasets: [{
          label: 'Revenus (€)',
          data: data.map(item => item.revenue),
          borderColor: '#3b82f6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderWidth: 2,
          fill: true,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            labels: {
              color: '#e5e7eb'
            }
          }
        },
        scales: {
          x: {
            ticks: {
              color: '#9ca3af'
            },
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            }
          },
          y: {
            ticks: {
              color: '#9ca3af',
              callback: function(value) {
                return value + '€'
              }
            },
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            }
          }
        }
      }
    }
  }

  getDoughnutChartConfig() {
    const data = this.dataValue || []
    
    const colors = [
      '#3b82f6', // blue
      '#10b981', // green  
      '#f59e0b', // yellow
      '#ef4444', // red
      '#8b5cf6'  // purple
    ]

    return {
      type: 'doughnut',
      data: {
        labels: data.map(item => item.status),
        datasets: [{
          data: data.map(item => item.count),
          backgroundColor: colors.slice(0, data.length),
          borderColor: colors.slice(0, data.length),
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#e5e7eb',
              padding: 20,
              usePointStyle: true
            }
          }
        }
      }
    }
  }

  getDefaultConfig() {
    return {
      type: 'bar',
      data: {
        labels: [],
        datasets: []
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    }
  }

  // Method called by dashboard controller to update data
  updateData(newData) {
    if (!this.chart) return
    
    if (this.typeValue === 'line') {
      this.chart.data.labels = newData.map(item => item.date)
      this.chart.data.datasets[0].data = newData.map(item => item.revenue)
    } else if (this.typeValue === 'doughnut') {
      this.chart.data.labels = newData.map(item => item.status)
      this.chart.data.datasets[0].data = newData.map(item => item.count)
    }
    
    this.chart.update('active')
  }

  // Method called by dashboard controller to refresh
  refreshData() {
    if (this.chart) {
      this.chart.update()
    }
  }
}