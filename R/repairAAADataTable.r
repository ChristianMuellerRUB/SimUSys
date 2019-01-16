# repairAAADataTable.r
# This Script repairs ALKIS and ATKIS attribute fields in order to obtain field names as expected by the standard

# input from python
args <- commandArgs()
dataPath <- args[5]
modelDataPath <- args[6]
rScriptPath <- args[7]


# suppress warnings
options(warn = -1)

# define model data directory
modDataDirPath = paste(dataPath, modelDataPath, sep = "/")


# load library
library(foreign)


# read data source table
lib <- read.table(paste(modDataDirPath, "use_spatialImport_All.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)

# handle NAs due to mixed up data mode
napos <- which(is.na(lib), arr.ind = T)
for (c in unique(napos[,2])){
  lib[,c] <- as.character(lib[,c])
  lib[which(is.na(lib[,c])), c] <- ""
}



# get ALKIS/ATKIS entries
pos <- numeric()
pos <- c(pos, which(lib[,which(names(lib) == "Quelle")] == "ATKIS"))
pos <- c(pos, which(lib[,which(names(lib) == "Quelle")] == "ALKIS"))
pos <- c(pos, which(lib[,which(names(lib) == "Quelle")] == "ATKIS/ALKIS"))
pos <- c(pos, which(lib[,which(names(lib) == "Quelle")] == "ALKIS/ATKIS"))

# get files
AAAfiles <- unique(lib[pos,which(names(lib) == "outPath")])


# read in synonym table
syn <- read.table(paste(rScriptPath, "repairAAADataTable.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)

for (f in 1:length(AAAfiles)){
  
  dat <- read.dbf(paste(strsplit(AAAfiles[f], ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
  allSyns <- which(syn[,1] == basename(AAAfiles[f]))
  
  for (i in 1:length(allSyns)){
    
    if ((length(which(names(dat) == syn[allSyns[i],2])) > 0) == F){
      
      # synonym position
      synPos <- which(substr(names(dat), 1, 10) == substr(syn[allSyns[i],3], 1, 10))
      if (length(synPos) > 0){
        dat <- cbind(dat, dat[,synPos])
        colnames(dat)[ncol(dat)] <- syn[allSyns[i],2]
       
        write.dbf(dat, file = paste(strsplit(AAAfiles[f], ".", fixed = T)[[1]][1], "dbf", sep = "."))
        
      }
      
    }
    
  }
    
}

print("...completed execution of R-script")

