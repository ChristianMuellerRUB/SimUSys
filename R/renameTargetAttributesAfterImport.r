# renameTargetAttributesAfterImport.r

args <- commandArgs()
modDataDirPath <- args[5]
thisFrom <- args[6]
thisLine <- args[7]
rScriptPath <- args[8]



# reshape data paths
thisFrom <- gsub(pattern = "\\", replacement = "/", x = thisFrom, fixed = T)
rScriptPath <- gsub(pattern = "\\", replacement = "/", x = rScriptPath, fixed = T)

# convert strings to integers
thisLine <- as.numeric(thisLine)


# load libraries
print("Loading R-packages...")
options(warn = -1)
library(foreign, quietly = T, warn.conflicts = F)


# read in data source table
libgeom <- read.table(paste(modDataDirPath, "use_spatialImport.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)
rlib <- read.table(paste(rScriptPath, "renameTargetAttributes.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)

# extract information from data source table
thisTo <- libgeom[thisLine, "inPath"]
thisFile <- strsplit(basename(thisTo), "_", fixed = T)[[1]]
TargetFilename <- thisFile[length(thisFile)]
SourceFilename <- basename(libgeom[thisLine, "outPath"])


# check if for this file attributes are to be renamed
hits <- which(rlib[,"SourceFilename"] == SourceFilename)[which(which(rlib[,"SourceFilename"] == SourceFilename) %in% which(rlib[,"TargetFilename"] == TargetFilename))]

if (length(hits) > 0){
  thisr <- rlib[hits,]
  
  # read .dbf-tables
  toTab <- read.dbf(paste(strsplit(thisTo, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
  
  for(i in 1:nrow(thisr)){
    thisString <- thisr[i,"TargetAttributeOrigin"]
    if (thisString == ""){
      thisPos <- which(is.na(toTab[,thisr[i,"TargetAttributeName"]]))
    } else {
      thisPos <- which(toTab[,thisr[i,"TargetAttributeName"]] == thisString)
    }
    if (length(thisPos) > 0){
      toTab[thisPos,thisr[i,"TargetAttributeName"]] <- thisr[i,"TargetAttributeChanged"]
    }
  }
  
  # ensure field length of string fields
  source(paste(rScriptPath, "setDBFStringFieldLength.r", sep = "/"))
  toTab <- setDBFStringFieldLength(toTab)
  
  write.dbf(toTab, file = paste(strsplit(thisTo, ".", fixed = T)[[1]][1], "dbf", sep = "."))
  
}
  
print("...completed execution of R-script")
