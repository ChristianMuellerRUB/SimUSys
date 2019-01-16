# aggregatedPlanningEntities_relativToabsolute.r
# Calculates absolute values from relative values in aggregated planning entities grid

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

# get aggregated grid (relative values)
rel_path <- paste(modFolder, "/AnalysenErgebnisse/PlanungseinheitenAggregiert_relativ.shp", sep = "")
rel_sp <- readOGR(dirname(rel_path), strsplit(basename(rel_path), ".", fixed = T)[[1]][1])
rel_dat <- rel_sp@data

# iterate over each higher planning entity
fPos <- which(colnames(rel_dat) %in% sumFields)
ePos <- which(colnames(rel_dat) == "NEinw")
for (f in 1:length(fPos)){
  rel_dat[,fPos[f]] <- (rel_dat[,fPos[f]] / 100) * rel_dat[,ePos]
}

# create new spatial object for absolute values
abs_sp <- rel_sp
abs_sp@data <- rel_dat
  
# write shapefile
outShp <- paste(modFolder, "/AnalysenErgebnisse/PlanungseinheitenAggregiert_absolut.shp", sep = "")
writeOGR(abs_sp, dsn = dirname(outShp), layer = strsplit(basename(outShp), ".", fixed = T)[[1]][1],
         driver = "ESRI Shapefile", overwrite_layer = T)

# report to ArcGIS
print ("...finished execution of R-Script.")
