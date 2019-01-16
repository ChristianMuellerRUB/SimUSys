# calculateDensitiesInPolygon.r

args <- commandArgs()
shpPath <- args[5]
fields <- args[6]
areaField <- args[7]
prefix <- args[8]
scriptPath <- args[9]
meanFields <- args[10]
sumFields <- args[11]
noDataValue <- args[12]



# convert fields string to vector
clearInput <- function(x){
  x <- strsplit(x, ";")[[1]]
  if (length(x) == 1) x <- strsplit(x, ",")[[1]]
  for (i in 1:length(x)){
    if (substr(x[i], 1, 1) == " ") x[i] <- substr(x[i], 2, nchar(x[i])-1)
    if (substr(x[i], 1, 1) == "[") x[i] <- substr(x[i], 2, nchar(x[i])-1)
    if (substr(x[i], nchar(x[i]), nchar(x[i])) == "]") x[i] <- substr(x[i], 1, nchar(x[i])-1)
    if (substr(x[i], 1, 1) == "'") x[i] <- substr(x[i], 2, nchar(x[i]))
    if (substr(x[i], nchar(x[i]), nchar(x[i])) == "'") x[i] <- substr(x[i], 1, nchar(x[i])-1)
    
  }
  return(x)
}
fields <- clearInput(fields)
meanFields <- clearInput(meanFields)
sumFields <- clearInput(sumFields)



# filter fields
meanFields <- meanFields[which(meanFields %in% fields)]
sumFields <- sumFields[which(sumFields %in% fields)]
if (length(meanFields) == 0) meanFields <- "0"
if (length(sumFields) == 0) sumFields <- "0"

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}



# read .dbf-table
tab <- read.dbf(paste(strsplit(shpPath, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)


# get area size data
areaDat <- abs(tab[,which(names(tab) == areaField)])

# ensure existance of all fields
allFields <- c(meanFields, sumFields)
fieldsPos <- which(allFields %in% colnames(tab))
fields <- allFields[fieldsPos]
fieldsPos <- which(meanFields %in% colnames(tab))
meanFields <- meanFields[fieldsPos]
fieldsPos <- which(sumFields %in% colnames(tab))
sumFields <- sumFields[fieldsPos]


# loop over each absolute field
for (i in 1:length(fields)){
  
  # get field data
  thisFieldDat <- as.numeric(tab[,which(names(tab) == fields[i])])
  
  # add new field
  newFieldName <- paste(prefix, fields[i], sep = "_")
  if (newFieldName %in% colnames(tab) == F){
    tab$newDen <- 0
    names(tab)[ncol(tab)] <- newFieldName
  }
  
  # calculate density
  thisDen <- thisFieldDat / areaDat
  
  
  # correct invalid calculations
  invalids <- which(thisDen == "Inf")
  if (length(invalids) > 0) thisDen[invalids] <- 0
    
  # reset no data values
  invalids <- which(thisDen == as.numeric(noDataValue))
  if (length(invalids) > 0) thisDen[invalids] <- -1
    
    
  # write density data to attribute matrix
  tab[,which(names(tab) == paste(prefix, fields[i], sep = "_"))] <- thisDen
    
}



# ensure field length of string fields
source(paste(scriptPath, "setDBFStringFieldLength.r", sep = "/"))
tab <- setDBFStringFieldLength(tab)


# write attribute table
write.dbf(tab, file = paste(strsplit(shpPath, ".", fixed = T)[[1]][1], "dbf", sep = "."))
  

print("...completed execution of R-script")
