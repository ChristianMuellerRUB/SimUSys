# extractOnlyGeometryAddDataTypes.r
# This Script extracts geometry data which should be imported into the simulation


# input from python
args <- commandArgs()
provDat <- args[5]
modelDataPath <- args[6]
wd <- args[7]

# end user input

# define model data directory
modDataDirPath = paste(provDat, modelDataPath, sep = "/")

# end user input


setwd(wd)

importTab <- read.table(paste(modDataDirPath, "use_spatialImport_All.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)

# handle NAs due to mixed up data mode
napos <- which(is.na(importTab), arr.ind = T)
for (c in unique(napos[,2])){
  importTab[,c] <- as.character(importTab[,c])
  importTab[which(is.na(importTab[,c])), c] <- ""
}


newTable <- importTab[which(importTab[,which(names(importTab) == "Feld_in")] == "nurGeometrie"),]


# sort table by outPath in order to process preprocess input files only once (later on the workflow)
ord <- order(newTable[,which(names(newTable) == "outPath")])
newTable <- newTable[ord,]


write.table(newTable, file = paste(modDataDirPath, "use_spatialImport.csv", sep = "/"), sep = ";", dec = ".", row.name = F)


print("...done with R-Script 'SearchData.r'")