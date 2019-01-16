# createCostRaster.r
# Creates a cost Raster for network analysis

createCostRaster <- function(networkLinesPath, resolution, crasPath, scriptPath){
  
  print("Loading R-Packages...")
  options(repos = c(CRAN = "http://cran.rstudio.com"))
  .libPaths(paste(scriptPath, "libraries", sep = "/"))
  for (i in 1:2){
    if (!require("gdistance", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("gdistance", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("rgeos", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgeos", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("raster", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("raster", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("plotKML", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("plotKML", lib = paste(scriptPath, "libraries", sep = "/"))
    if (!require("RSAGA", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("RSAGA", lib = paste(scriptPath, "libraries", sep = "/"))
  }
  
  # load transition matrix from saved object if it exists
  obj <- paste(strsplit(crasPath, "_Kostenraster.tif", fixed = T)[[1]][1], "_TransitionObjekt.r", sep = "")
  if (file.exists(obj)) {
    load(obj)
  } else {
  
    if (file.exists(crasPath)){
      
      cras <- raster(crasPath)
      
    } else {
    
      # load shapefiles
      networkLines <- readOGR(dirname(networkLinesPath), strsplit(basename(networkLinesPath), ".", fixed = T)[[1]][1])
      ext <- extent(networkLines)
      proj <- CRS(proj4string(networkLines))
      ras <- raster(resolution = c(costRasCellSize, costRasCellSize), ext = ext, crs = proj)
      values(ras) <- -1
      cras <- rasterize(networkLines, ras, fun = "first")
      writeRaster(cras, file = crasPath, format = "ascii", prj = T)
  
    }
      
    values(cras)[which(is.na(values(cras)) == F)] <- 1
    values(cras)[which(is.na(values(cras)))] <- 0
    costTrans <- transition(cras, transitionFunction = max, 8)
    costTrans <- geoCorrection(costTrans)
    
    # write object to file
    save(costTrans, file = obj)
    
  }
    
  return(costTrans)
  
}