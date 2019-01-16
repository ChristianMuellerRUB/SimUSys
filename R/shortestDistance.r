# shortestDistance.r
# Calculates the shortest (network) distance between points based on travel cost analysis

shortestDistance <- function(fromPoints, toPointsPath, networkLinesPath, outFilePath, outFieldPrefix, gridCellSize, costRasCellSize, scriptPath, fromPointsPath){
  
  # load packages
  print("Loading R-Packages...")
  options(repos = c(CRAN = "http://cran.rstudio.com"))
  .libPaths(paste(scriptPath, "libraries", sep = "/"))
  for (i in 1:2){
    if (!require("gdistance", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("gdistance", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("rgeos", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgeos", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("SpatialTools", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("SpatialTools", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("maptools", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("maptools", lib = paste(scriptPath, "libraries", sep = "/"))
  }
  
  # cost raster
  crasPath <- paste(dirname(outFilePath), "/", strsplit(basename(outFilePath), ".", fixed = T)[[1]][1], "_Kostenraster.tif", sep = "") # crasPath <- "C:/HochschuleBochum/Daten/TestFolder/costRasEmpty.asc"
  
  # create cost raster
  source(paste(scriptPath, "createCostRaster.r", sep = "/"))
  costTrans <- createCostRaster(networkLinesPath, resolution = c(costRasCellSize, costRasCellSize), crasPath, scriptPath)

  
  # create output object
  out <- fromPoints
  frColN <- colnames(out@data)[1]
  out@data <- as.data.frame(out@data[,1])
  colnames(out@data) <- frColN
  
  
  # iterate over each starting point
  for (j in 1:length(toPointsPath)){
    
    thisFile <- toPointsPath[j]
    
    # load destination points (only if there is at least one feature)
    if (ogrInfo(dirname(thisFile), strsplit(basename(thisFile), ".", fixed = T)[[1]][1])$nrows > 0){
      
      toPoints <- readOGR(dirname(thisFile), strsplit(basename(thisFile), ".", fixed = T)[[1]][1])
    
      getVertexCoordinates <- function(so){
        if (class(so) == "SpatialPointsDataFrame"){
          coords <- coordinates(so)
        } else if (class(so) == "SpatialLinesDataFrame"){
          coords <- c()
          lines <- so@lines
          for (l in 1:length(lines)){
            thisLines <- lines[[l]]@Lines
            for (ls in 1:length(thisLines)){
              coords <- rbind(coords, thisLines[[ls]]@coords)
            }
          }
        } else if (class(so) == "SpatialPolygonsDataFrame"){
          coords <- c()
          polys <- so@polygons
          for (p in 1:length(polys)){
            thisPolys <- polys[[p]]@Polygons
            for (ps in 1:length(thisPolys)){
              coords <- rbind(coords, thisPolys[[ps]]@coords)
            }
          }
        }
        return(coords)
      }
      useCoords <- getVertexCoordinates(toPoints)
      toPoints <- SpatialPointsDataFrame(useCoords, as.data.frame(rep(0, nrow(useCoords))))
      
      # add attribute field
      thissplit <- strsplit(basename(thisFile), "_", fixed = T)[[1]]
      thisName <- paste(outFieldPrefix, paste(thissplit[1:(length(thissplit)-1)], collapse = "_"), sep = "")
      thisName <- gsub(x = thisName, pattern = ".shp", replacement = "")
      out@data <- cbind(out@data, numeric(nrow(out@data)))
      colnames(out@data)[ncol(out@data)] <- thisName
      
      # calculate travel cost
      costs <- accCost(costTrans, toPoints)
      
      # resample to starting points
      ext <- extent(out)
      proj <- CRS(proj4string(out))
      ras <- raster(resolution = c(gridCellSize, gridCellSize), ext = ext, crs = proj)
      values(ras) <- NA
      pos <- which(values(costs) == Inf)
      if (length(pos) > 0) values(costs)[pos] <- NA
      outRas <- resample(costs, ras)
      
      
      # estimate travel distance
      out@data[,ncol(out@data)] <- values(outRas)
      
      # correct for grid cells which intersect target features
      inters <- raster::intersect(out, toPoints)
      inters_pos <- which(is.na(over(out, inters)[,1]) == F)
      if (length(inters_pos) > 0) out@data[inters_pos, ncol(out@data)] <- 0
      
      
    }
  }
  
  
  # write to file
  writeOGR(out, dsn = dirname(outFilePath), layer = strsplit(basename(outFilePath), ".", fixed = T)[[1]][1],
           driver = 'ESRI Shapefile', overwrite_layer = T)
  
  # copy projection file
  file.copy(from = paste(strsplit(fromPointsPath, ".shp", fixed = T)[[1]][1], ".prj", sep = ""),
            to = paste(strsplit(outFilePath, ".shp", fixed = T)[[1]][1], ".prj", sep = ""), overwrite = T)

}
