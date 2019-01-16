# joinMultipleAttributeTablesToOneShapefile.r

args <- commandArgs()
toShp <- args[5]
toJoinField <- args[6]
fromShps <- args[7]
fromJoinFields <- args[8]
rScriptPath <- args[9]
noDataValue <- args[10]


# prepare inputs
noDataValue <- as.numeric(noDataValue)
source(paste(rScriptPath, "pythonListToRVector.r", sep = "/"))
fromShps <- pythonListToRVector(fromShps)

# replicate from join field names if it is not specified for each from join file
if (length(fromJoinFields) < length(fromShps)) fromJoinFields <- rep(fromJoinFields, length(fromShps))


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(rScriptPath, "libraries", sep = "/"))
}
library(foreign, quietly = T, warn.conflicts = F)

# read .dbf-table
toDat <- read.dbf(paste(strsplit(toShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
toPos <- which(colnames(toDat) == toJoinField)


if (length(toPos) > 0){

  for (i in 1:length(fromShps)){
    
    thisFrom <- fromShps[i]
    
    # open from attribute table
    fromDat <- read.dbf(paste(strsplit(thisFrom, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
    fromPos <- which(colnames(fromDat) == fromJoinFields[i])
    
    
    # continue if join field exists
    if (length(fromPos) > 0){
      
      
      # create empty data container
      addData <- matrix(noDataValue, nrow = nrow(toDat), ncol = ncol(fromDat) - 1,
                        dimnames = list(1:nrow(toDat), colnames(fromDat)[-fromPos]))
      
      # add data
      for (c in 1:nrow(fromDat)){
        
        thisToRow <- which(toDat[,toPos] == fromDat[c,fromPos])
        addData[thisToRow,] <- as.numeric(fromDat[c,-fromPos])
        
      }
      
      # add data to attribute table
      toDat <- cbind(toDat, addData)
      
    }
  
  }
    
  
  # delete old ID field
  IDPos <- which(colnames(toDat) == "SP_ID")
  if (length(IDPos) > 0) toDat <- toDat[,-IDPos]
  
  
  # write attribute table
  write.dbf(toDat, file = paste(strsplit(toShp, ".", fixed = T)[[1]][1], "dbf", sep = "."))
  
}
  
# send feedback to python
print("...completed execution of R-script")
