import { Controller } from "@hotwired/stimulus"

// Renders an ApexCharts chart into the element using a JSON `options` value.
//
// <div data-controller="chart"
//      data-chart-options-value='{ "chart": {"type":"area"}, "series":[...], ... }'>
// </div>
//
// The full ApexCharts API is exposed — pass any options the library accepts.
// On Turbo navigation Stimulus disconnect() destroys the chart so it can be
// recreated cleanly on the next page.
export default class extends Controller {
  static values = { options: Object }

  connect() {
    if (typeof window.ApexCharts === "undefined") {
      console.warn("chart_controller: window.ApexCharts is not loaded")
      return
    }
    this.chart = new window.ApexCharts(this.element, this.optionsValue)
    this.chart.render()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
