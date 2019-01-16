# mergeAllInputs.r
# Combines multiple shapefiles
# christian1.mueller@hs-bochum.de

# get input arguments
args <- commandArgs()
full_inputs <- args[5]
full_output <- args[6]
scriptPath <- args[7]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
}


# prepare input
prepareDataPath <- function(x){
  x <- gsub(x, pattern = "\\\\", replacement = "/")
  x <- gsub(x, pattern = "//", replacement = "/")
  x <- gsub(x, pattern = "'", replacement = "")
  if (substr(x, 1, 1) == "[") x <- substr(x, 2, nchar(x))
  if (substr(x, nchar(x), nchar(x)) == "]") x <- substr(x, 1, nchar(x)-1)
  x <- unlist(strsplit(x, ", ", fixed = T))
}
full_inputs <- prepareDataPath(full_inputs)
full_output <- prepareDataPath(full_output)

# process inputs
for (i in 1:length(full_inputs)){
  
  # load file
  shp <- readOGR(dirname(full_inputs[i]), strsplit(basename(full_inputs[i]), ".", fixed = T)[[1]][1])
  
  # add to output
  if (i == 1){
    outs <- shp
  } else {
    
    # change unique ID field
    shp <- spChFIDs(shp, paste(strsplit(basename(full_inputs[i]), ".", fixed = T)[[1]][1], row.names(shp), sep="."))
    
    # prepare attribute tables
    allCols <- c(colnames(outs@data), colnames(shp@data))
    addCols <- allCols[which(allCols %in% colnames(outs@data) == F)]
    if (length(addCols) > 0){
      for (c in 1:length(addCols)){
        outs@data <- cbind(outs@data, NA)
        colnames(outs@data)[ncol(outs@data)] <- addCols[c]
      }
    }
    addCols <- allCols[which(allCols %in% colnames(shp@data) == F)]
    if (length(addCols) > 0){
      for (c in 1:length(addCols)){
        shp@data <- cbind(shp@data, NA)
        colnames(shp@data)[ncol(shp@data)] <- addCols[c]
      }
    }
    outs@data <- outs@data[,order(colnames(outs@data))]
    shp@data <- shp@data[,order(colnames(shp@data))]
    
    
    # add data
    outs <- rbind(outs, shp)
  }
  
}

# write to file
writeOGR(outs, dsn = dirname(full_output), layer = strsplit(basename(full_output), ".", fixed = T)[[1]][1],
         driver = 'ESRI Shapefile', overwrite_layer = T)



# clean up working directory
rm(list=ls())

# report to ArcGIS
print ("...finished execution of R-Script.")
