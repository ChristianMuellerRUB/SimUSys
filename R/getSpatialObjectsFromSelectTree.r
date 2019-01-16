# getSpatialObjectsFromSelectedTree.r

getSpatialObjectsFromSelectTree <- function(inputTree, topicName, reactVals){
  
  library(rgdal)
  
  # prepare inputs
  modDat <- isolate(reactVals$modDat)
  cSpPName <<- paste("cSp", topicName, "P", sep = "")
  cSpLName <<- paste("cSp", topicName, "L", sep = "")
  cSpPgName <<- paste("cSp", topicName, "Pg", sep = "")
  cColsPName <<- paste("cCols", topicName, "P", sep = "")
  cColsLName <<- paste("cCols", topicName, "L", sep = "")
  cColsPgName <<- paste("cCols", topicName, "Pg", sep = "")
  
  # execute code if at least one layer was selected
  if (length(get_selected(inputTree)) > 0){
    thisTree <<- unlist(get_selected(inputTree))
    
  
    # get layer object names from displayed/checked/selected layer names
    
    # loop over each selected layer
    for (i in 1:length(thisTree)){
      
      incProgress(1/length(thisTree) * i)
      
      lyrPos <- which(lyrNames[,6+lan] == thisTree[i])
      lyrPos2 <- 7
      if (length(lyrPos) == 0) {
        lyrPos <- which(lyrNames[,3+lan] == thisTree[i])
        lyrPos2 <- 4
      }
      if (length(lyrPos) == 1){
        
        thisTree[i] <- lyrNames[lyrPos, lyrPos2]
        
        
        # load data if the data is not already present in global variables
        getOneSpatialObject(thisTree[i])
        
        # combine layers and respective colors (while considering geometry)
        if (class(get(thisTree[i]))[1] == "SpatialPointsDataFrame"){
          if (class(get(cSpPName)) == "character"){
            warning(thisTree[i])
            spdat <- get(thisTree[i])
            if (("cID" %in% colnames(spdat@data)) == F) spdat@data <- cbind(spdat@data, cID = 1:nrow(spdat@data))
          } else {
            spdat1 <- get(cSpPName)
            spdat2 <- get(thisTree[i])
            if (("cID" %in% colnames(spdat1@data)) == F) spdat1@data <- cbind(spdat1@data, cID = 1:nrow(spdat1@data))
            if (("cID" %in% colnames(spdat2@data)) == F) spdat2@data <- cbind(spdat2@data, cID = 1:nrow(spdat2@data))
            row.names(spdat1) <- as.character(1:nrow(spdat1))
            row.names(spdat2) <- as.character(seq(nrow(spdat1)+1, (nrow(spdat1)+1 + nrow(spdat2)-1)))
            spdat <- rbind(spdat1, spdat2)
            if (("cID" %in% colnames(spdat@data)) == F) spdat@data <- cbind(spdat@data, cID = 1:nrow(spdat@data))
          }
          spdat@data[,"cID"] <- 1:nrow(spdat@data)
          assign(cSpPName, spdat, envir = .GlobalEnv)
          temp <- c(get(cColsPName), get(paste(thisTree[i], "col", sep = "_")))
          assign(cColsPName, temp[which(temp != "")], envir = .GlobalEnv)
        } else if (class(get(thisTree[i]))[1] == "SpatialLinesDataFrame"){
          if (class(get(cSpLName)) == "character"){
            spdat <- get(thisTree[i])
            if (("cID" %in% colnames(spdat@data)) == F) spdat@data <- cbind(spdat@data, cID = 1:nrow(spdat@data))
          } else {
            spdat1 <- get(cSpLName)
            spdat2 <- get(thisTree[i])
            if (("cID" %in% colnames(spdat1@data)) == F) spdat1@data <- cbind(spdat1@data, cID = 1:nrow(spdat1@data))
            if (("cID" %in% colnames(spdat2@data)) == F) spdat2@data <- cbind(spdat2@data, cID = 1:nrow(spdat2@data))
            row.names(spdat1) <- as.character(1:nrow(spdat1))
            row.names(spdat2) <- as.character(seq(nrow(spdat1)+1, (nrow(spdat1)+1 + nrow(spdat2)-1)))
            spdat <- rbind(spdat1, spdat2)
            if (("cID" %in% colnames(spdat@data)) == F) spdat@data <- cbind(spdat@data, cID = 1:nrow(spdat@data))
          }
          spdat@data[,"cID"] <- 1:nrow(spdat@data)
          assign(cSpLName, spdat, envir = .GlobalEnv)
          temp <- c(get(cColsLName), get(paste(thisTree[i], "col", sep = "_")))
          assign(cColsLName, temp[which(temp != "")], envir = .GlobalEnv)
        } else if (class(get(thisTree[i]))[1] == "SpatialPolygonsDataFrame"){
          if (class(get(cSpLName)) == "character"){
            spdat <- get(thisTree[i])
            
            if (("cID" %in% colnames(spdat@data)) == F) spdat@data <- cbind(spdat@data, cID = 1:nrow(spdat@data))
            
          } else {
            spdat1 <- get(cSpPgName)
            spdat2 <- get(thisTree[i])
            if (("cID" %in% colnames(spdat1@data)) == F) spdat1@data <- cbind(spdat1@data, cID = 1:nrow(spdat1@data))
            if (("cID" %in% colnames(spdat2@data)) == F) spdat2@data <- cbind(spdat2@data, cID = 1:nrow(spdat2@data))
            row.names(spdat1) <- as.character(1:nrow(spdat1))
            row.names(spdat2) <- as.character(seq(nrow(spdat1)+1, (nrow(spdat1)+1 + nrow(spdat2)-1)))
            spdat <- rbind(spdat1, spdat2)
            if (("cID" %in% colnames(spdat@data)) == F) spdat@data <- cbind(spdat@data, cID = 1:nrow(spdat@data))
          }
          spdat@data[,"cID"] <- 1:nrow(spdat@data)
          assign(cSpPgName, spdat, envir = .GlobalEnv)
          temp <- c(get(cColsPgName), get(paste(thisTree[i], "col", sep = "_")))
          assign(cColsPgName, temp[which(temp != "")], envir = .GlobalEnv)
        }
        
      }
    }
    
    # get informative attributes
    useObj <- ""
    if (class(get(cSpPName)) != "character") useObj <- get(cSpPName)
    if (class(get(cSpLName)) != "character") useObj <- get(cSpLName)
    if (class(get(cSpPgName)) != "character") useObj <- get(cSpPgName)
    if (class(useObj) != "character"){
      valAtts <- colnames(useObj@data)
      valAtts <- valAtts[which(valAtts %in% attNames[,1])]
      outCases <- c()
      for (c in 1:length(valAtts)){
        if (all(is.na(useObj@data[,valAtts[c]]))){
          outCases <- c(outCases, c)
        } else if (all(useObj@data[which(is.na(useObj@data[,valAtts[c]]) == F),valAtts[c]] == 0)){
          outCases <- c(outCases, c)
        }
      }
      if (length(outCases) > 0) valAtts <- valAtts[-outCases]
      attTemp <- c("oGeom", valAtts)
      attOutName <- paste(substring(cSpPName, 4, nchar(cSpPName) - 1), "att", sep = "_")
      assign(attOutName, attTemp, envir = .GlobalEnv)
      assign(paste(attOutName, "nice", sep = "_"), attNames[which(attNames[,1] %in% attTemp),lan], envir = .GlobalEnv)
    } 
    
  } else {
    attOutName <- paste(substring(cSpPName, 4, nchar(cSpPName) - 1), "att", sep = "_")
    assign(attOutName, attNames[which(attNames[,1] == "oGeom"),1], envir = .GlobalEnv)
    assign(paste(attOutName, "nice", sep = "_"), attNames[which(attNames[,1] == "oGeom"),lan], envir = .GlobalEnv)
  }
  
  # add combined layers and colors to reactive values
  reactVals[[paste("cSp", topicName, "P", sep = "")]] <<- get(paste("cSp", topicName, "P", sep = ""))
  reactVals[[paste("cSp", topicName, "L", sep = "")]] <<- get(paste("cSp", topicName, "L", sep = ""))
  reactVals[[paste("cSp", topicName, "Pg", sep = "")]] <<- get(paste("cSp", topicName, "Pg", sep = ""))
  reactVals[[paste("cCols", topicName, "P", sep = "")]] <<- get(paste("cCols", topicName, "P", sep = ""))
  reactVals[[paste("cCols", topicName, "L", sep = "")]] <<- get(paste("cCols", topicName, "L", sep = ""))
  reactVals[[paste("cCols", topicName, "Pg", sep = "")]] <<- get(paste("cCols", topicName, "Pg", sep = ""))
  
}