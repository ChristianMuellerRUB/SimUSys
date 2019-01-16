# joinByLibrary.r
# Joins non-spatial data to spatial data as defined in a csv library

# get input arguments
args <- commandArgs()
scriptPath <- args[5]
dataPath <- args[6]
overwriteExisting <- args[7]

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("XLConnectJars", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnectJars", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("XLConnect", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnect", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("stringr", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("stringr", lib = paste(scriptPath, "libraries", sep = "/"))
}

# prepare input
scriptPath <- gsub(scriptPath, pattern = "\\\\", replacement = "/")
dataPath <- gsub(dataPath, pattern = "\\\\", replacement = "/")
if (overwriteExisting == "true") overwriteExisting <- T else overwriteExisting <- F

# read join library CSV
tab <- read.table(paste(scriptPath, "joinLib.csv", sep = "/"), header = T, sep = ";", dec = ".", as.is = T) 
tab <- tab[order(tab[,6]),]

# list all files in data model directory
print("Getting all files in directory...")
all_files <- list.files(dataPath, recursive = T, full.names = T)

# create temporary container
s_file_before <- "temp"

for (i in 1:nrow(tab)){

  # give feedback on progress to the console
  print(paste("Processing ", i, " out of ", nrow(tab), sep = ""))
  
  # look for files
  ns_file <- all_files[grep(x = all_files, pattern = tab[i,1], fixed = T)][1]
  s_file <- all_files[grep(x = all_files, pattern = tab[i,5], fixed = T)][1]
  if (is.na(s_file) || length(s_file) == 0){
    s_file <- all_files[grep(x = all_files, pattern = tab[i,2], fixed = T)][1]
  }
  
  if ((length(ns_file) > 0) && (length(s_file) > 0) && (is.na(ns_file) == F) && (is.na(s_file) == F)){
    
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
    
    if (s_file_before != s_file){
      s_sobj <- readOGR(dirname(s_file), strsplit(basename(s_file), ".", fixed = T)[[1]][1])
      s_dat <- s_sobj@data
      s_file_before <- s_file
    }
    join_field_copy <- s_dat[,tab[i,4]]
      
    
    # remove duplicate fields in join table
    fromFieldData <- c()
    try(fromFieldData <- as.data.frame(ns_dat[,which(colnames(ns_dat) == tab[i,3])]), silent = T)
    if (length(fromFieldData) > 0){
      
      colnames(fromFieldData) <- tab[i,3]
      colnames(ns_dat) <- substr(colnames(ns_dat), 1, 10)
      ns_dat <- as.data.frame(ns_dat[,unique(colnames(ns_dat))])
      colnames(s_dat) <- substr(colnames(s_dat), 1, 10)
      setNames <- unique(colnames(s_dat))
      s_dat <- as.data.frame(s_dat[,unique(colnames(s_dat))])
      colnames(s_dat) <- setNames
      duppos <- which(colnames(ns_dat) %in% colnames(s_dat))
      if (length(duppos) > 0){
        temp <- as.data.frame(ns_dat[,-duppos])
        colnames(temp) <- colnames(ns_dat)[-duppos]
      } else {
        temp <- ns_dat
      }
      ns_dat <- cbind(fromFieldData, temp)
      
      
      # continue if there are new columns in the join table
      if (length(ns_dat) > 0){
      
        # add columns to target attribute table
        s_dat <- cbind(s_dat, matrix(NA, nrow = nrow(s_dat), ncol = ncol(ns_dat)))
        colnames(s_dat)[(ncol(s_dat) - ncol(ns_dat) + 1):ncol(s_dat)] <- colnames(ns_dat)
        
        # match data entries
        for (r in 1:nrow(ns_dat)){
          pos <- c()
          try(pos <- which(as.character(s_dat[,tab[i,4]]) == as.character(ns_dat[r,tab[i,3]])), silent = T)
          if (length(pos) > 0){
            s_dat[pos,(ncol(s_dat) - ncol(ns_dat) + 1):ncol(s_dat)] <- ns_dat[r,]
          }
        }
        
        
        # shorten field names
        for (rc in 1:ncol(s_dat)){
          colnames(s_dat)[rc] <- gsub(pattern = ".", replacement = "", x = colnames(s_dat)[rc], fixed = T)
          colnames(s_dat)[rc] <- substr(colnames(s_dat)[rc], 1, 10)
        }
        
        # remove join field if it is already present in target table
        s_dat <- s_dat[,unique(colnames(s_dat))]
        
        
        # remove duplicate fields
        remF <- c()
        for (c in 1:ncol(s_dat)){
          pos <- which(colnames(s_dat) == colnames(s_dat)[c])
          if (length(pos) > 1) remF <- c(remF, pos[-1])
        }
        if (length(remF) > 0) s_dat <- s_dat[,-unique(remF)]
        
        # remove NA field names
        remF <- c()
        remF <- which(is.na(colnames(s_dat)))
        if (length(remF > 0)) s_dat <- s_dat[,-remF]
        

        
        # write to file
        try({
          s_dat <- s_dat[which(s_dat[,tab[i,4]] %in% join_field_copy),]
          s_sobj@data <- s_dat
          writeOGR(s_sobj, dsn = dirname(s_file), layer = strsplit(tab[i,5], ".", fixed = T)[[1]][1],
                   driver = 'ESRI Shapefile', overwrite_layer = T)
        
        
        }, silent = T)
          
      }  
    }

  }
  
}

# clean up working directory
rm(list=ls())

# report to ArcGIS
print ("...finished execution of R-Script.")
