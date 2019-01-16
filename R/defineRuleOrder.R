# defineRuleOrder.r

defineRuleOrder <- function(allRuleParameters){
  
  allRuleNumbers <- rev(unique(allRuleParameters[,1]))
  for (i in 1:length(allRuleNumbers)){
    thisRLines <- which(allRuleParameters[,1] == as.character(i))
    for (j in 1:length(thisRLines)){
      this_x <- as.vector(t(allRuleParameters[thisRLines[j],6]))
      if (this_x %in% allRuleParameters[,4]){
        pos <- which(allRuleParameters[,4] == this_x)
        changeRs <- c()
        for (k in 1:length(pos)){
          changeRs <- c(changeRs, allRuleParameters[pos[k],1])
        }
        changeR <- unique(changeRs)
        for (k in 1:length(changeR)){
          newPos <- which(allRuleNumbers == changeR[k])
          temp <- c(NA, allRuleNumbers)
          for (l in 1:newPos){
            temp[l] <- allRuleNumbers[l]
          }
          temp[newPos+1] <- NA
          temp[which(temp == as.character(i))] <- NA
          temp[newPos+1] <- as.character(i)
          allRuleNumbers <- as.vector(na.omit(temp))
        }
      }
    }
  }
  attRule <- allRuleParameters[which(allRuleParameters[,4] == "Raumattraktivität"),1][1]
  allRuleNumbers <- allRuleNumbers[-which(allRuleNumbers == attRule)]
  allRuleNumbers <- c(allRuleNumbers, attRule)
  return(allRuleNumbers)
  
}