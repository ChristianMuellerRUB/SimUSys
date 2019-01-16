# calculateNumberOfCitizensFromFemalesAndMales.r

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

# get highest resolution data on number of citizens
higRes <- read.table(paste(modFolder, "highestResAttributes.csv", sep = "/"), sep = ";", dec = ".", header = T, as.is = T)
calcFromFM <- F
if (("NEinw" %in% strsplit(rev(higRes[,2]), ";", fixed = T)[[1]]) == F){
  for (i in 1:nrow(higRes)){
    if (("Gesch_F" %in% strsplit(rev(higRes[i,2]), ";", fixed = T)[[1]]) && ("Gesch_M" %in% strsplit(rev(higRes[i,2]), ";", fixed = T)[[1]])){
      calcFromFM <- T
      higRes[i,2] <- paste0(higRes[i,2], ";NEinw")
    }
  }
}
useThisFile <- ""
i <- 1
while(useThisFile == ""){
  if ("NEinw" %in% strsplit(rev(higRes[,2])[i], ";", fixed = T)[[1]]){
    useThisFile <- rev(higRes[,1])[i]
  }
  i <- i + 1
}

if (calcFromFM){
  indbf <- paste(strsplit(useThisFile, ".", fixed = T)[[1]][1], "dbf", sep = ".")  
  dat <- read.dbf(indbf, as.is = T)
  dat[,"NEinw"] <- dat[,"Gesch_F"] + dat[,"Gesch_M"]


  # write .dbf to file
  write.dbf(dat, file = indbf)
  
  # write updated highest resolution file
  write.table(higRes, file = paste(modFolder, "highestResAttributes.csv", sep = "/"), sep = ";", dec = ".", row.name = F)
    
}

# report to ArcGIS
print ("...finished execution of R-Script.")
