# countEntities.r

# get input arguments
args <- commandArgs()
provDat <- args[5]
scriptPath <- args[6]

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("XLConnectJars", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnectJars", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("XLConnect", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnect", lib = paste(scriptPath, "libraries", sep = "/"))
}

# prepare input
scriptPath <- gsub(scriptPath, pattern = "\\\\", replacement = "/")

# read join library CSV
tab <- read.table(paste(scriptPath, "countEntitiesLib.csv", sep = "/"), header = T, sep = ";", dec = ".", as.is = T) 


for (i in 1:nrow(tab)){
  
  # look for files
  ns_file <- list.files(provDat, pattern = tab[i,1], recursive = T, full.names = T)[1]
  
  if (length(ns_file) > 0){
    
    # load non-spatial table
    if (strsplit(basename(ns_file), ".", fixed = T)[[1]][2] %in% c("xls", "xlsx")){
    
      # read non-spatial data
      ns_wb <- loadWorkbook(ns_file)
      ns_dat <- readWorksheet(ns_wb, sheet = 1, header = T)
      rm(ns_wb)
      
    } else if (strsplit(basename(ns_file), ".", fixed = T)[[1]][2] %in% c("dbf")){
      
      ns_dat <- read.dbf(paste(strsplit(ns_file, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
      
    } else {
      
      ns_dat <- read.table(ns_file, sep = ";", dec = ".", header = T, as.is = T)
      
    }
    
    # get attribute field
    thisField <- gsub(tab[i,2], pattern = "-", replacement = ".")
    pos <- which(colnames(ns_dat) == thisField)
    if (length(pos) > 0){
      alldat <- ns_dat[,pos]
      
      # count entities
      countdat <- as.matrix(table(alldat))
      
      # prepare output data
      outdat <- as.data.frame(cbind(rownames(countdat), as.numeric(countdat)))
      colnames(outdat)[1] <- thisField
      colnames(outdat)[2] <- "counted"
      
      # prepare output data file path
      outfile <- paste(strsplit(ns_file, ".", fixed = T)[[1]][1], "_countedEntities.csv", sep = "")
      
      # write to file
      write.table(outdat, file = outfile, row.names = F, col.names = T, sep = ";", dec = ".")
      
    }
    
    
  }

}

# clean up working directory
rm(list=ls())

# report to ArcGIS
print ("...finished execution of R-Script.")
