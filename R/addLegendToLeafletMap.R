# addLegendToLeafletMap.r

# adds a legend to the leaflet map based on datatypes and geometry

addLegendToLeafletMap <- function(thisName){
  
  # get spatial data collections
  thiscSpP <<- paste("cSp", thisName, "P", sep = "")
  thiscSpL <<- paste("cSp", thisName, "L", sep = "")
  thiscSpPg <<- paste("cSp", thisName, "Pg", sep = "")
  
  # test if data was selected
  if ((length(names(get(thiscSpP))) > 0) || (length(names(get(thiscSpL))) > 0) || (length(names(get(thiscSpPg))) > 0)){
      
    # get selected attributes
    thisattSel_O <<- paste("attSel_O", thisName, sep = "")
    
    # get no value label
    noVal <- labelNames[which(labelNames[,1] == "noVal"), lan]
    
    # create legend if more data than geometry is shown
    if (get(thisattSel_O) != "oGeom"){
      
      # get legend label names
      legendLabelP <<- paste("legendLabel", thisName, "P", sep = "")
      legendLabelL <<- paste("legendLabel", thisName, "L", sep = "")
      legendLabelPg <<- paste("legendLabel", thisName, "Pg", sep = "")
      
      # get legend label colors
      legendColP <<- get(paste("cCols", thisName, "P_show", sep = ""))
      legendColL <<- get(paste("cCols", thisName, "L_show", sep = ""))
      legendColPg <<- get(paste("cCols", thisName, "Pg_show", sep = ""))
      
      # diferentiated methods for different data types
      if ((class(get(legendLabelP)) == "factor") || (class(get(legendLabelL)) == "factor") || (class(get(legendLabelPg)) == "factor")){
        
        # categorical data
        
        # combine legend colors and labels for multiple layer selection
        legendCol_temp <- c(unique(legendColP), unique(legendColL), unique(legendColPg))
        legendLabel_temp <- c(as.character(get(legendLabelP)), as.character(get(legendLabelL)), as.character(get(legendLabelPg)))
        legendColLabel <- cbind(legendCol_temp, legendLabel_temp)
        legendColLabel <- cbind(legendColLabel, paste(legendColLabel[,1], legendColLabel[,2], sep = "_"))
        allUnique <- unique(legendColLabel[,3])
        unvalidPos <- c()
        unvalidPos <- c(unvalidPos, which(allUnique == "_"))
        unvalidPos <- c(unvalidPos, which(allUnique == "NA_"))
        unvalidPos <- c(unvalidPos, which(allUnique == "_NA"))
        if (length(unvalidPos) > 0) allUnique <- allUnique[-unvalidPos]
        legendCol <- c()
        legendLabel <- c()
        for (lc in 1:length(allUnique)){
          thispos <- which(legendColLabel[,3] == allUnique[lc])[1]
          if (length(thispos) > 0){
            thisCol <- as.character(legendColLabel[thispos, 1])
            if (is.na(thisCol)) thisCol <- "_"
            legendCol <- c(legendCol, thisCol)
            thisLabel <- as.character(legendColLabel[thispos, 2])
            if (is.na(thisLabel)) thisLabel <- "_"
            legendLabel <- c(legendLabel, thisLabel)
          }
        }
        assign(paste("legendCol", thisName, sep = ""), as.vector(legendCol), envir = .GlobalEnv)
        assign(paste("legendLabel", thisName, sep = ""), as.vector(legendLabel), envir = .GlobalEnv)
        
      } else {
        
        # contiguous data
        
        # points
        if ((class(get(legendLabelP)) == "numeric") || (class(get(legendLabelP)) == "integer") || (class(get(legendLabelP)) == "factor")){
          thisLabs <- sort(get(legendLabelP))
          ord <- order(get(legendLabelP))
          if (length(unique(quantile(get(thiscSpP)@data[,get(thisattSel_O)], na.rm = T))) < 5){
            useThis <- thisLabs
          } else {
            useThis <- quantile(thisLabs, na.rm = T)
          }
          useThisCol <- as.vector(na.omit(get(paste("legendCol", thisName, sep = ""))))
          if (length(useThisCol) != length(useThis)){
            useThisCol <- colorBin(palette = usePal, domain = 1:length(useThis), bins = useThis)(useThis)
          }
          useThis <- paste("<= ", useThis, sep = "")
          thisGeom <- "P"
          if ((("#808080" %in% useThisCol) == F) && ("#808080" %in% get(paste("cCols", thisName, thisGeom, "_show", sep = "")))){
            useThisCol <- c(useThisCol, "#808080")
          }
          assign(paste("legendCol", thisName, sep = ""), useThisCol, envir = .GlobalEnv)
          legendLabeltemp <<- c(as.character(useThis), labelNames[which(labelNames[,1] == "noVal"),lan])
          if (length(legendLabeltemp) != length(useThisCol)) legendLabeltemp <- legendLabeltemp[-length(legendLabeltemp)]
          assign(paste("legendLabel", thisName, sep = ""), legendLabeltemp, envir = .GlobalEnv)
        }
        
        # lines
        if ((class(get(legendLabelL)) == "numeric") || (class(get(legendLabelL)) == "integer") || (class(get(legendLabelL)) == "factor")){
          thisLabs <- sort(get(legendLabelL))
          ord <- order(get(legendLabelL))
          assign(paste("legendCol", thisName, sep = ""), unique(legendColL)[ord], envir = .GlobalEnv)
          if (length(unique(quantile(get(thiscSpL)@data[,get(thisattSel_O)], na.rm = T))) < 5){
            useThis <- thisLabs
          } else {
            useThis <- quantile(thisLabs, na.rm = T)
          }
          useThis <- paste("<= ", useThis, sep = "")
          useThisCol <- get(paste("legendCol", thisName, sep = ""))
          thisGeom <- "L"
          if ((("#808080" %in% useThisCol) == F) && ("#808080" %in% get(paste("cCols", thisName, thisGeom, "_show", sep = "")))){
            useThisCol <- c(useThisCol, "#808080")
          }
          legendLabeltemp <<- c(as.character(useThis), labelNames[which(labelNames[,1] == "noVal"),lan])
          if (length(legendLabeltemp) != length(useThisCol)) legendLabeltemp <- legendLabeltemp[-length(legendLabeltemp)]
          assign(paste("legendLabel", thisName, sep = ""), get(legendLabelL), envir = .GlobalEnv)
        }
        
        # polygons
        if ((class(get(legendLabelPg)) == "numeric") || (class(get(legendLabelPg)) == "integer") || (class(get(legendLabelPg)) == "factor")){
          thisLabs <- sort(get(legendLabelPg))
          ord <- order(get(legendLabelPg))
          if (length(unique(quantile(get(thiscSpPg)@data[,get(thisattSel_O)], na.rm = T))) < 5){
            theseColsTemp <- unique(legendColPg)
            noValPos <- which(theseColsTemp == "#808080")
            if (length(noValPos) > 0) theseColsTemp <- theseColsTemp[-noValPos]
            theseColsTemp <- rev(sort(unique(theseColsTemp)))
            if (length(noValPos) > 0) theseColsTemp <- c(theseColsTemp, "#808080")
            if (unique(legendColPg)[length(unique(legendColPg))] %in% theseColsTemp == F) theseColsTemp <- c(theseColsTemp, unique(legendColPg)[length(unique(legendColPg))])
            if (length(theseColsTemp) != length(thisLabs)) {
              theseColsTemp <- colorBin(palette = usePal, domain = 1:length(thisLabs), bins = thisLabs)(thisLabs)
            }
            assign(paste("legendCol", thisName, sep = ""), theseColsTemp, envir = .GlobalEnv)
            if (length(theseColsTemp) < length(thisLabs)){
              thisDat <- get(thiscSpPg)@data[,get(thisattSel_O)]
              thisLabs <- round(unique(thisDat), digits = 2)
            }
            useThis <- thisLabs
            
          } else {
            useThis <- quantile(thisLabs, na.rm = T)
            assign(paste("legendCol", thisName, sep = ""), colorQuantile(palette = usePal, domain = useThis, n = 5)(useThis), envir = .GlobalEnv)
            useThis <- round(useThis, digits = 2)
          }
          useThis <- paste("<= ", useThis, sep = "")
          useThisCol <- get(paste("legendCol", thisName, sep = ""))
          thisGeom <- "Pg"
          if ((("#808080" %in% useThisCol) == F) && ("#808080" %in% get(paste("cCols", thisName, thisGeom, "_show", sep = "")))){
            useThisCol <- c(useThisCol, "#808080")
          }
          legendLabeltemp <<- c(as.character(useThis), labelNames[which(labelNames[,1] == "noVal"),lan])
          if (length(legendLabeltemp) != length(useThisCol)) useThisCol <- c(useThisCol, "#808080")
          assign(paste("legendCol", thisName, sep = ""), useThisCol, envir = .GlobalEnv)
          assign(paste("legendLabel", thisName, sep = ""), legendLabeltemp, envir = .GlobalEnv)
        }
        
        # simpler approach
        legendLabel <- legendLabeltemp
        showNoVal <- noVal %in% legendLabeltemp
        if (showNoVal) legendLabeltemp <- legendLabeltemp[-which(legendLabeltemp == noVal)]
        legendLabeltemp <- as.numeric(unlist(strsplit(legendLabeltemp, " ", fixed = T))[seq(2, length(legendLabeltemp) * 2, by = 2)])
        useThisCol <- colorBin(palette = usePal, domain = 1:length(legendLabeltemp), bins = legendLabeltemp)(legendLabeltemp)
        if (showNoVal) useThisCol <- c(useThisCol, "#808080")
        assign(paste("legendCol", thisName, sep = ""), useThisCol, envir = .GlobalEnv)
        assign(paste("legendLabel", thisName, sep = ""), legendLabel, envir = .GlobalEnv)
        
      }
    }
  }
  
}
