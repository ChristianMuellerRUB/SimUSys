# calculateMeansOfFeaturesPerGridCell.r
# Calculates the mean of each feature in a analysis grid cell weighted by its area share of the grid cell

args <- commandArgs()
combinationShape <- args[5]
densityDataField <- args[6]
totAreaField <- args[7]
toField <- args[8]
AreaIntermediateField <- args[9]
AreaGridField <- args[10]
noDataValue <- args[11]
scriptPath <- args[12]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}


# load attribute table
dat <- read.dbf(paste(strsplit(combinationShape, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)


# extract data
AreaGrid <- dat[,AreaGridField]
AreaIntermediate <- dat[,AreaIntermediateField]
densityData <- dat[,densityDataField]
OrigDataField <- substr(substr(densityDataField, 3, nchar(densityDataField)), 1, 8)
OrigDataField <- colnames(dat)[which(substr(colnames(dat), 1, 8) == OrigDataField)]
OrigData <- as.numeric(dat[,OrigDataField])
toFieldPos <- which(colnames(dat) == toField)


# calculate values
dat[, toFieldPos] <- AreaIntermediate/AreaGrid * OrigData

# correct invalid entries
dat[which(is.na(dat[,toFieldPos])), toFieldPos] <- 0

# reset no data values
invalids <- which(dat[, densityDataField] == as.numeric(noDataValue))
if (length(invalids) > 0) dat[invalids, toFieldPos] <- -1


# write to attribute table file
write.dbf(dat, file = paste(strsplit(combinationShape, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# send feedback to python
print("...completed execution of R-script")
