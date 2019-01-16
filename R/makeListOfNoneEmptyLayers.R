# makeListOfNoneEmptyLayers.r

makeListOfNoneEmptyLayers <- function(inList, modDat){
  
  outList <- inList
  
  if (class(inList[[1]]) == "character"){
    nLevels <- 1
  } else if (class(inList[[1]][[1]]) == "character"){
    nLevels <- 2
  } else {
    nLevels <- 3
  }
  
  for (lev1 in 1:length(inList)){
    tempList <- inList[[lev1]]
    
    if (nLevels == 3){
      for (lev2 in 1:length(tempList)){
        tempList2 <- tempList[[lev2]]
        tempNull <- c()
        for (lev3 in 1:length(tempList2)){
          thisLayer <- tempList2[[lev3]]
          tempPath <- lyrNames[which(lyrNames == thisLayer, arr.ind = T)[1,1], "path"]
          tempPath <- paste(modDat, tempPath, sep = "/")[1]
          nFeatures <- 0
          try(nFeatures <- ogrInfo(dirname(tempPath), strsplit(basename(tempPath), ".", fixed = T)[[1]][1])[1], silent = T)
          if (nFeatures == 0) tempNull <- c(tempNull, lev3)
        }
        outList[[lev1]][[lev2]][tempNull] <- NULL
      }
    } else {
      tempNull <- c()
      for (lev2 in 1:length(tempList)){
        thisLayer <- tempList[[lev2]]
        tempPath <- lyrNames[which(lyrNames == thisLayer, arr.ind = T)[1,1], "path"]
        tempPath <- paste(modDat, tempPath, sep = "/")[1]
        nFeatures <- 0
        try(nFeatures <- ogrInfo(dirname(tempPath), strsplit(basename(tempPath), ".", fixed = T)[[1]][1])[1], silent = T)
        if (nFeatures == 0) tempNull <- c(tempNull, lev2)
      }
      outList[[lev1]][tempNull] <- NULL
    }
  }
  
  return(outList)
  
}

