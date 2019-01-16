# Data management
# Renames AAA-shapefiles according to information in the attribute table in order to achieve standard naming
# Christian Mueller, christian1.mueller@hs-bochum.de, Bochum University of Applied Sciences
# requiered packages: foreign

# user input
# aaaFolder <- 'C:\\HochschuleBochum\\Daten\\Herdecke\\ATKIS_rename'
# wd <- "C:\\HochschuleBochum\\CodesScripts\\R"

# input from python
args <- commandArgs()
aaaFolder <- args[5]
wd <- args[6]


# rearrange data paths
aaaFolder <- gsub(pattern = "\\", replacement = "/", x = aaaFolder, fixed = T)
wd <- gsub(pattern = "\\", replacement = "/", x = wd, fixed = T)

# set working directory
setwd(wd)


# load libraries
print("Loading R-packages...")
for (i in 1:2){
  if (!require("foreign")) install.packages("foreign")
}


# read field name information
fieldNames <- read.table("renameAAAData.csv", sep = ";", dec = ".", header = T, stringsAsFactors = F)[,1]


# get all shapefiles in folder
allShp <- list.files(aaaFolder, pattern = "\\.shp$", full.names = T, recursive = T)

for (s in 1:length(allShp)){
  
  thisShp <- allShp[s]
  
  # AAA-Shapefile name should have an '_' as the third symbol (e.g. AX_Strasse.shp)
  if (((substr(basename(thisShp), 3, 3)) == "_") == F){
    
    dbfPath <- paste(strsplit(thisShp, ".", fixed = T)[[1]][1], "dbf", sep = ".")
    dat <- read.dbf(dbfPath, as.is = T)
    
    # match field names with names known to hold information about the standard AAA-naming
    pos <- which(names(dat) %in% fieldNames)[1]
    
    if (is.na(pos) == F){
    
      # get standard name
      newName <- dat[1,pos]
      if (substr(newName, (nchar(newName) - 3), nchar(newName)) != ".shp"){
        newName <- paste(newName, "shp", sep = ".")
      }
      
      # get all files for this shapefile
      allFiles <- list.files(aaaFolder, pattern = strsplit(basename(thisShp), ".", fixed = T)[[1]][1], full.names = T, recursive = T)
      
      # rename all associated files
      for (f in 1:length(allFiles)){
        
        newPath = paste(dirname(allFiles[f]), "/", strsplit(newName, ".", fixed = T)[[1]][1], ".", strsplit(basename(allFiles[f]), ".", fixed = T)[[1]][2], sep = "")
        
        file.rename(from = allFiles[f], to = newPath)
        
      }
      
    
    }
    
  }
  
}
  
print("...completed execution of R-script")
