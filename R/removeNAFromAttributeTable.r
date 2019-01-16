# removeNAFromAttributeTable.r
# Removes NA values from attribute table of shapefiles


# get input arguments
args <- commandArgs()
shp <- args[5]
rScriptPath <- args[6]

options(warn = -1)

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}


# read analysis grid .dbf-table
indbf <- paste(strsplit(shp, ".", fixed = T)[[1]][1], "dbf", sep = ".")


# replace NA values
dat <- read.dbf(indbf, as.is = T)
for (c in 1:ncol(dat)){
  pos <- which(dat[,c] == "NA")
  if (length(pos) > 0) dat[pos, c] <- ""
  pos <- which(is.na(dat[,c]))
  if (length(pos) > 0) dat[pos, c] <- ""
}

# ensure field length of string fields
source(paste(rScriptPath, "setDBFStringFieldLength.r", sep = "/"))
dat <- setDBFStringFieldLength(dat)


# write .dbf to file
write.dbf(dat, file = paste(strsplit(shp, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# report to ArcGIS
print ("...completed execution of R script")
