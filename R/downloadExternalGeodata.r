# downloadExternalGeodata.r

# input from python
args <- commandArgs()
rScriptPath <- args[5]
dest <- args[6]
studyAreaPath <- args[7]

# load packages
print("Loading R-Packages...")
scriptPath <- gsub(pattern = "\\", replacement = "/", x = rScriptPath, fixed = T)
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
}
require(rgdal, lib.loc = paste(scriptPath, "libraries", sep = "/"))


# get study area
studyArea <- readOGR(dirname(studyAreaPath), strsplit(basename(studyAreaPath), ".", fixed = T)[[1]][1])

# get download list
dlist <- read.table(paste(rScriptPath, "externalDatasourcesToDownload.csv", sep = "/"), dec = ".", sep = ";", header = T, as.is = T)

# define function for download and clipping
handleThisFile <- function(i){
  
  # prepare URL
  thisURL <- dlist[i,1]
  if (substr(thisURL, 1, 4) != "http") thisURL <- paste("http://", thisURL, sep = "")
  
  # prepare destination path
  thisOutPath <- paste(dest, dlist[i,2], sep = "/")
  if (dir.exists(thisOutPath) == F) dir.create(thisOutPath, recursive = T)
  thisFileOut <- strsplit(dlist[i,2], "/", fixed = T)[[1]][length(strsplit(dlist[i,2], "/", fixed = T)[[1]])]
  thisCompleteOutPath <- paste(thisOutPath, "/", thisFileOut, ".zip", sep = "")
  
  # download file
  download.file(thisURL, thisCompleteOutPath)
  
  # unzip data
  allZIP <- list.files(thisOutPath, pattern = "\\.zip$", full.names = T, recursive = T)
  if(length(allZIP) > 0){
    allZIP <- list.files(thisOutPath, pattern = "\\.zip$", full.names = T, recursive = T)
    for (z in 1:length(allZIP)){
      unzip(allZIP[z], exdir = dirname(thisCompleteOutPath))
    }
  }
  
  # get all shapefiles
  allSHP <- list.files(thisOutPath, pattern = "\\.shp$", full.names = T, recursive = T)

  # continue if there are any shapefiles in this folder
  if (length(allSHP) > 0){

    # clip shapefiles to study area
    for (s in 1:length(allSHP)){
      thisShpPath <- allSHP[s]

      # load shapefile
      thisShp <- readOGR(dirname(thisShpPath), strsplit(basename(thisShpPath), ".", fixed = T)[[1]][1])

      # clip
      thisShp <- spTransform(thisShp, studyArea@proj4string)
      try(thisShp_clip <- thisShp[studyArea,], silent = T)

      if ("thisShp_clip" %in% ls()){

        # write to file
        writeOGR(thisShp_clip, dirname(thisShpPath), strsplit(basename(thisShpPath), ".", fixed = T)[[1]][1],
                 driver = "ESRI Shapefile", overwrite_layer = T)

        rm("thisShp_clip")

      }

    }
  }
  
}

# execute download and clipping function with exception handling
for (i in 1:nrow(dlist)){
  try(handleThisFile(i))
}


# feedback to python
print("...completed execution of R-script")
