# popDataToShapefile.r
# Create a point feature for every citizen based on location given in an extra shapefile 

# input from python
args <- commandArgs()
popTable <- args[5]
IDFieldpop <- args[6]
IDFieldloc <- args[8]
outSuffix <- args[9]
outFilePath <- args[10]
rScriptPath <- args[11]

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(rScriptPath, "libraries", sep = "/"))
}



# load population data
popdat <- read.table(popTable, sep = ";", dec = ".", header = T, as.is = T)

# load location file
locdat <- readOGR(dirname(locShp), strsplit(basename(locShp), ".", fixed = T)[[1]][1])

# create coordinates container
coords <- matrix(NA, nrow = 0, ncol = 2)

# create attribute table container
outdat <- data.frame()

# create container for not found addresses
notfound <- c()

# prepare container for all coordinates
allCoords <- c()

# prepare container for geocoding sources
geoS <- c()
geoSall <- c()

# prepare population data
rem <- which(colnames(popdat) == "coords.x1")
if (length(rem) > 0) popdat <- popdat[,-rem]
rem <- which(colnames(popdat) == "coords.x2")
if (length(rem) > 0) popdat <- popdat[,-rem]
rem <- which(colnames(popdat) == "geoSource")
if (length(rem) > 0) popdat <- popdat[,-rem]


# get all unique address IDs
uniAdd <- unique(popdat[,IDFieldpop])

# loop over each address entry in population data
for (i in 1:length(uniAdd)){
  
  # get positions in population data table for this address
  thisPopPos <- which(popdat[,IDFieldpop] == uniAdd[i])
  
  # find matching location in location shapefile
  pos <- which(as.character(locdat@data[,IDFieldloc]) == uniAdd[i])[1]
  
  if (is.na(pos) == F){
  
    # save coordinates
    newcoords <- cbind(coords.x1 = rep(coordinates(locdat)[pos,][1], times = length(thisPopPos)),
                 coords.x2 = rep(coordinates(locdat)[pos,][2], times = length(thisPopPos)))
    coords <- rbind(coords, newcoords)
    
    # save attributes
    outdat <- rbind(outdat, popdat[thisPopPos,])
    
    # save geocoding source
    geoS <- c(geoS, rep(as.character(locdat@data[pos,"geoSource"]), times = length(thisPopPos)))
    geoSall <- c(geoSall, rep(as.character(locdat@data[pos,"geoSource"]), times = length(thisPopPos)))
    
    
  } else {
    
    # save not found addresses
    notfound <- c(notfound, uniAdd[i])
    newcoords <- cbind(coords.x1 = rep(NA, times = length(thisPopPos)),
                       coords.x2 = rep(NA, times = length(thisPopPos)))
    
    # save geocoding source
    geoSall <- c(geoSall, rep(NA, times = length(thisPopPos)))
    
  }
  
  # collect all coordinates
  allCoords <- rbind(allCoords, newcoords)
  
}

# set rownames to NULL
rownames(allCoords) <- NULL
rownames(coords) <- NULL
rownames(geoS) <- NULL
rownames(geoSall) <- NULL

# write coordinates to population table
if (all((colnames(allCoords) %in% colnames(popdat)) == F)){
  popdat <- cbind(popdat, allCoords)
}
if (all((colnames(geoSall) %in% colnames(popdat)) == F)){
  popdat <- cbind(popdat, geoSall)
  colnames(popdat)[ncol(popdat)] <- "geoSource"
}
write.table(popdat, file = popTable, sep = ";", dec = ".", col.names = T, row.names = F)
  

# write not found addresses to file
write.table(unique(notfound), file = paste(dirname(outFilePath), "notfoundAddressesForPersons.csv", sep = "/"), sep = ";", dec = ".", col.names = T, row.names = F)

# create spatial object
proj <- proj4string(locdat)
if (all((colnames(coords) %in% colnames(outdat)) == F)){
  outdat <- cbind(outdat, coords)
}
if (all((colnames(geoS) %in% colnames(outdat)) == F)){
  outdat <- cbind(outdat, geoS)
  colnames(outdat)[ncol(outdat)] <- "geoSource"
}
outsp <- SpatialPointsDataFrame(coords = coords, data = outdat, proj4string = CRS(proj))

# write spatial object to file
writeOGR(outsp, dirname(outFilePath), strsplit(basename(outFilePath), ".", fixed = T)[[1]][1],
         driver = "ESRI Shapefile", overwrite_layer = T)
file.copy(from = paste(strsplit(locShp, ".shp", fixed = T)[[1]][1], ".prj", sep = ""),
          to = paste(strsplit(outFilePath, ".shp", fixed = T)[[1]][1], ".prj", sep = ""),
          overwrite = T)


print("...completed execution of R-script")

