# removeSelfReferingFromImportList.r

# Removes self refering entries from data import list

# get input arguments
args <- commandArgs()
provDat <- args[5]
ModelDataFolderName <- args[6]
rScript <- args[7]

# read data import list
csvPath <- paste(provDat, "\\", ModelDataFolderName, "\\use_spatialImport.csv", sep = "")
dat <- read.csv2(csvPath, as.is = T)

# go through all lines
targetPath <- paste(provDat, ModelDataFolderName, sep = "\\")
targetPath <- gsub(targetPath, pattern = "\\\\", replacement = "/")
self <- c()
for (i in 1:nrow(dat)){
  if (is.na(pmatch(targetPath, dat[i,"outPath"])) == F) self <- c(self, i)
}
if (length(self) > 0){
  out <- dat[-self,]
  
  # write to file
  write.table(out, file = csvPath, sep = ";", dec = ".", row.name = F)

}
  
# report to ArcGIS
print ("...finished execution of R-Script.")
