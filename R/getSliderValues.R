# getSliderValues.r

getSliderValues <- function(thisR, output_method = "full"){
  
  pos <- which(allRuleParameters[,1] == thisR)
  if (length(pos) > 0){
    sliderID <- unname(allRuleParameters[pos, 8])
    thisR_sliderValues <<- lapply(1:length(sliderID), function(i){input[[sliderID[i]]]})
  
    outPar <- as.matrix(allRuleParameters[pos,])
    if (ncol(outPar) != ncol(allRuleParameters)) outPar <- t(outPar)
    
    sliderVals <- as.character(unlist(thisR_sliderValues))
    if (length(sliderVals) > 0){
      
      outPar[,10] <- sliderVals
      
      if (output_method == "full"){
        outPar <- rbind(allRuleParameters[-pos,], outPar)
      }
      
      
    } else {
      
      outPar <- allRuleParameters
      
    }
    
    return(outPar)
    
  }
  
}