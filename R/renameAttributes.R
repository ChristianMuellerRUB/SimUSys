# renameAttributes.r

# Searches attribute tables and renames attributes according to a .csv-Table

# input from python
args <- commandArgs()
provDat <- args[5]
wd <- args[6]

# prepare data path
provDat <- gsub(pattern = "\\", replacement = "/", x = provDat, fixed = T)
wd <- gsub(pattern = "\\", replacement = "/", x = wd, fixed = T)

setwd(wd)

if (substring(wd, nchar(wd), nchar(wd)) != "/") wd <- paste(wd, "/", sep = "")

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(wd, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("foreign", lib = paste(wd, "libraries", sep = "/"))
}
library(foreign, quietly = T, warn.conflicts = F)


# read in rename library
lib <- read.table("renameAttributes.csv", sep = ";", dec = ".", header = T, stringsAsFactors = F)

# find data according to rename library
for (i in 1:nrow(lib)){
  allFiles <- list.files(provDat, pattern = paste(lib[i,1], ".dbf", sep = ""), full.names = T, recursive = T)
  if (length(allFiles) > 0){
    for (f in 1:length(allFiles)){
      thisFileName <- strsplit(allFiles[f], split = ".", fixed = T)[[1]]
      thisFileTest <- strsplit(allFiles[f], split = paste(lib[i,1], ".", sep = ""), fixed = T)[[1]]
      if (length(thisFileTest) == 2){
        dat <- read.dbf(allFiles[f], as.is = T)
        attPos <- which(colnames(dat) == lib[i,2])
        if (length(attPos) != 0){
          colnames(dat)[attPos] <- lib[i,3]
          write.dbf(dat, file = allFiles[f])
        }
      }
    }
  }
}

print("...completed execution of R script")