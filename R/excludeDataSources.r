# excludeDataSources.r
# This Script excludes data sources if the User has precified these sources to be excluded in the .csv-file


# input from python
args <- commandArgs()
provDat <- args[5]
modelDataPath <- args[6]
wd <- args[7]


setwd(wd)


# define model data directory
modDataDirPath = paste(provDat, modelDataPath, sep = "/")


# create new .csv-file if not yet created for this project
if (file.exists(paste(modDataDirPath, "usedDataSources.csv", sep = "/")) == F){
  file.copy(from = paste(wd, "usedDataSources.csv", sep = "/"), to = paste(modDataDirPath, "usedDataSources.csv", sep = "/"))
}


sourcesTab <- read.table(paste(modDataDirPath, "usedDataSources.csv", sep = "/"), sep = ";", dec = ".", header = F, stringsAsFactors = F)
importTab <- read.table(paste(modDataDirPath, "use_spatialImport.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)

# handle NAs due to mixed up data mode
napos <- which(is.na(importTab), arr.ind = T)
for (c in unique(napos[,2])){
  importTab[,c] <- as.character(importTab[,c])
  importTab[which(is.na(importTab[,c])), c] <- ""
}


# create a new data frame in same style as importTab but without data
newImportTab <- importTab[-(1:length(importTab))]

sourceTabUse <- sourcesTab[which(sourcesTab[,2] == "yes"),]

# for each data source which should be included for the simulation...
for (i in 1:nrow(sourceTabUse)){
  
  # ...add the respective data row to the new table
  newImportTab <- rbind(newImportTab, importTab[which(importTab[,which(names(importTab) == "Quelle")] == sourceTabUse[i,1]),])
}

# sort table by outPath in order to process preprocess input files only once (later on the workflow)
ord <- order(newImportTab[,which(names(newImportTab) == "outPath")])
newImportTab <- newImportTab[ord,]


# write new table to file
write.table(newImportTab, file = paste(modDataDirPath, "use_spatialImport.csv", sep = "/"), sep = ";", dec = ".", row.name = F)


print("...done with R-Script 'SearchData.r'")