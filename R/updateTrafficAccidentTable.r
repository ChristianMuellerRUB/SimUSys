# updateTrafficAccidentTable.r
# Updates the attribute table of single accidents


# input from python
args <- commandArgs()
modelFolder <- args[5]
rScriptPath <- args[6]



# get all shapefiles in specified folder
allShpPlan <- list.files(paste(modelFolder, "Netzwerke", sep = "/"), pattern = "\\.shp$", full.names = T, recursive = T)
allShp <- c(allShpPlan)
pos <- which(basename(allShp) == "9000_014_Unfall.shp")
if (length(pos) > 0){
  
  shpFile <- allShp[pos]
  
  # load attribute table
  thisDbf <- read.dbf(paste(strsplit(shpFile, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
  
  # update attribute table
  pos <- which(colnames(thisDbf) == "UnfDich")
  thisDbf[,pos] <- 1
  
  # write attribute table to file
  write.dbf(thisDbf, file = paste(strsplit(shpFile, ".", fixed = T)[[1]][1], "dbf", sep = "."))
  
}

print("...completed execution of R-script")
