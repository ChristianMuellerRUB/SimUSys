# setParametersAccordingToPredefinedFile.r

setParametersAccordingToPredefinedFile <- function(allRuleParameters, thisR, compareString, preDefAv){
  
  pos <- which(allRuleParameters[,1] == thisR)
  
  # add a row to rule table if the rule number was not defined erliear
  if (length(pos) == 0) {
    addR <- allRuleParameters[nrow(allRuleParameters),]
    addR <- as.matrix(addR)
    if (ncol(t(addR)) == ncol(allRuleParameters)) addR <- t(addR)
    addR[,1] <- thisR
    addR[,2] <- paste("tabPanel_rule_", thisR, sep = "")
    addR[,3] <- paste("rule_", thisR, "_y", sep = "")
    addR[,4] <- preDefAv[as.numeric(thisR), 1]
    addR[,5] <- paste("rule_", thisR, "_xSel", sep = "")
    addR[,7] <- paste(addR[,1], addR[,2], addR[,3], addR[,4], addR[,5], addR[,6], collapse = "_")
    temp <- strsplit(addR[,8], "_", fixed = T)[[1]]
    addR[,8] <- paste(temp[1], "_", as.numeric(temp[2]) + 1, sep = "")
    addR[,9] <- paste(temp[1], addR[,6], "rule", thisR, sep = "_")
    addR[,10] <- 1
    addR[,11] <- -1
    addR[,12] <- 1
    addR[,13] <- 1
    allRuleParameters <- rbind(allRuleParameters, addR)
    pos <- nrow(allRuleParameters)
  }
  pos2 <- c()
  for (r in 1:nrow(preDefAv)){
    if (paste(preDefAv[r,1:2], collapse = "_") == paste(c(allRuleParameters[pos[1], 4], "HerdeckeInnenstadt"), collapse = "_")) pos2 <- r
  }
  if (length(pos2) > 0){
    dat <- get(preDefAv[pos2, 3])
    temp_1 <- allRuleParameters[pos[1],1]
    temp_2 <- allRuleParameters[pos[1],2]
    temp_3 <- allRuleParameters[pos[1],3]
    temp_4 <- allRuleParameters[pos[1],4]
    temp_5 <- allRuleParameters[pos[1],5]
    temp_8 <- strsplit(allRuleParameters[pos[1],8], "_", fixed = T)[[1]][2]
    out <- matrix(NA, nrow = nrow(dat)-1, ncol = ncol(allRuleParameters), dimnames = list(c(), colnames(allRuleParameters)))
    out[,1] <- temp_1
    out[,2] <- temp_2
    out[,3] <- temp_3
    out[,4] <- temp_4
    out[,5] <- temp_5
    out[,6] <- unlist(lapply(2:nrow(dat), function(i){strsplit(dat[i,1], "_", fixed = T)[[1]][1]}))
    out[,7] <- unlist(lapply(1:nrow(out), function(i){paste(out[i,1:6], collapse = "_")}))
    out[,8] <- unlist(lapply(as.numeric(temp_8):(as.numeric(temp_8)+nrow(dat)-2), function(i){paste("xSlider", as.character(i), sep = "_")}))
    out[,9] <- paste("xSlider", out[,6], "rule", out[,1], sep = "_")
    out[,10] <- as.character(dat[-1,2])
    out[,11] <-  as.character(round(min(dat[-1,2], na.rm = T), digits = 2))
    out[,12] <-  as.character(round(max(dat[-1,2], na.rm = T), digits = 2))
    if (length(unique(dat[-1,2])) == 1){
      out[,11] <-  unique(dat[-1,2]) * (-1)
      out[,12] <-  unique(dat[-1,2])
    }
    out[,13] <- as.character(dat[1,2])
    out <<- out
    allRuleParameters <- allRuleParameters[-pos,]
    allRuleParameters <- rbind(allRuleParameters, out)
    return(allRuleParameters)
    
  }
  
}