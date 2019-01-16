# input from python
args <- commandArgs()
provDat <- args[5]
wd <- args[6]

# adjust data paths and set working directory
provDat <- gsub(pattern = "\\", replacement = "/", x = provDat, fixed = T)
wd <- gsub(pattern = "\\", replacement = "/", x = wd, fixed = T)
setwd(wd)
if (substring(wd, nchar(wd), nchar(wd)) != "/") wd <- paste(wd, "/", sep = "")


# read in data source library
lib <- read.table("DataSourceBib.csv", sep = ";", dec = ".", header = T, stringsAsFactors = F)

# get possible study area shapefile names
sNames <- lib[which(lib[,1] == "Untersuchungsgebiet.shp"), 10]

# get priorities
sPrior <- lib[which(lib[,1] == "Untersuchungsgebiet.shp"), 13]

if (length(sNames) > 0){

  # get unique filenames
  if (length(sNames) > 1){
    sNames <- unique(sNames)
  }
  
  # sort names by priority
  sNames <- sNames[order(sPrior)]
  sPrior <- sPrior[order(sPrior)]
  
  # look for data paths
  outPaths <- character()
  for (i in 1:length(sNames)){
    allHits <- list.files(provDat, pattern = paste("\\", sNames[i], "$", sep = ""), full.names = T, recursive = T)
    if (length(allHits) > 0){
      outPaths <- c(outPaths, allHits)
    }
  }
  
  # get unique filepaths
  outPath <- unique(outPaths)
  
  if (length(outPath) > 0){
    write.table(outPath[1], paste(provDat, "studyAreaPath.csv", sep = "/"), sep = ";", dec = ".", row.names = F, col.names =  F)
  }
  
}

print("...completed execution of R script")