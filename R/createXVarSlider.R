# createXVarSlider.r

createXVarSlider <- function(slider_name, slider_id, slider_val, slider_min, slider_max){
  
  wellPanel(id = "controls", class = "panel panel-default", fixed = F,
            draggable = TRUE, top = 80, left = 50, right = 20, bottom = "auto",
            width = 360, height = "auto", align = "center", style = "background-color: #ffffff;",
            
            sliderInput(inputId = slider_id,
                        label = slider_name, value = as.numeric(slider_val),
                        min = as.numeric(slider_min), max = as.numeric(slider_max), step = 0.001, width = "100%")
                      
            )
  
}