# planningEntityGrid_relative_accountForPersonData.r
# Recalculates relative values if person data is available


# select shapefiles and output shapefile path
args <- commandArgs()
modFolder <- args[5]
rScriptPath <- args[6]
sumFields <- args[7]



# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(rScriptPath, "libraries", sep = "/"))
  if (!require("maptools", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("maptools", lib = paste(rScriptPath, "libraries", sep = "/"))
  if (!require("foreign", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(rScriptPath, "libraries", sep = "/"))
  if (!require("raster", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("raster", lib = paste(rScriptPath, "libraries", sep = "/"))
}

# get highest resolution data on number of citizens
higRes <- read.table(paste(modFolder, "highestResAttributes.csv", sep = "/"), sep = ";", dec = ".", header = T, as.is = T)

# get attribute fields which have been aggregated from person data
pos <- c()
pos <- c(pos, which(basename(higRes[,"file"]) == "8000_012_Person.shp"))
pos <- c(pos, which(basename(higRes[,"file"]) == "8000_011_Adresskoordinate.shp"))
pos <- c(pos, which(basename(higRes[,"file"]) == "8000_010_Adresse.shp"))
if (length(pos) > 0){
  
  fields <- c()
  for (c in 1:length(pos)){
    fields <- c(fields, higRes[pos[c], 2])
  }
  fields <- strsplit(fields, ";", fixed = T)[[1]]
  fields <- unique(fields)
  
  # filter for fields which have been aggregated as sums
  sumFields <- strsplit(sumFields, ";", fixed = T)[[1]]
  
  hitpos <- which(fields %in% sumFields)
  if (length(hitpos) > 0) fields <- fields[hitpos]


  # get absolute aggregated grid data
  absGrid_path <- paste(modFolder, "/AnalysenErgebnisse/PlanungseinheitenAggregiert_total.dbf", sep = "")
  if (file.exists(absGrid_path)){
    dat <- read.dbf(paste(strsplit(absGrid_path, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
    
    # check if information on number of citizens is available
    if ("NEinw" %in% colnames(dat)){
    
      # get non-no data rows
      use_r <- which(dat[,"NEinw"] != -1)
      if (length(use_r) > 0){
        
        # re-calculate relative values for respective attribute fields
        for (f in 1:ncol(dat)){
          
          thisField <- colnames(dat)[f]
          
          if ((thisField != "grid_ID") && (thisField != "NEinw")){
            
            if (thisField %in% fields){
              
              use_this <- unique(c(use_r, which(dat[,f] != -1)))
              
              dat[use_this, f] <- dat[use_this, f] / dat[use_this, "NEinw"] * 100
              
              # account for invalid calculations
              setZero <- c()
              setZero <- c(setZero, which(is.na(dat[use_r, f])))
              setZero <- c(setZero, which(dat[use_r, f] == "Inf"))
              setZero <- c(setZero, which(dat[use_r, f] == "-Inf"))
              if (length(setZero) > 0) dat[use_r, f][setZero] <- 0
              
            }
            
          }
          
        }
        
        
      }
      
    }
    
    # write to relative aggregated grid
    relGrid_path <- paste(modFolder, "/AnalysenErgebnisse/PlanungseinheitenAggregiert_relativ.dbf", sep = "")
    
    if (file.exists(relGrid_path)){
    
      # write relative values to file
      write.dbf(dat, file = paste(strsplit(relGrid_path, ".", fixed = T)[[1]][1], "dbf", sep = "."))
      
    }
  }
  
}

# report to ArcGIS
print ("...finished execution of R-Script.")
