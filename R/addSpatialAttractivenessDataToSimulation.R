# addSpatialAttractivenessDataToSimulation.r
# Searches for data about spatial attractiveness and adds it to the model

# get input arguments
args <- commandArgs()
provDat <- args[5]
ModelDataFolderName <- args[6]
scriptPath <- args[7]

# create folder (if necessary)
provDat <- gsub(pattern = "\\", replacement = "/", x = provDat, fixed = T)
outDir <- paste(provDat, "/", ModelDataFolderName, "/", "AnalysenErgebnisse", sep = "")
if (file.exists(outDir) == F) dir.create(outDir)

# search for data on spatial attractiveness
potFiles <- read.table(paste(scriptPath, "/spatialAttractivenessDataPath.csv", sep = ""), as.is = T, sep = ";", dec = ".", header = F)
for (i in 1:nrow(potFiles)){

  for (e in c("CPG", "dbf", "prj", "sbn", "sbx", "shp", "shx")){
    pat <- paste(strsplit(potFiles[i,1], ".", fixed = T)[[1]][1], "\\.", e, sep = "")
    hits <- list.files(provDat, pattern = pat, full.names = T, recursive = T)

    if (length(hits) > 0){

      # copy data
      file.copy(from = hits[1], to = paste(outDir, "/Raumattraktivitaet_punkte", ".", e, sep = ""), overwrite = T)

    }
  }
}
  
# report to ArcGIS
print ("...finished execution of R-Script.")
