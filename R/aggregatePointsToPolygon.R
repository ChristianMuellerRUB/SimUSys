# aggregatePointsToPolygon.r

# select shapefiles and output shapefile path
args <- commandArgs()
pointShp <- args[5]
polygonShp <- args[6]
meanFields <- args[7]
sumFields <- args[8]
outShp <- args[9]
rScriptPath <- args[10]
fieldsOrig <- args[11]
noDataValue <- args[12]


# prepare inputs
meanFields <- strsplit(meanFields, ";")[[1]]
sumFields <- strsplit(sumFields, ";")[[1]]
allFields <- c(meanFields, sumFields)
fieldsOrig <- strsplit(fieldsOrig, ";")[[1]]
noDataValue <- as.numeric(noDataValue)


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(rScriptPath, "libraries", sep = "/"))
  if (!require("maptools", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("maptools", lib = paste(rScriptPath, "libraries", sep = "/"))
}

# load shapefiles
polys <- readOGR(dirname(polygonShp), strsplit(basename(polygonShp), ".", fixed = T)[[1]][1])
points <- readOGR(dirname(pointShp), strsplit(basename(pointShp), ".", fixed = T)[[1]][1])
pointsDat <- points@data


# spatial querry for selected values
within <- over(points, polys)
within$point_ID <- 1:nrow(within)


# get data positions
meanPos <- which(colnames(pointsDat) %in% meanFields)
sumPos <- which(colnames(pointsDat) %in% sumFields)
allPos <- c(meanPos, sumPos)


# create new attribute fields
for (f in 1:length(allPos)){
  thisName <- colnames(pointsDat)[allPos][f]
  if (thisName %in% fieldsOrig){
    if ((thisName %in% colnames(polys@data)) == F){
      polys@data <- cbind(polys@data, numeric(nrow(polys@data)))
      colnames(polys@data)[ncol(polys@data)] <- thisName
      polys@data[ncol(polys@data)] <- noDataValue
    }
  }
}

# define used fields
allFields <- allFields[which(allFields %in% fieldsOrig)]


# iterate over each grid cell
gridIDs <- unique(within[,1])
naPos <- which(is.na(gridIDs))
if (length(naPos) > 0) gridIDs <- gridIDs[-naPos]

for (i in 1:length(gridIDs)){
  
  thisID <- gridIDs[i]
  thisToRow <- which(polys@data[,1] == thisID)
  thisFromRows <- within[which(within[,1] == thisID),2]
  
  for (c in 1:length(allFields)){
    
    thisField <- allFields[c]
    
    if (thisField %in% colnames(pointsDat)){
    
      # reset no data values
      noDatPos <- which(pointsDat[,which(colnames(pointsDat) == thisField)] == noDataValue)
      if (length(noDatPos) > 0) pointsDat[noDatPos, which(colnames(pointsDat) == thisField)] <- NA
    
      # calculate values
      if (thisField %in% meanFields) polys@data[thisToRow, which(colnames(polys@data) == thisField)] <- mean(pointsDat[thisFromRows, which(colnames(pointsDat) == thisField)], na.rm = T)
      if (thisField %in% sumFields){
        theseVals <- pointsDat[thisFromRows, which(colnames(pointsDat) == thisField)]
        if (class(theseVals) == "factor") theseVals <- as.numeric(as.character(theseVals))
        polys@data[thisToRow, which(colnames(polys@data) == thisField)] <- sum(theseVals, na.rm = T)
      }
      
      # reset no data values
      if (is.na(polys@data[thisToRow, which(colnames(polys@data) == thisField)])) polys@data[thisToRow, which(colnames(polys@data) == thisField)] <- noDataValue
      
    }
  }
}

# calculate total citizen number from gender counts if necessary
if ("NEinw" %in% allFields){
  if (("NEinw" %in% colnames(polys@data)) == F) {
    polys@data <- cbind(polys@data, NEinw = polys@data[,which(colnames(polys@data) == "Gesch_F")] + polys@data[,which(colnames(polys@data) == "Gesch_M")])
  } else {
    if (all(polys@data[,which(colnames(polys@data) == "NEinw")] == 0)) polys@data[,which(colnames(polys@data) == "NEinw")] <- polys@data[,which(colnames(polys@data) == "Gesch_F")] + polys@data[,which(colnames(polys@data) == "Gesch_M")]
  }
}

# write shapefile
writeSpatialShape(x = polys, fn = outShp)

# report to ArcGIS
print ("...finished execution of R-Script.")
