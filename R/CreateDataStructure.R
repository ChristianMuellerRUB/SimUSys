# createDataStructure.r
# This Script searches provided data for information in order to feed the simulation model


# input from python
args <- commandArgs()
provDat <- args[5]
wd <- args[6]
studyAreaPath <- args[7]
outputFolderName <- args[8]


# end user input

provDat <- gsub(pattern = "\\", replacement = "/", x = provDat, fixed = T)
wd <- gsub(pattern = "\\", replacement = "/", x = wd, fixed = T)


setwd(wd)
wd <- getwd()


# load packages
print("loading packages")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(wd, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("sp", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("sp", lib = paste(wd, "libraries", sep = "/"))
  if (!require("raster", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("raster", lib = paste(wd, "libraries", sep = "/"))
  if (!require("XML", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("XML", lib = paste(wd, "libraries", sep = "/"))
  if (!require("RCurl", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("RCurl", lib = paste(wd, "libraries", sep = "/"))
  if (!require("osmar", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("osmar", lib = paste(wd, "libraries", sep = "/"))
  if (!require("rgeos", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("rgeos", lib = paste(wd, "libraries", sep = "/"))
  if (!require("maptools", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("maptools", lib = paste(wd, "libraries", sep = "/"))
  if (!require("rgdal", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(wd, "libraries", sep = "/"))
}



# parse data path
if (substring(wd, nchar(wd), nchar(wd)) != "/") wd <- paste(wd, "/", sep = "")


# start creating data structure
createDataStructure <- function(provDat, studyAreaPath){

  # get working data path
  workDat_temp <- strsplit(provDat, split = "/", fixed = T)[[1]]
  workDat <- ""
  for (i in 1:length(workDat_temp)){
    workDat <- paste(workDat, workDat_temp[i], sep = "")
    workDat <- paste(workDat, "/", sep = "")
  }
  workDat <- paste(workDat, outputFolderName, sep = "")
  rm(workDat_temp)
  
  
  
  
  # get data structure information
  datStr_temp <- read.csv2(paste(wd, "dataStructure.csv", sep = ""))
  datStr <- matrix("empty", nrow = nrow(datStr_temp[1]), ncol = 4,
                   dimnames = list(1:nrow(datStr_temp[1]), colnames(datStr_temp)[c(1,2,4,6)]))
  datStr[,1] <- as.character(datStr_temp[[1]])
  datStr[,2] <- paste(as.character(datStr_temp[[2]]), as.character(datStr_temp[[3]]), sep = "_")
  datStr[,3] <- paste(as.character(datStr_temp[[4]]), as.character(datStr_temp[[5]]), sep = "_")
  datStr[,4] <- as.character(datStr_temp[[6]])
  rm(datStr_temp)
  
  attri <- read.table(paste(wd, "AttributeStructure.csv", sep = ""), sep = ";", dec = ".", header = T)
  for (i in 1:ncol(attri)){
    attri[which(attri[,i] == 0),i] <- NA
  }
  
  # get unique base directory names
  base <- unique(datStr[,1])
  
  
  # read in study area
  studyArea <- readOGR(dirname(studyAreaPath), strsplit(basename(studyAreaPath), ".", fixed = T)[[1]][1])
  
  # define projection
  proj <- proj4string(studyArea)
  
  # get study area extent
  SAbbox <- as_osmar_bbox(studyArea)
  
  # load data type defaults
  defPoint <- readOGR(paste(getwd(), "DefaultGeometry", sep = "/"), "DefPoint")
  defLine <- readOGR(paste(getwd(), "DefaultGeometry", sep = "/"), "DefLine")
  defPoly <- readOGR(paste(getwd(), "DefaultGeometry", sep = "/"), "DefPolygon")
                     
  
  # reproject default shapefiles
  projdef <- proj4string(defPoint)
  if (projdef != proj) defPoint <- project(defPoint, proj)
  projdef <- proj4string(defLine)
  if (projdef != proj) defPoint <- project(defLine, proj)
  projdef <- proj4string(defPoly)
  if (projdef != proj) defPoint <- project(defPoly, proj)
                                        
                     
  # create data structure
  if (file.exists(workDat) == F) dir.create(workDat)
  for (i in 1:length(base)){
    if (file.exists(paste(workDat, base[i], sep = "/")) == F) dir.create(paste(workDat, base[i], sep = "/"))
    ObjAG <- as.character(unique(datStr[which(datStr[,1] == base[i]),2]))
    for (j in 1:length(ObjAG)){
      if (file.exists(paste(workDat, base[i], ObjAG[j], sep = "/")) == F) dir.create(paste(workDat, base[i], ObjAG[j], sep = "/"))
      ObjA <- as.character(unique(datStr[which(datStr[,2] == ObjAG[j]),3]))
      for (k in 1:length(ObjA)){
        if (is.na(ObjA[k]) == F){
          logQuerry <- datStr[which(datStr[,3] == ObjA[k]),4]
          if (logQuerry != "Raster"){
            if (logQuerry == "Point") geomtyp <- defPoint
            if (logQuerry == "Line") geomtyp <- defLine
            if (logQuerry == "Polygon") geomtyp <- defPoly
            fields <- as.character(na.omit(attri[,which(colnames(attri) == base[i])]))
            types <- as.character(na.omit(attri[,which(colnames(attri) == base[i]) + 1]))
            for (f in 1:length(fields)){
              if (types[f] == "Short Integer") addF <- c(0)
              if (types[f] == "Double") addF <- c(0.0)
              if (types[f] == "String") addF <- c("#")
              geomtyp@data <- cbind(geomtyp@data, addF) 
              colnames(geomtyp@data)[length(colnames(geomtyp@data))] <- fields[f]
            }
            if (file.exists(paste(paste(workDat, base[i], ObjAG[j], ObjA[k], sep = "/"), "shp", sep = ".")) == F) writeSpatialShape(geomtyp, paste(paste(workDat, base[i], ObjAG[j], ObjA[k], sep = "/"), "shp", sep = "."))
          }
        }
      }
    }
  }
  
  
  
  
  
}

createDataStructure(provDat = provDat, studyAreaPath = studyAreaPath)

# report to ArcGIS
print("...completed execution of R script")
