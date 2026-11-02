
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    config: Object,
    unit: String,
    breakdown: Array
  }

  connect() {
    const Chart = window.Chart

    if (!Chart || !this.hasConfigValue) return

    Chart.getChart(this.element)?.destroy()

    const config = JSON.parse(JSON.stringify(this.configValue))
    const formatter = new Intl.NumberFormat()
    const unit = this.unitValue || ""

    config.options ||= {}
    config.options.responsive = true
    config.options.maintainAspectRatio = false

    config.options.plugins ||= {}

    config.options.plugins.legend = {
      ...config.options.plugins.legend,
      display: false
    }

    config.options.plugins.tooltip ||= {}
    config.options.plugins.tooltip.callbacks ||= {}

    config.options.plugins.tooltip.callbacks.label = (context) => {
      const value = context.parsed?.y ?? context.parsed
      const formattedValue = formatter.format(Number(value || 0))

      const totalLine =
        `${context.dataset.label || "Total"}: ${formattedValue} ${unit}`.trim()

      if (!this.hasBreakdownValue) {
        return totalLine
      }

      const monthBreakdown = this.breakdownValue[context.dataIndex] || {}

      const detailLines = Object.entries(monthBreakdown).map(
        ([product, amount]) => {
          return `${product}: ${formatter.format(Number(amount || 0))} ${unit}`.trim()
        }
      )

      return [totalLine, ...detailLines]
    }

    config.options.scales ||= {}

    config.options.scales.x = {
      grid: { display: false },
      ticks: {
        maxRotation: 0,
        autoSkip: true
      },
      ...config.options.scales.x
    }

    config.options.scales.y = {
      beginAtZero: true,
      grid: {
        color: "rgba(148, 163, 184, 0.14)"
      },
      ticks: {
        callback: (value) => formatter.format(Number(value))
      },
      ...config.options.scales.y
    }

    this.chart = new Chart(this.element, config)
  }

  disconnect() {
    this.chart?.destroy()
    this.chart = null
  }
}
