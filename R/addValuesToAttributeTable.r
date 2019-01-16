# addValuesToAttributeTable.r

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
lib <- read.table(paste(modDataDirPath, "use_spatialImport_All.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)
atstr <- read.table(paste(rScriptPath, "attributeStructure.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)

# extract information from data source table
thisTo <- libgeom[thisLine, which(names(lib) == "inPath")]


# read .dbf-tables
fromTab <- read.dbf(paste(strsplit(thisFrom, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
toTab <- read.dbf(paste(strsplit(thisTo, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)


if (nrow(toTab) > 0){

  # add data source
  sourceName <- libgeom[thisLine, which(names(libgeom) == "Quelle")]
  toTab[which(is.na(toTab[,which(names(toTab) == "Quelle")])), which(names(toTab) == "Quelle")] <- sourceName
  
  
  # get rows for additional information on this fromFile-toFile combination
  origFrom <- libgeom[thisLine,which(names(lib) == "outPath")]
  allThisTo <- which(lib[,which(names(lib) == "inPath")] == thisTo)
  allThisFrom <- which(lib[,which(names(lib) == "outPath")] == origFrom)
  
  addLines <- intersect(allThisTo, allThisFrom)
  
  
  # loop over each additional information row in the data source table
  for (i in addLines){
    
    # get field name information
    inFieldName <- lib[i,which(names(lib) == "Feld_in")]
    
    
    if (inFieldName != "nurGeometrie"){
  
      fromFieldName <- lib[i,which(names(lib) == "Feld_out")]
      toFieldName <- lib[i,which(names(lib) == "Feld_in")]
      
      # get positions of features in question
      oldIDName <- libgeom[thisLine,which(names(libgeom) == "Out_ID1")]
      outFeats <- fromTab[,which(names(fromTab) == oldIDName)]
      inFeats <- toTab[,which(names(toTab) == "OldID")]
      
      
      
      if (fromFieldName %in% names(fromTab)){
      
        # get fromField entries
        entries <- fromTab[,which(names(fromTab) == fromFieldName)]
        
        # convert data type according to data model specification
        hit <- which(atstr == toFieldName, arr.ind = T)
        if (length(hit) > 0){
          targetType <- atstr[hit[,1], hit[,2] + 1]
          if (targetType == "Double" && class(entries) != "numeric"){
            entries_temp <- as.numeric(as.character(entries))
            if (F %in% is.na(entries_temp)){
              entries <- entries_temp
            } else {
              entries <- rep(NA, times = length(entries))
            }
          }
        }
        
        
        # iterate over each feature
        for (feat in 1:length(outFeats)){
          
          pos <- which(inFeats == outFeats[feat])
          thisOutPos <- which(fromTab[,which(names(fromTab) == "OldID_str")] == outFeats[feat])
          toTab[pos,which(names(toTab) == toFieldName)] <- entries[thisOutPos][1]
          
        }
        
      }
    }
      
    
  }
  
  # ensure field length of string fields
  source(paste(rScriptPath, "setDBFStringFieldLength.r", sep = "/"))
  toTab <- setDBFStringFieldLength(toTab)
  
  write.dbf(toTab, file = paste(strsplit(thisTo, ".", fixed = T)[[1]][1], "dbf", sep = "."))
  
  
}
  
print("...completed execution of R-script")
