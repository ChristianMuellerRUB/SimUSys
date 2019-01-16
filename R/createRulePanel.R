# createRulePanel.r

createRulePanel <- function(r, addSlider_names, addSlider_ids, lastYvar_sel, lastXvar_sel, preDatAvailable, slider_vals, slider_mins, slider_maxs){

  controlPanel_args <- list(id = paste("controls", r, sep = "_"), class = "panel panel-default", fixed = TRUE,
                            draggable = TRUE, top = 80, left = 50, right = 20, bottom = "auto",
                            width = 360, height = "auto", align = "center")
  
  if (addSlider_names[1] != ""){
    controlPanel_args[[length(controlPanel_args)+1]] <- actionButton(inputId = paste("derrule", r, sep = "_"), label = labelNames[which(labelNames[,1] == "derW"),lan])
  }
  
  preDatAvailable <- strsplit(preDatAvailable, ";", fixed = T)[[1]]
  sort_this <- c()
  for (i in 1:nrow(allAnalAtts)){
    temp <- strsplit(allAnalAtts[i,2], " ", fixed = T)[[1]]
    sort_this <- c(sort_this, temp[length(temp)])
  }
  yVarPanel_choices <- allAnalAtts[,2][order(sort_this)]
  
  if ("Bochum" %in% preDatAvailable) controlPanel_args[[length(controlPanel_args)+1]] <- actionButton(inputId = paste("takerulefrombochum", r, sep = "_"), label = labelNames[which(labelNames[,1] == "trbochum"),lan])
  if ("Herdecke" %in% preDatAvailable) controlPanel_args[[length(controlPanel_args)+1]] <- actionButton(inputId = paste("takerulefromherdecke", r, sep = "_"), label = labelNames[which(labelNames[,1] == "trherdecke"),lan])
  if ("HerdeckeInnenstadt" %in% preDatAvailable) controlPanel_args[[length(controlPanel_args)+1]] <- actionButton(inputId = paste("takerulefromherdeckeinnen", r, sep = "_"), label = labelNames[which(labelNames[,1] == "trherdeckeinnen"),lan])
  if ("Herten" %in% preDatAvailable) controlPanel_args[[length(controlPanel_args)+1]] <- actionButton(inputId = paste("takerulefromherten", r, sep = "_"), label = labelNames[which(labelNames[,1] == "trherten"),lan])
  
  controlPanel <- do.call(wellPanel, controlPanel_args)
  
  yVarPanel <- wellPanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                         draggable = TRUE, top = 80, left = 50, right = 20, bottom = "auto",
                         width = 360, height = "auto", align = "center",
                         
                         h4(labelNames[which(labelNames[,1] == "yVarName"),lan]),
                         selectInput(inputId = paste("rule", r, "y", sep = "_"), label = NULL,
                                     choices = c(plsChoose, sort(yVarPanel_choices)), width = "100%", selected = lastYvar_sel))
  
  
  
  # generate dynamic x variable panel
  xArgsList <- list(id = "controls", class = "panel panel-default", fixed = F,
                    draggable = TRUE, top = 80, left = 50, right = 20, bottom = "auto",
                    width = 360, height = "auto", align = "center")
  xArgsList[[length(xArgsList)+1]] <- h4(labelNames[which(labelNames[,1] == "xVarName"),lan])
  
  xArgsList[[length(xArgsList)+1]] <- selectInput(inputId = paste("rule", r, "xSel", sep = "_"), label = NULL,
                                                  choices = c(addText, sort(allAnalAtts[,2])), width = "100%", selected = lastXvar_sel)
  
  
  if (addSlider_names[1] != ""){
    for (s in 1:length(addSlider_names)){
      xArgsList[[length(xArgsList)+1]] <- createXVarSlider(addSlider_names[s], addSlider_ids[s], slider_vals[s], slider_mins[s], slider_maxs[s])
    }
    
    xArgsList[[length(xArgsList)+1]] <- actionButton(inputId = paste("rmvSlider", r, sep = "_"), label = labelNames[which(labelNames[,1] == "rmvSlider"),lan])
    
  }
  
  xVarPanel <- do.call(wellPanel, xArgsList)
           
  
  # generate tabPanel
  argList <- list(paste(labelNames[which(labelNames[,1] == "rule"),lan], r, sep = " "),
                  value = paste("tabPanel_rule", r, sep = "_"),
                  controlPanel, yVarPanel, xVarPanel)
  
  do.call(tabPanel, argList)
        
}