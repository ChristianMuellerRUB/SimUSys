# searchData.r
# This Script searches a provided data path for data to feed the simulation model


# input from python
args <- commandArgs()
provDat <- args[5]
modelDataPath <- args[6]
wd <- args[7]


# define model data directory
modDataDirPath = paste(provDat, modelDataPath, sep = "/")


provDat <- gsub(pattern = "\\", replacement = "/", x = provDat, fixed = T)
wd <- gsub(pattern = "\\", replacement = "/", x = wd, fixed = T)


setwd(wd)

if (substring(wd, nchar(wd), nchar(wd)) != "/") wd <- paste(wd, "/", sep = "")


# read in data source library
lib <- read.table("DataSourceBib.csv", sep = ";", dec = ".", header = T, stringsAsFactors = F)

# define data path for data to be stored
inPaths <- paste(paste(provDat, modelDataPath, lib[,2], paste(lib[,3], lib[,4], sep = "_"), paste(lib[,5], lib[,6], sep = "_"), sep = "/"), "shp", sep = ".")

### part one - geometry

# find data according to data source library
sourceTab <- lib
fileNames <- lib[,which(colnames(lib) == "Dateiname_out")]
fileNames <- cbind(fileNames, found = "")
ufileNames <- unique(fileNames)
allSHP <- list.files(provDat, pattern = "\\.shp$", full.names = T, recursive = T)
for (f in 1:length(ufileNames)){
  hit <- grep(allSHP, pattern = ufileNames[f])
  if (length(hit) > 1){
    hit3 <- hit[grep(allSHP[hit], pattern = "_combined")]
    if (length(hit3) > 0){
      hit <- hit3
    } else {
      geoMet <- lib[which(lib[,10] == ufileNames[f]),7][1]
      geoMetPat <- tolower(substring(geoMet, 1, 3))
      hit2 <- hit[grep(basename(allSHP[hit]), pattern = geoMetPat, ignore.case = T)]
      if (length(hit2) > 0) {
        hit <- hit2
      } else {
        hit <- hit[1]
      }
    }
  }
  if (length(hit) > 0){
    fileNames[which(fileNames[,1] == ufileNames[f]),2] <- allSHP[hit][1]
  }
}
hitPos <- which(fileNames[,2] != "")
sourceTab <- lib[hitPos,]
sourceTab$outPath <- fileNames[hitPos,2]
sourceTab$inPath <- inPaths[hitPos]

# ask user for correctness of data paths and give oppertunity to add data paths manually
userTab <- sourceTab

# apply priorities: all point features will be included. As for lines and polygons, only the ones with the highest priority will be included. If more than one highest priority will be detected only the first file will be included in the simulation
priorTab <- userTab[-(1:length(userTab))]  # copy data frame without entries
allIns <- unique(userTab[,1])  # get unique input shapefiles
for (i in 1:length(allIns)){
  thisIn <- userTab[which(userTab[,1] == allIns[i]),]
  
  
    # get the one with the highest priority
    prior <- thisIn[which(thisIn[,which(names(thisIn) == "Prioritaet")] == min(thisIn[,which(names(thisIn) == "Prioritaet")])),]  # get highest priority cases
    
    thisOutFile <- unique(prior[,which(names(prior) == "outPath")])
    thisOutFileSource <- cbind(thisOutFile, gsource = character(length(thisOutFile)))
    for (s in 1:length(thisOutFile)){
      thisOutFileSource[s,2] <- prior[which(prior[,15] == thisOutFile[s])[1],9]
    }
    thisSources <- prior[,which(colnames(prior) == "Quelle")]
    if (length(thisOutFile) > 1){
      if (all(prior[,"Geometrie"] == "Point")){
        thisOutFile <- thisOutFileSource[,1]
      } else if (all(prior[,"Geometrie"] == "Line")){
        thisOutFile <- thisOutFileSource[,1]
      } else {
        thisSource <- unique(thisSources)[1]
        print(paste("Es wurden mehr als eine Datei mit gleicher hoechster Prioritaet fuer den Import als ", thisIn[1,1], " ausgewaehlt. Es werden nur Daten aus einer Quelle (", thisSource, ") importiert.", sep = ""))
        thisOutFile <- thisOutFileSource[which(thisOutFileSource[,2] == thisSource),1]
      }
    }
    priorTab <- rbind(priorTab, thisIn[which(thisIn[,which(names(thisIn) == "outPath")] %in% thisOutFile),])
  
}


# sort table by outPath in order to process preprocess input files only once (later on the workflow)
ord <- order(priorTab[,which(names(priorTab) == "outPath")])
priorTab <- priorTab[ord,]

# write table
write.table(priorTab, file = paste(modDataDirPath, "use_spatialImport_All.csv", sep = "/"), sep = ";", dec = ".", row.name = F)


print("...completed execution of R script")