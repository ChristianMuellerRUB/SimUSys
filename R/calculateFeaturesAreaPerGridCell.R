# calculateFeaturesAreaPerGridCell.r
# Calculates the total area size of all features in a analysis grid cell

args <- commandArgs()
combinationShape <- args[5]
fieldsOrig <- args[6]
meanFields <- args[7]
sumFields <- args[8]
noDataValue <- args[9]
scriptPath <- args[10]



# convert fields string to vector
clearInput <- function(x){
  x <- strsplit(x, ";")[[1]]
  if (length(x) == 1) x <- strsplit(x, ",")[[1]]
  for (i in 1:length(x)){
    if (substr(x[i], 1, 1) == " ") x[i] <- substr(x[i], 2, nchar(x[i])-1)
    if (substr(x[i], 1, 1) == "[") x[i] <- substr(x[i], 2, nchar(x[i])-1)
    if (substr(x[i], nchar(x[i]), nchar(x[i])) == "]") x[i] <- substr(x[i], 1, nchar(x[i])-1)
    if (substr(x[i], 1, 1) == "'") x[i] <- substr(x[i], 2, nchar(x[i]))
    if (substr(x[i], nchar(x[i]), nchar(x[i])) == "'") x[i] <- substr(x[i], 1, nchar(x[i])-1)
    
  }
  return(x)
}
fieldsOrig <- clearInput(fieldsOrig)
meanFields <- clearInput(meanFields)
sumFields <- clearInput(sumFields)

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}
library(foreign, quietly = T, warn.conflicts = F)


# load attribute table
dat <- read.dbf(paste(strsplit(combinationShape, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)

# copy area size information
for (i in length(colnames(dat)):1){
  thisFrac <- substring(colnames(dat)[i], 1, 4)
  if (thisFrac == "FID_"){
    if (is.na(as.numeric(substring(colnames(dat)[i], 5, 5)))){
      origIDField <- colnames(dat)[i]
    }
  }
}
dat$origFeatA <- 0
featPos <- which(dat[,which(colnames(dat) == origIDField)] != -1)
dat[featPos, which(colnames(dat) == "origFeatA")] <- dat[featPos, which(colnames(dat) == "intArea")]
dat$totFeatA <- 0

# get all grid IDs
gridIDs <- unique(dat[, which(colnames(dat) == "grid_ID")])

# add total area of original features per grid cell
gridTab <- cbind(gridIDs, totFeatA = 0)
for (i in 1:length(gridIDs)){
  thisGridID <- gridTab[i,1]
  thisRows <- which(dat[,which(colnames(dat) == "grid_ID")] == thisGridID)
  gridTab[i,2] <- sum(dat[thisRows, which(colnames(dat) == "origFeatA")])
  toPos <- which(dat[,which(colnames(dat) == "grid_ID")] == thisGridID)
  dat[toPos,which(colnames(dat) == "totFeatA")] <- sum(dat[thisRows, which(colnames(dat) == "origFeatA")])
}



# convert fields string to vector
fieldsOrig <- strsplit(fieldsOrig, ";")[[1]]
meanFields <- strsplit(meanFields, ";")[[1]]
sumFields <- strsplit(sumFields, ";")[[1]]


# calculate weighted fields for mean data
for (i in 1:length(fieldsOrig)){
  thisField <- fieldsOrig[i]
  if (thisField %in% meanFields){
    
    if (length(which(colnames(dat) == thisField) ) > 0){
    
      # calculate value
      dat[,which(colnames(dat) == substring(paste("d", thisField, sep = "_"), 1, 10))] <- as.numeric(dat[,which(colnames(dat) == thisField)]) * dat[,which(colnames(dat) == "intArea")]
      
      # reset no data values
      invalids <- which(dat[,which(colnames(dat) == thisField)] == as.numeric(noDataValue))
      invalids <- c(invalids, which(is.na(dat[,which(colnames(dat) == thisField)])))
      if (length(invalids) > 0) dat[invalids,which(colnames(dat) == substring(paste("d", thisField, sep = "_"), 1, 10))] <- -1
      
    }
  }
}


# write to attribute table file
write.dbf(dat, file = paste(strsplit(combinationShape, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# send feedback to python
print("...completed execution of R-script")
