# convertOldIDFieldToString.r
# Checks whether or not OldID-Field is string and converts it to string if this is not the case

# input from python
args <- commandArgs()
dataPath <- args[5]
modelDataPath <- args[6]
rScriptPath <- args[7]


# define model data directory
modDataDirPath = paste(dataPath, modelDataPath, sep = "/")


# suppress warnings
options(warn = -1)

# load library
library(foreign)


# read data source table
lib <- read.table(paste(modDataDirPath, "use_spatialImport.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)

# handle NAs due to mixed up data mode
napos <- which(is.na(lib), arr.ind = T)
for (c in unique(napos[,2])){
  lib[,c] <- as.character(lib[,c])
  lib[which(is.na(lib[,c])), c] <- ""
}


# get files
allFromFiles <- unique(lib[,which(names(lib) == "outPath")])


# iterate over each file
for (i in 1:length(allFromFiles)){
  
  thisFile <- allFromFiles[i]
  
  cat("\n")
  cat(paste0("Processing ", thisFile, "...(", i, "/", length(allFromFiles), ")"))
  
  # read attribute table
  dat <- read.dbf(paste(strsplit(thisFile, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
  
  if (nrow(dat) > 0){
  
    # get requiered OldID field name
    allFitRows <- which(lib[,which(names(lib) == "outPath")] == thisFile)
    
    for (j in 1:length(allFitRows)){ 
      thisRow <- allFitRows[j]
      thisColumn <- which(names(lib) == "Out_ID1" )[1]
      reqFieldName <- lib[thisRow, thisColumn]
    
      # check if requiered field name is of requiered data type "string/character"
      pos <- which(names(dat) == reqFieldName)

        newEntries <- paste(strsplit(basename(lib[thisRow,which(names(lib) == "outPath")]), ".", fixed = T)[[1]][1], 1:nrow(dat), sep = "_")
        
        # add new ID entries as string
        dat <- data.frame(dat, newEntries)
        dat[,ncol(dat)] <- newEntries
          
        # add new field name
        names(dat)[length(names(dat))] <- "OldID_str"
          
        # delete old ID-field if necessary
        allPos <- which(names(dat) == "OldID_str")
        keepPos <- which(allPos == allPos[length(allPos)])
        deletePos <- allPos[-keepPos]
        if (length(deletePos > 0)) dat <- dat[,-deletePos]
          
        # write updated attribute table to file
        write.dbf(dat, file = paste(strsplit(thisFile, ".", fixed = T)[[1]][1], "dbf", sep = "."))
          
        # update data source table
        lib[thisRow,thisColumn] <- "OldID_str"
        
      # }
    }
  }
  
}

# write updated data source table to file
write.table(lib, file = paste(modDataDirPath, "use_spatialImport.csv", sep = "/"), sep = ";", dec = ".", row.name = F)

print("...completed execution of R-script")

