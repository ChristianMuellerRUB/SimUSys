# Calculates the shortest (network) distance between points based on travel cost analysis
# christian1.mueller@hs-bochum.de

# provDat <- "C:/HochschuleBochum/Daten/Bochum"
# modelDataName <- "SimUSys_modelData"
# gridCellSize <- "100"
# costRasCellSize <- "10"
# scriptPath <- "C:\\HochschuleBochum\\CodesScripts\\R"

# provDat <- "C:/HochschuleBochum/Daten/Herten"
# modelDataName <- "SimUSys_modelData"
# gridCellSize <- "100"
# costRasCellSize <- "10"
# scriptPath <- "C:\\HochschuleBochum\\CodesScripts\\R"

# provDat <- "C:/HochschuleBochum/Daten/Herdecke"
# modelDataName <- "SimUSys_modelData"
# gridCellSize <- "100"
# costRasCellSize <- "10"
# scriptPath <- "C:\\HochschuleBochum\\CodesScripts\\R"

# provDat <- "C:/HochschuleBochum/Daten/Herdecke"
# modelDataName <- "SimUSys_modelData_HerdeckeInnenstadt"
# gridCellSize <- "100"
# costRasCellSize <- "10"
# scriptPath <- "C:\\HochschuleBochum\\CodesScripts\\R"


args <- commandArgs()
provDat <- args[5]
modelDataName <- args[6]
gridCellSize <- args[7]
costRasCellSize <- args[8]
scriptPath <- args[9]


provDat <- gsub(pattern = "\\", replacement = "/", x = provDat, fixed = T)
scriptPath <- gsub(pattern = "\\", replacement = "/", x = scriptPath, fixed = T)
gridCellSize <- as.numeric(gridCellSize)
costRasCellSize <- as.numeric(costRasCellSize)


# define model data directory
modDataDirPath = paste(provDat, modelDataName, sep = "/")

# load packages
print("Loading R-Packages...")
scriptPath <- gsub(pattern = "\\", replacement = "/", x = scriptPath, fixed = T)
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("gdistance", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("gdistance", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("rgeos", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgeos", lib = paste(scriptPath, "libraries", sep = "/"))
}
require(parallel, lib.loc = paste(scriptPath, "libraries", sep = "/"))


# load data
fromPointsPath <- paste(modDataDirPath, "/AnalysenErgebnisse/Gitter.shp", sep = "") # fromPointsPath <- "C:/HochschuleBochum/Daten/TestFolder/fromPoly.shp"
lib <- read.table(paste(scriptPath, "LayerNamen.csv", sep = "/"), sep = ";", dec = ".", header = T, stringsAsFactors = F)
toPointsPath <- paste(modDataDirPath, lib[which(lib[,"calcAccess"] == 1), "path"], sep = "/") # toPointsPath <- "C:/HochschuleBochum/Daten/TestFolder/toP.shp"

networkLinesPathAll <- c(paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_005_FussWanderwege.shp", sep = ""),
                         paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_004_Fahrradwegenetz.shp", sep = ""),
                         # paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_006_LiniennetzOePNV.shp", sep = ""),
                         paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_007_Strassennetz.shp", sep = ""))
barriersPathAll <- c(paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_003_Barrieren.shp", sep = ""),
                     paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_003_Barrieren.shp", sep = ""),
                     # paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_003_Barrieren.shp", sep = ""),
                     paste(modDataDirPath, "/Netzwerke/9000_Netzwerke/9000_003_Barrieren.shp", sep = ""))
outFilePathAll <- c(paste(modDataDirPath, "/AnalysenErgebnisse/Erreichbarkeit_zuFuss.shp", sep = ""),
                    paste(modDataDirPath, "/AnalysenErgebnisse/Erreichbarkeit_mitFahrrad.shp", sep = ""),
                    # paste(modDataDirPath, "/AnalysenErgebnisse/Erreichbarkeit_mitOePNV.shp", sep = ""),
                    paste(modDataDirPath, "/AnalysenErgebnisse/Erreichbarkeit_mitPKW.shp", sep = ""))
# travelCostFieldAll <- c("", "", "", "", "")
# outFieldPrefixAll <- c("F", "B", "O", "P")
travelCostFieldAll <- c("", "", "", "")
outFieldPrefixAll <- c("F", "B", "P")
outCostRasterAll <- c(paste(modDataDirPath, "/AnalysenErgebnisse/Durchgaengigkeit_zuFuss", sep = ""),
                      paste(modDataDirPath, "/AnalysenErgebnisse/Durchgaengigkeit_mitFahrrad", sep = ""),
                      # paste(modDataDirPath, "/AnalysenErgebnisse/Durchgaengigkeit_mitOePNV", sep = ""),
                      paste(modDataDirPath, "/AnalysenErgebnisse/Durchgaengigkeit_mitPKW", sep = ""))

# load shapefiles
fromPointsPath <- gsub(pattern = "\\", replacement = "/", x = fromPointsPath, fixed = T)
toPointsPath <- gsub(pattern = "\\", replacement = "/", x = toPointsPath, fixed = T)
fromPoints <- readOGR(dirname(fromPointsPath), strsplit(basename(fromPointsPath), ".", fixed = T)[[1]][1])

calcDistances <- function(m){

  networkLinesPath <- gsub(pattern = "\\", replacement = "/", x = networkLinesPathAll[m], fixed = T) # networkLinesPath <- "C:/HochschuleBochum/Daten/TestFolder/lines.shp"
  barriersPath <- gsub(pattern = "\\", replacement = "/", x = barriersPathAll[m], fixed = T)
  outFilePath <- gsub(pattern = "\\", replacement = "/", x = outFilePathAll[m], fixed = T)
  
  travelCostField <- travelCostFieldAll[m]
  outFieldPrefix <- outFieldPrefixAll[m]
  
  # calculate distances
  source(paste(scriptPath, "shortestDistance.r", sep = "/"))
  shortestDistance(fromPoints, toPointsPath, networkLinesPath, outFilePath, outFieldPrefix, gridCellSize, costRasCellSize, scriptPath, fromPointsPath)

}

# prepare multicore processing
nUseCores <- detectCores() - 0
if (nUseCores == 0) nUseCores <- 1
cl <- makePSOCKcluster(nUseCores)
clusterExport(cl, ls(), envir = .GlobalEnv)

# run loop over each layer as multicore processing
parLapply(cl = cl, X = 1:length(networkLinesPathAll), fun = calcDistances)

# close multicore processing
stopCluster(cl)

 
# report to ArcGIS
print ("...finished execution of R-Script.")
