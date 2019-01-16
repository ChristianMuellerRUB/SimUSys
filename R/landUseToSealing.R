# landUseToSealing.r

args <- commandArgs()
modelFolder <- args[5]
rScriptPath <- args[6]

modelFolder <- gsub(pattern = "\\", replacement = "/", x = modelFolder, fixed = T)
scriptPath <- gsub(pattern = "\\", replacement = "/", x = rScriptPath, fixed = T)


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}


# get data from sealing specifying table
sealDat <- read.table(paste(rScriptPath, "landUseToSealing.csv", sep = "\\"), header = T, dec = ".", sep = ";")


# landuse shapefile path
inShp <- paste(modelFolder, "UmweltVersorgung\\1100_UmweltVersorgung\\1100_012_Landnutzung.shp", sep = "\\")

# read dbf file
dat <- read.dbf(paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)

# get landuse and sealing fields
luPos <- which(colnames(dat) == "Spezi")
sPos <- which(colnames(dat) == "Versieg")

# continue if there are features in this shapefile
if (nrow(dat) > 0){
  
  # continue if there is at least one valid entry in the landuse attribute field
  if (length(which(is.na(dat[,luPos]))) < nrow(dat)){
    
    # iterate over each row
    for (r in 1:nrow(dat)){
      
      hitPos <- which(sealDat[,1] == dat[r,luPos])
      
      # continue if there is information in the sealing table
      if (length(hitPos) > 0){
        
        # overwrite sealing information according to table
        dat[r,sPos] <- sealDat[hitPos,2]
        
      }
      
    }
    
  }
  
  # ensure field length of string fields
  source(paste(scriptPath, "setDBFStringFieldLength.r", sep = "/"))
  dat <- setDBFStringFieldLength(dat)
  
  
  # write new attribute table to file
  write.dbf(dat, file = paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."))

}

# send feedback to python
print("...completed execution of R-script")
