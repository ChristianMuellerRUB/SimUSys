# aggregateNumberOfCitizens.r
# Aggregates number of citezens to higher planning entity levels

# select shapefiles and output shapefile path
args <- commandArgs()
modFolder <- args[5]
sumFields <- args[6]
rScriptPath <- args[7]



# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(rScriptPath, "libraries", sep = "/"))
  if (!require("maptools", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("maptools", lib = paste(rScriptPath, "libraries", sep = "/"))
  if (!require("foreign", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(rScriptPath, "libraries", sep = "/"))
  if (!require("raster", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("raster", lib = paste(rScriptPath, "libraries", sep = "/"))
}

sumFields <- strsplit(sumFields, ";", fixed = T)[[1]]

# copy entire folder to backup absoulte values
if (file.exists(paste(modFolder, "/PlanungsEinheiten_absolut", sep = ""))){
  unlink(paste(modFolder, "/PlanungsEinheiten", sep = ""), recursive = T, force = T)
  file.rename(from = paste(modFolder, "/PlanungsEinheiten_absolut", sep = ""), to = paste(modFolder, "/PlanungsEinheiten", sep = ""))
}
dir.create(paste(modFolder, "/PlanungsEinheiten_absolut", sep = ""))
file.copy(from = paste(modFolder, "/PlanungsEinheiten/8000_PlanungsEinheiten/", sep = ""), to = paste(modFolder, "/PlanungsEinheiten_absolut", sep = ""), recursive = T)


# get highest resolution data on number of citizens
higRes <- read.table(paste(modFolder, "highestResAttributes.csv", sep = "/"), sep = ";", dec = ".", header = T, as.is = T)
useThisFile <- ""
i <- 1
while(useThisFile == ""){
  if ("NEinw" %in% strsplit(rev(higRes[,2])[i], ";", fixed = T)[[1]]){
    useThisFile <- rev(higRes[,1])[i]
  }
  i <- i + 1
  if (i > 100) useThisFile <- "noEntityWithPopulationDataFound"
}
hig_sp <- readOGR(dirname(useThisFile), strsplit(basename(useThisFile), ".", fixed = T)[[1]][1])


# iterate over each higher planning entity
for (j in (i-1):nrow(higRes)){
  
  aggThisFile <- rev(higRes[,1])[j]
  agg_sp <- readOGR(dirname(aggThisFile), strsplit(basename(aggThisFile), ".", fixed = T)[[1]][1])
  agg_dat <- agg_sp@data
    
  if (j >= i){
    
    # iterate over each feature
    for (f in 1:nrow(agg_sp@data)){
      agg_dat[f,"NEinw"] <- sum(raster::intersect(agg_sp[f,], hig_sp)@data[,"NEinw.2"], na.omit = T)
    }
    
    # write .dbf to file
    outPath <- paste(paste(dirname(dirname(aggThisFile)), "_absolut", sep = ""), basename(dirname(aggThisFile)), basename(aggThisFile), sep = "/")
    write.dbf(agg_dat, file = paste(strsplit(outPath, ".", fixed = T)[[1]][1], "dbf", sep = "."))
    
  }
  
  
  # calculate relative values
  attPos <- which(colnames(agg_dat) %in% sumFields)
  for (a in 1:length(attPos)){
    if (colnames(agg_dat)[attPos[a]] != "NEinw"){
      agg_dat[,attPos[a]] <- agg_dat[,attPos[a]]/agg_dat[,"NEinw"] * 100
    }
  }
  for (c in 1:ncol(agg_dat)){
    agg_dat[which(is.na(agg_dat[,c])),c] <- 0
    agg_dat[which(agg_dat[,c] == "Inf"),c] <- 0
    agg_dat[which(agg_dat[,c] == "-Inf"),c] <- 0
  }
  
  # write relative values to file
  write.dbf(agg_dat, file = paste(strsplit(aggThisFile, ".", fixed = T)[[1]][1], "dbf", sep = "."))
  
}


# report to ArcGIS
print ("...finished execution of R-Script.")
