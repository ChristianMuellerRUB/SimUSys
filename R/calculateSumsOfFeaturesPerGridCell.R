# calculateSumsOfFeaturesPerGridCell.r
# Calculates the sum of each feature in a analysis grid cell weighted by its area share of the grid cell

args <- commandArgs()
combinationShape <- args[5]
AreaFromField <- args[6]
AreaGridField <- args[7]
AreaIntermediateField <- args[8]
densityDataField <- args[9]
toField <- args[10]
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
AreaFrom <- dat[,AreaFromField]
AreaGrid <- dat[,AreaGridField]
AreaIntermediate <- dat[,AreaIntermediateField]
densityData <- dat[,densityDataField]
OrigDataField <- substr(substr(densityDataField, 3, nchar(densityDataField)), 1, 8)
OrigDataField <- colnames(dat)[which(substr(colnames(dat), 1, 8) == OrigDataField)]
OrigData <- dat[,OrigDataField]  

# handle no data values
pos <- which(densityData == noDataValue)
if (length(pos) > 0) densityData[pos] <- 0
pos <- which(OrigData == noDataValue)
if (length(pos) > 0) OrigData[pos] <- 0

# get cases
case_small2big <- which(AreaGrid >= AreaFrom)
case_big2small <- which(AreaGrid < AreaFrom)

# handle case 1
dat[case_small2big, toField] <- densityData[case_small2big] * AreaFrom[case_small2big]

# hande case 2
dat[case_big2small, toField] <- AreaIntermediate[case_big2small]/AreaGrid[case_big2small] * OrigData[case_big2small]

# write to attribute table file
write.dbf(dat, file = paste(strsplit(combinationShape, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# send feedback to python
print("...completed execution of R-script")
