# renameAttributeField.r
# Renames a shapefile attribute field

# get input arguments
args <- commandArgs()
shapefilePath <- args[5]
fromFieldName <- args[6]
toFieldName <- args[7]
rScriptPath <- args[8]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(rScriptPath, "libraries", sep = "/"))
}
library(foreign, quietly = T, warn.conflicts = F)


# read analysis grid .dbf-table
incDBFPath <- paste(strsplit(shapefilePath, ".", fixed = T)[[1]][1], "dbf", sep = ".")
incdat <- read.dbf(incDBFPath, as.is = T)

# rename attribute field name
names(incdat)[which(names(incdat) == fromFieldName)] <- toFieldName


# ensure field length of string fields
source(paste(rScriptPath, "setDBFStringFieldLength.r", sep = "/"))
incdat <- setDBFStringFieldLength(incdat)


# write .dbf to file
write.dbf(incdat, file = paste(strsplit(shapefilePath, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# report to ArcGIS
print ("...finished execution of R-Script.")
