# createGauge.r

createGauge <- function(gauge_val, gauge_min, gauge_max, gauge_label) {
  
    flexdashboard::renderGauge(
      flexdashboard::gauge(value = gauge_val, min = gauge_min, max = gauge_max, label = gauge_label, gaugeSectors(colors = "#34888C"))
    )
    
}