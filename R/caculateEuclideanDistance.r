# caculateEuclideanDistance.r

args <- commandArgs()
provDat <- args[5]
modelDataName <- args[6]
scriptPath <- args[7]

# prepare input
provDat <- gsub(provDat, pattern = "\\\\", replacement = "/")
scriptPath <- gsub(scriptPath, pattern = "\\\\", replacement = "/")


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("sp", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("sp", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("raster", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("raster", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rgeos", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgeos", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("gdistance", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("gdistance", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("data.table", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("data.table", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rlist", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rlist", lib = paste(scriptPath, "libraries", sep = "/"))
}


# load information on which targets to be used
lib <- read.csv2(paste(scriptPath, "/LayerNamen.csv", sep = ""), as.is = T)
shps <- lib[which(lib[,"calcEucDist"]==1), "path"]


# load grid
gridPath <- paste(provDat, "/", modelDataName, "/", "AnalysenErgebnisse/Gitter.shp", sep = "")
grid <- readOGR(dirname(gridPath), strsplit(basename(gridPath), ".", fixed = T)[[1]][1])

# load raster
rasPath <- paste(provDat, "/", modelDataName, "/", "AnalysenErgebnisse/Gitter_raster.tif", sep = "")
ras <- raster(rasPath)
# values(ras) <- res(ras)[1]
values(ras) <- 1

# create transition raster
trans <- transition(ras, mean, 8)

t <- 1

# define function for vertex coordinates extraction
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


# iterate over each shapefile
for (shp in shps){
  
  print (paste("Processing file ", t, "/", length(shps), sep = ""))
  
  canRead <- F
  try({
    nFeat <- ogrInfo(path.expand(dirname(paste(provDat, "/", modelDataName, "/", shp, sep = ""))), strsplit(basename(paste(provDat, "/", modelDataName, "/", shp, sep = "")), ".", fixed = T)[[1]][1])[1]
    canRead <- T
  }, silent = T)
    
  if (canRead == T){
    if (nFeat > 0){
      
      # add data column
      grid@data <- cbind(grid@data, NA)
      colnames(grid@data)[ncol(grid@data)] <- paste("d", paste(strsplit(strsplit(shp, "/", fixed = T)[[1]][length(strsplit(shp, "/", fixed = T)[[1]])], "_", fixed = T)[[1]][1:2], collapse = "_"), sep = "")
          
      # load source locations
      so <- readOGR(dirname(paste(provDat, "/", modelDataName, "/", shp, sep = "")), strsplit(basename(paste(provDat, "/", modelDataName, "/", shp, sep = "")), ".", fixed = T)[[1]][1])
          
      # get coordinates
      coords <- getVertexCoordinates(so)
      
      
      # calculate distances
      thisRes <- accCost(trans, coords[,1:2])
      addVals <- values(thisRes) * res(ras)[1]
      grid@data[,ncol(grid@data)] <- addVals
      
      # correct for grid cells which intersect target features
      inters <- raster::intersect(grid, so)
      inters_pos <- which(is.na(over(grid, inters)[,1]) == F)
      if (length(inters_pos) > 0) grid@data[inters_pos, ncol(grid@data)] <- 0
        
    }
  
  }  

  t <- t + 1
  
}


# write to file
outgridPath <- paste(provDat, "/", modelDataName, "/", "AnalysenErgebnisse/LuftlinienDistanzen.shp", sep = "")
writeOGR(grid, dsn = dirname(outgridPath), layer = strsplit(basename(outgridPath), ".", fixed = T)[[1]][1],
         driver = 'ESRI Shapefile', overwrite_layer = T)
