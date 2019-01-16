# changeValueInAttributeTable.r
# Changes a specific value in a specific attribute field of shapefiles


# get input arguments
args <- commandArgs()
shp <- args[5]
field <- args[6]
oldval <- args[7]
newval <- args[8]
rScriptPath <- args[9]


options(warn = -1)

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(rScriptPath, "libraries", sep = "/"))
}


if (oldval == "emtpy") oldval <- ""

# read analysis grid .dbf-table
indbf <- paste(strsplit(shp, ".", fixed = T)[[1]][1], "dbf", sep = ".")


# replace values
dat <- read.dbf(indbf, as.is = T)


if (field == ""){
  for (c in 1:ncol(dat)){
    pos <- which(dat[,c] == oldval)
    if (length(pos) > 0) dat[pos, c] <- newval
    pos <- which(is.na(dat[,c]))
    if (length(pos) > 0) dat[pos, c] <- newval
  }
} else { 
  pos <- which(dat[,field] == oldval)
  if (length(pos) > 0) dat[pos, field] <- newval
  pos <- which(is.na(dat[,field]))
  if (length(pos) > 0) dat[pos, field] <- newval
}


# ensure field length of string fields
source(paste(rScriptPath, "setDBFStringFieldLength.r", sep = "/"))
dat <- setDBFStringFieldLength(dat)


# write .dbf to file
write.dbf(dat, file = paste(strsplit(shp, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# report to ArcGIS
print ("...completed execution of R script")
