# updateSearchListForCombinedDataSources.r
# Updates the data source list if combined data sources are detected

args <- commandArgs()
dataPath <- args[5]
modName <- args[6]

# prepare input
dataPath <- gsub(dataPath, pattern = "\\\\", replacement = "/")

# read join library CSV
tab <- read.table(paste(dataPath, modName, "use_spatialImport_All.csv", sep = "/"), header = T, sep = ";", dec = ".", as.is = T) 

# iterate over each input path
for (p in 1:nrow(tab)){
  
  # define possible path for combined data file
  combPath <- paste(dirname(tab[p,"outPath"]), "/", strsplit(basename(tab[p,"outPath"]), ".", fixed = T)[[1]][1], "_combined.shp", sep = "")
  
  # overwrite entry if combined file exists
  if (file.exists(combPath)){
    tab[p,"outPath"] <- combPath
    tab[p,"Dateiname_out"] <- paste(strsplit(tab[p,"Dateiname_out"], ".", fixed = T)[[1]][1], "combined.shp", sep = "_")
  }
  
  # define possible path for combined data file
  combPath <- paste(dirname(tab[p,"outPath"]), "/", strsplit(basename(tab[p,"outPath"]), ".", fixed = T)[[1]][1], "_addInf.shp", sep = "")
  
  # overwrite entry if combined file exists
  if (file.exists(combPath)){
    tab[p,"outPath"] <- combPath
    tab[p,"Dateiname_out"] <- paste(strsplit(tab[p,"Dateiname_out"], ".", fixed = T)[[1]][1], "addInf.shp", sep = "_")
  }
  
}

# write to file
write.table(tab, file = paste(dataPath, modName, "use_spatialImport_All.csv", sep = "/"), sep = ";", dec = ".", row.name = F)

# clean up working directory
rm(list=ls())

# report to ArcGIS
print ("...finished execution of R-Script.")
