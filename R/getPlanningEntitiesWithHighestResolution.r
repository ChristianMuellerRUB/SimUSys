# getPlanningEntitiesWithHighestResolution.r
# Identifies for a number of fields which planning entity with the respective information has the highest resolution

args <- commandArgs()
modelFolder <- args[5]
meanFields <- args[6]
sumFields <- args[7]
noDataValue <- args[8]
rScriptPath <- args[9]

noDataValue <- as.numeric(noDataValue)

# normalize paths
modelFolder <- normalizePath(modelFolder, "/")

# convert fields string to vector
meanFields <- strsplit(meanFields, ";")[[1]]
sumFields <- strsplit(sumFields, ";")[[1]]
allFields <- c(meanFields, sumFields)


# load libraries
options(warn = -1)
library(foreign, quietly = T, warn.conflicts = F)

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(rScriptPath, "libraries", sep = "/"))
}


# get all shapefiles in specified folder
allShpPlan <- list.files(paste(modelFolder, "PlanungsEinheiten", sep = "/"), pattern = "\\.shp$", full.names = T, recursive = T)
allShp <- c(allShpPlan)

# define resolution order
allShp <- allShp[order(basename(allShp))]


# create output matrix
out <- cbind(field = allFields, highestResIn = character(length(allFields)), geometry = character(length(allFields)))


# get geometry info table
datStruc <- read.csv(paste(rScriptPath, "DataStructure.csv", sep = "/"), header = T, dec = ".", sep = ";", stringsAsFactors = F)


# loop over .dbf-tables
for (i in 1:length(allShp)){
  
  print(paste(i, "/", length(allShp), sep = ""))
  thisDbf <- read.dbf(paste(strsplit(allShp[i], ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
  
  # check if respective attribute fields hold information
  for (a in 1:length(allFields)){
    
    print(paste("Field ", a, "/", length(allFields), "...", sep = ""))
    
    fieldPos <- which(names(thisDbf) == allFields[a])
    if (length(fieldPos) > 0){
      
      # extract NA entries
      naPos <- which(is.na(thisDbf[,fieldPos]))
      if (length(naPos) == 0){
        validDbf <- thisDbf
      } else {
        validDbf <- thisDbf[-naPos,]
      }
      if (length(naPos) < nrow(thisDbf)){
  
        # get no data and zero positions
        noDataPos <- which(validDbf[,fieldPos] == noDataValue)
        zeroTextPos <- which(validDbf[,fieldPos] == "0")
        zeroPos <- which(validDbf[,fieldPos] == 0)
        allnoDataPos <- unique(c(noDataPos, zeroTextPos, zeroPos))
        
        # define threshold for containing data
        thr <- 0.7
        if (basename(allShp[i]) == "8000_012_Person.shp") thr <- 0.999
        
        # consider this field to hold information if at least 30 per cent of the features provide information
        if (length(allnoDataPos) / length(thisDbf[,fieldPos]) < thr){
            
            out[a,2] <- allShp[i]
            
            # get respective geometry
            temp_split <- strsplit(basename(allShp[i]), "_", fixed = T)[[1]]
            out[a,3] <- datStruc[which(datStruc[,4] == paste(temp_split[1], temp_split[2], sep = "_")),6]
            
        }
  
      }
    }
  }
  
}



# sort table by shapefiles
shp <- unique(out[,2])
shp <- shp[which(shp != "")]
shp <- sort(shp)
out_sort <- matrix("", nrow = length(shp), ncol = 3)
colnames(out_sort) <- c("file", "fields", "geometry")
for (i in 1:length(shp)){
  out_sort[i,1] <- shp[i]
  out_sort[i,2] <- paste(out[which(out[,2] == shp[i]),1], collapse = ";") 
  temp_split <- strsplit(basename(shp[i]), "_", fixed = T)[[1]]
  out_sort[i,3] <- datStruc[which(datStruc[,4] == paste(temp_split[1], temp_split[2], sep = "_")),6]
}


# write to .csv-file
write.table(out_sort, file = paste(modelFolder, "highestResAttributes.csv", sep = "/"), sep = ";", dec = ".", row.name = F)


print("...completed execution of R-script")
