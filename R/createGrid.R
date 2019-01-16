# createGrid.r
# Creates a grid shapefile of rectangular cells (similar to rasters)

# get input arguments
args <- commandArgs()
outPath <- args[5]
studyAreaPath <- args[6]
cellSize <- args[7]
scriptPath <- args[8]

# get output file paths
outPath2 <- paste(strsplit(outPath, ".", fixed = T)[[1]][1], "_punkte.shp", sep = "")


# convert data types
cellSize <- as.numeric(cellSize)


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("raster", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("raster", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("osmar", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("osmar", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rgeos", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgeos", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("maptools", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("maptools", lib = paste(scriptPath, "libraries", sep = "/"))
}


# data structure analysis results
if (file.exists(dirname(outPath)) == F) dir.create(dirname(outPath))

# read in study area
studyArea <- readOGR(dirname(studyAreaPath), strsplit(basename(studyAreaPath), ".", fixed = T)[[1]][1])

# define projection
proj <- proj4string(studyArea)

# get study area extent
SAbbox <- as_osmar_bbox(studyArea)


# create raster object
rasObj <- raster(xmn = SAbbox[1], xmx = SAbbox[3], ymn = SAbbox[2], ymx = SAbbox[4],
                 resolution = cellSize)
projection(rasObj) <- proj
values(rasObj) <- 1:(nrow(rasObj) * ncol(rasObj))

# convert raster to polygon
poly <- rasterToPolygons(rasObj)
names(poly@data) <- "grid_ID"

# write polygons to shapefile
if (file.exists(outPath) == F){
  writeOGR(poly, dirname(outPath), strsplit(basename(outPath), ".", fixed = T)[[1]][1],
           driver = "ESRI Shapefile", overwrite_layer = T)
}

# get polygon midpoints
pointCoords <- coordinates(poly)
points <- SpatialPointsDataFrame(coords = pointCoords, data = poly@data, proj4string = CRS(proj))

# write points to shapefile
if (file.exists(outPath2) == F){
  writeOGR(points, dirname(outPath2), strsplit(basename(outPath2), ".", fixed = T)[[1]][1],
           driver = "ESRI Shapefile", overwrite_layer = T)
}

# write raster to file
outPath3 <- paste(dirname(outPath2), "/Gitter_raster.tiff", sep = "")
if (file.exists(outPath3) == F){
  rf <- writeRaster(rasObj, filename = outPath3, format = "GTiff", overwrite=TRUE)
}


# report to ArcGIS
print ("...finished execution of R-Script.")
