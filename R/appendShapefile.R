# appendShapefile.r
# appends features from one shapefile to another

# input from python
args <- commandArgs()
fromShp <- args[5]
toShp <- args[6]
rScriptPath <- args[7]


# suppress warnings
options(warn = -1)

print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
Sys.chmod(rScriptPath, mode = "0777", use_umask = TRUE)
try(
  for (i in 1:2){
    if (!require("sp", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("sp", lib = paste(rScriptPath, "libraries", sep = "/"))
    if (!require("maptools", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("maptools", lib = paste(rScriptPath, "libraries", sep = "/"))
    if (!require("rgdal", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(rScriptPath, "libraries", sep = "/"))
    if (!require("rgeos", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("rgeos", lib = paste(rScriptPath, "libraries", sep = "/"))
  }
  , silent = T)


# load spatial data
fromShp_sp <- readOGR(dirname(fromShp), strsplit(basename(fromShp), ".", fixed = T)[[1]][1])
toShp_sp <- readOGR(dirname(toShp), strsplit(basename(toShp), ".", fixed = T)[[1]][1])

# append data
out_sp <- rbind(toShp_sp, fromShp_sp)

# write to file
writeOGR(out_sp, dsn = dirname(toShp), layer = strsplit(basename(toShp), ".", fixed = T)[[1]][1], driver = "ESRI Shapefile",
         overwrite_layer = T)

print("...completed execution of R-script")

