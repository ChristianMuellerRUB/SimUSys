# getAllAvailableAnalysisAttributes.r

getAllAvailableAnalysisAttributes <- function(allAnalysisLayers_nice){

  # get all available attributes
  allLayers <- c()
  allLayers_nice <- c()
  allLayers_paths <- c()
  allAttributes <- c()
  allAttributes_nice <- c()
  allPaths <- c()
  allPaths_full <- c()
  
  analysisLayers <<- c("Erreichbarkeit_mitFahrrad", "Erreichbarkeit_mitPKW", "Erreichbarkeit_zuFuss",
                       "LuftlinienDistanzen", "PlanungseinheitenAggregiert_total", "Raumattraktivitaet",
                       "NetzwerkeAggregiert", "UmweltAggregiert")
  
  for (aL in 1:length(allAnalysisLayers_nice)){
    
    thisLayer_nice <- allAnalysisLayers_nice[aL]
    thisPos <- which(lyrNames[,5] == allAnalysisLayers_nice[aL])
    if (length(thisPos) == 0) thisPos <- which(lyrNames[,6] == allAnalysisLayers_nice[aL])
    thisLayer <- lyrNames[thisPos, 4]
    thisPath <- lyrNames[thisPos, 10]
    thisPath_full <- paste(modDat, thisPath, sep = "/")
    
    if (thisLayer %in% analysisLayers){
    
      thisAtts <- getInformativeAttributes(thisLayer_nice)
      
      thisAtts_nice <- c()
      for (at in 1:length(thisAtts)){
      
        thisAtts_nice <- c(thisAtts_nice, attNames[which(attNames[,1] == thisAtts[at]), lan])
        
      }
      
      # bring all information for this loop together
      allAttributes <- c(allAttributes, thisAtts)
      allAttributes_nice <- c(allAttributes_nice, thisAtts_nice)
      allLayers_nice <- c(allLayers_nice, rep(allAnalysisLayers_nice[aL], times = length(thisAtts)))
      allLayers <- c(allLayers, rep(thisLayer, times = length(thisAtts)))
      allPaths <- c(allPaths, rep(thisPath, times = length(thisAtts)))
      allPaths_full <- c(allPaths_full, rep(thisPath_full, times = length(thisAtts)))
      
    }
  }
  
  # bring all information together
  out <- cbind(allAttributes, allAttributes_nice, allLayers_nice, allLayers)
  
  return(out)
  
}