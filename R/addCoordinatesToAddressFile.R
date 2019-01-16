# addCoordinatesToAddressFile.r
# Adds x- and y-coordinates to address table

# get input arguments
args <- commandArgs()
inTable <- args[5]
misAddPos <- args[6]
xCoords <- args[7]
yCoords <- args[8]
geocodeMethod <- args[9]


if (misAddPos == "inFile"){
  misAddPos <- read.table(paste(dirname(inTable), "temp_misAddPos.csv", sep = "/"), sep = ";", dec = ".", as.is = T, header = F)
  misAddPos <- as.numeric(misAddPos)
  xCoords <- read.table(paste(dirname(inTable), "temp_xCoords.csv", sep = "/"), sep = ";", dec = ".", as.is = T, header = F)
  xCoords <- as.numeric(xCoords)
  yCoords <- read.table(paste(dirname(inTable), "temp_yCoords.csv", sep = "/"), sep = ";", dec = ".", as.is = T, header = F)
  yCoords <- as.numeric(yCoords)
} else {


  # convert coordinate data format
  xCoords <- strsplit(xCoords, ",", fixed = T)[[1]]
  xCoords <- gsub(x = xCoords, pattern = "\\[", replacement = "")
  xCoords <- gsub(x = xCoords, pattern = "\\]", replacement = "")
  xCoords <- gsub(x = xCoords, pattern = " ", replacement = "")
  xCoords <- as.numeric(xCoords)
  yCoords <- strsplit(yCoords, ",", fixed = T)[[1]]
  yCoords <- gsub(x = yCoords, pattern = "\\[", replacement = "")
  yCoords <- gsub(x = yCoords, pattern = "\\]", replacement = "")
  yCoords <- gsub(x = yCoords, pattern = " ", replacement = "")
  yCoords <- as.numeric(yCoords)
  misAddPos <- strsplit(misAddPos, ",", fixed = T)[[1]]
  misAddPos <- gsub(x = misAddPos, pattern = "\\[", replacement = "")
  misAddPos <- gsub(x = misAddPos, pattern = "\\]", replacement = "")
  misAddPos <- gsub(x = misAddPos, pattern = " ", replacement = "")
  misAddPos <- as.numeric(misAddPos)

}
  
useX <- numeric()
useY <- numeric()
usePos <- numeric()
for (a in 1:length(xCoords)){
  if (all((is.na(xCoords[a]) == F), (is.na(yCoords[a]) == F), (is.na(misAddPos[a]) == F))){
    useX <- c(useX, xCoords[a])
    useY <- c(useY, yCoords[a])
    usePos <- c(usePos, misAddPos[a])
  }
}
xCoords <- useX
yCoords <- useY
misAddPos <- usePos

if (length(xCoords) > 0){

  # read data
  dat <- read.table(inTable, header = T, sep = ";", dec = ".")
  dat <- dat[misAddPos,]
  
  # append data table
  dat$xCoords <- xCoords
  dat$yCoords <- yCoords
  dat$geoSource <- paste("geocodedFrom_", geocodeMethod, "_", 1:nrow(dat), sep = "")
  
  # write missing addresses to file
  write.table(dat, file = paste(dirname(inTable), "addressDataPlusCoordinates.csv", sep = "/"), sep = ";", dec = ".", row.name = F)

}
  
# report to ArcGIS
print ("...completed execution of R script")
