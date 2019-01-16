# addAdditionalInformationToAttributeTable.r

args <- commandArgs()
dataPath <- args[5]
modelNamePath <- args[6]
wd <- args[7]
modDataDirPath <- args[8]
scriptPath <- args[9]


# reshape data paths
dataPath <- gsub(pattern = "\\", replacement = "/", x = dataPath, fixed = T)
wd <- gsub(pattern = "\\", replacement = "/", x = wd, fixed = T)


# set working directory
setwd(wd)
if (substring(wd, nchar(wd), nchar(wd)) != "/") wd <- paste(wd, "/", sep = "")

# load libraries
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("parallel", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("parallel", lib = paste(scriptPath, "libraries", sep = "/"))
}



# list all shapefiles in the model data path
allSHP <- list.files(paste(dataPath, modelNamePath, sep = "/"), pattern = "\\.shp$", full.names = T, recursive = T)

# open data source table
lib <- read.table(paste(modDataDirPath, "use_spatialImport_All.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)


# iterate over each shapefile
addInfo <- function(s){
# for (s in 1:length(allSHP)){
  
  .libPaths(paste(scriptPath, "libraries", sep = "/"))
  library(foreign)
  library(rgdal)
  
  
  thisShpPath <- allSHP[s]
  
  
  # send progress to ArcGIS
  print(paste("Processing file ", thisShpPath, " (", as.character(s), "/", as.character(length(allSHP)), ")...", sep = ""))
  
  
  try({
  
    indbf <- paste(strsplit(thisShpPath, ".", fixed = T)[[1]][1], "dbf", sep = ".")  
    dat <- read.dbf(indbf, as.is = T)
      
    if (nrow(dat) > 0){
      
      # add ID
      dat[,which(names(dat) == "Id")] <- 1:nrow(dat)
      dat[,which(names(dat) == "ObjID")] <- 1:nrow(dat)
      
      # get shapefile name
      shpName <- strsplit(basename(thisShpPath), "_")[[1]][length(strsplit(basename(thisShpPath), "_")[[1]])]
      
      # get according row in data source table
      pos <- which(lib[,which(names(lib) == "file_in")] == shpName)[1]
      
      # fill in data
      dat[,which(names(dat) == "ObjAB"):which(names(dat) == "ObjArtN")] <- lib[pos,which(names(lib) == "ObjAB"):which(names(lib) == "ObjArtN")]
      
      
      # if the geometry is point, fill in coordinate information
      if (is.na(lib[pos,which(names(lib) == "Geometrie")] == "Point") == F){  
        if (lib[pos,which(names(lib) == "Geometrie")] == "Point"){
    
          dat[,which(names(dat) == "coords_x1"):which(names(dat) == "coords_x3")] <-  coordinates(thisShp)
          dat[,which(names(dat) == "KooN"):which(names(dat) == "KooE")] <-  coordinates(thisShp)[,1:2]
          
        }
      
      
        # ensure field length of string fields
        source(paste(wd, "setDBFStringFieldLength.r", sep = "/"))
        dat <- setDBFStringFieldLength(dat)
        
        
        # write updated attribute table to file
        write.dbf(dat, file = paste(strsplit(thisShpPath, ".", fixed = T)[[1]][1], "dbf", sep = "."))
        
      }
      
      # rm(thisShp)
    
    }
    
  }, silent = T)
}

# prepare multicore processing
nUseCores <- detectCores() - 0
if (nUseCores == 0) nUseCores <- 1
cl <- makePSOCKcluster(nUseCores)
clusterExport(cl, ls(), envir = .GlobalEnv)

# execute multicore processing
parLapply(cl = cl, X = 1:length(allSHP), fun = addInfo)

# close multicore processing
stopCluster(cl)


print("...completed execution of R-script")
