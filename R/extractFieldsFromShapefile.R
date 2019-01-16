# extractFieldsFromShapefile.r
# Extracts attribute fields from shapefiles and saves only the extracted fields

args <- commandArgs()
inShp <- args[5]
fields <- args[6]
noDataValue <- args[7]
scriptPath <- args[8]



# prepare inputs
fields <- strsplit(fields, ";")[[1]]
noDataValue <- as.numeric(noDataValue)

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}


# read dbf file
dat <- read.dbf(paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)

# create container for output attribute table
out <- c()

# iterate over each specified field
for (f in 1:length(fields)){
  
  # continue if this field exists in source attribute table
  if (fields[f] %in% colnames(dat)){
    
    # extract data
    thisDat <- dat[,which(colnames(dat) == fields[f])]
    
    # determine valid data entries
    validPos <- which(thisDat != noDataValue)
    
    # continue if there is any valid data entry for this field
    if (length(validPos) > 0){
      
      # add this attribute field to the output attribute table
      out <- cbind(out, thisDat)
      
      # rename added field
      colnames(out)[ncol(out)] <- fields[f]
      
    }
    
  }
  
}


# write new attribute table to file
write.dbf(out, file = paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# send feedback to python
print("...completed execution of R-script")
