# update_distances.r

# Calculates the shortest (network) distance between points based on travel cost analysis

update_Distances <- function(updateToFeatures_name){
  
  # get target spatial object
  updateToFeatures <<- get(updateToFeatures_name)
  
  # get respective attribute field
  thisRow <- which(attNames[,"shortNames"] == updateToFeatures_name)
  thisAtts <- attNames[thisRow,]
  
  # get default analysis raster
  ras_path <- paste(modDat, "/AnalysenErgebnisse/Gitter_raster.tif", sep = "")
  ras <- raster(ras_path)
  
  
  # get accessibility object names
  costRasterPaths <- c("Erreichbarkeit_zuFuss", "Erreichbarkeit_mitFahrrad", "Erreichbarkeit_mitPKW")
  
  for (c in 1:length(costRasterPaths)){
  
    # cost raster
    crasPath <- paste(modDat, "/AnalysenErgebnisse/", costRasterPaths[c], "_TransitionObjekt.r", sep = "")
    
    # load transition raster
    attach(crasPath)
    
    updateToFeatures_UTM <<- spTransform(updateToFeatures, UTMproj)
    useCoords <<- getVertexCoordinates(updateToFeatures_UTM)
    toPoints_buf <<- gBuffer(updateToFeatures_UTM, byid = T, width = 50)
    useCoords_buf <<- getVertexCoordinates(toPoints_buf)
    useCoords <- rbind(useCoords[,1:2], useCoords_buf[,1:2])
    toPoints <- SpatialPointsDataFrame(useCoords, as.data.frame(rep(0, nrow(useCoords))), proj4string = UTMproj)
    
    # calculate travel cost
    costs <- accCost(costTrans, toPoints)
    pos <- which(values(costs) == "Inf")
    if (length(pos) > 0) values(costs)[pos] <- NA
    
    # get accessibility object
    acc_sp <- get(costRasterPaths[c])
    acc_dat <- acc_sp@data
    acc_sp_proj <- spTransform(acc_sp, CRS(costTrans@crs@projargs))
    
    # resample recalculated values to accessiblity object
    costs_res <- resample(costs, ras)
    
    # get respective attribute field
    pos <- which(thisAtts[,1] %in% colnames(acc_dat))
    thisAtt <- thisAtts[pos,1]
    
    # rescale calculated distances
    fromVals <- get(paste0(costRasterPaths[c], "_origrange"))
    pos <- which(colnames(fromVals) == thisAtt)
    if (length(pos != 0) & (fromVals[1,pos] != "Inf")) fromVal <- fromVals[,pos] else fromVal <- c(0,1)
    norm_temp <- rescale(values(costs_res), from = fromVal, to = c(0,1))
    norm_temp[which(is.na(norm_temp))] <- NA
    
    
    # update attribute
    acc_dat[,thisAtt] <- norm_temp
    acc_sp@data <- acc_dat
    assign(costRasterPaths[c], acc_sp, envir = .GlobalEnv)
    
    if (c == 1){
    
      # update euclidean distances
      values(ras) <- 1
      trans <- transition(ras, mean, 8)
      costs <- accCost(trans, toPoints)
      pos <- which(values(costs) == "Inf")
      if (length(pos) > 0) values(costs)[pos] <- NA
      values(costs) <- values(costs) * res(costs)[1]
      getOneSpatialObject("LuftlinienDistanzen")
      dist_dat <- LuftlinienDistanzen@data
      pos <- which(thisAtts[,1] %in% colnames(dist_dat))
      thisAtt <- thisAtts[pos,1]
      
      # rescale values
      fromVals <- get("LuftlinienDistanzen_origrange")
      pos <- which(colnames(fromVals) == thisAtt)
      if (length(pos != 0) & (fromVals[1,pos] != "Inf")) fromVal <- fromVals[,pos] else fromVal <- c(0,1)
      norm_temp <- rescale(values(costs_res), from = fromVal, to = c(0,1))
      
      dist_dat[,thisAtt] <- norm_temp
      norm_temp <- normalize_fast(as.matrix(dist_dat[,-1]))
      LuftlinienDistanzen@data <- as.data.frame(cbind(dist_dat[,1], norm_temp[[1]]))
      assign("LuftlinienDistanzen", LuftlinienDistanzen, envir = .GlobalEnv)
    }
    
    
  }
    
}
