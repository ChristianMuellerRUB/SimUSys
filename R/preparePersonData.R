# preparePersonData.r
# Prepares person related data

# select shapefiles and output shapefile path
args <- commandArgs()
modFolder <- args[5]
scriptPath <- args[6]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}

# look for import library file
libPath <- paste(modFolder, "use_spatialImport_All.csv", sep = "/")

if (file.exists(libPath)){
  
  # read import library file
  lib <- read.table(libPath, sep = ";", dec = ".", header = T, as.is = T)
  
  # look for person related import entries
  pos <- grep(x = lib[,"file_in"], pattern = "Person.shp", fixed = T)
  
  if (length(pos) > 0){
    
    # get source file names
    sourceFiles <- unique(lib[pos,"outPath"])
    
    # iterate over source files
    for (s in 1:length(sourceFiles)){
      
      thisFile <- sourceFiles[s]
      
      # test if there are features in source file
      nFeatures <- 0
      try(nFeatures <- ogrInfo(dirname(thisFile), strsplit(basename(thisFile), ".", fixed = T)[[1]][1])[1], silent = T)
      
      if (nFeatures > 0){
        
        # get attribute table
        dat <- read.dbf(paste(strsplit(thisFile, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
        
        
        # add information based on provided infos
        if (("NEinw" %in% colnames(dat)) == F){
          dat <- cbind(dat, 1)
          colnames(dat)[ncol(dat)] <- "NEinw"
        }
        
        
        # get maritial status field
        fam_pos <- which(lib[pos,"Feld_in"] == "FamSt")
        
        if (length(fam_pos) > 0){
          
          famField <- lib[pos,"Feld_out"][fam_pos]
          f_pos <- which(colnames(dat) %in% famField)[1]
          
          if (length(f_pos) > 0){
            
            # add maritial status related information
            if (("Nledig" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "Nledig"
              entry_pos <- which(dat[,f_pos] == "LD")
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("Nverheir" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "Nverheir"
              entry_pos <- which(dat[,f_pos] == "VH")
              entry_pos <- c(entry_pos, which(dat[,f_pos] == "LP"))
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("Nverwit" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "Nverwit"
              entry_pos <- which(dat[,f_pos] == "VW")
              entry_pos <- c(entry_pos, which(dat[,f_pos] == "LE"))
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("Ngschied" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "Ngschied"
              entry_pos <- which(dat[,f_pos] == "GS")
              entry_pos <- c(entry_pos, which(dat[,f_pos] == "LA"))
              entry_pos <- c(entry_pos, which(dat[,f_pos] == "EA"))
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
          }
          
        }
            
            
        
        # get age field name
        age_pos <- which(lib[pos,"Feld_in"] == "AltN_AV")
        
        if (length(age_pos) > 0){
        
          ageField <- lib[pos,"Feld_out"][age_pos]
          a_pos <- which(colnames(dat) %in% ageField)[1]
          
          if (length(a_pos) > 0){
          
            # add age related information
            if (("NKitaK" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "NKitaK"
              entry_pos <- which(dat[,a_pos] <= 3)
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("NKindgK" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "NKindgK"
              entry_pos <- which(dat[,a_pos] > 3)
              if (length(entry_pos) > 0) entry_pos <- which(dat[entry_pos, a_pos] <= 5)
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("NGrundS" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "NGrundS"
              entry_pos <- which(dat[,a_pos] > 5)
              if (length(entry_pos) > 0) entry_pos <- which(dat[entry_pos, a_pos] <= 10)
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("NJugend" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "NJugend"
              entry_pos <- which(dat[,a_pos] > 10)
              if (length(entry_pos) > 0) entry_pos <- which(dat[entry_pos, a_pos] <= 18)
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("NErwJ" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "NErwJ"
              entry_pos <- which(dat[,a_pos] > 18)
              if (length(entry_pos) > 0) entry_pos <- which(dat[entry_pos, a_pos] <= 35)
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("NErwA" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "NErwA"
              entry_pos <- which(dat[,a_pos] > 35)
              if (length(entry_pos) > 0) entry_pos <- which(dat[entry_pos, a_pos] <= 67)
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
            if (("NSenMob" %in% colnames(dat)) == F){
              dat <- cbind(dat, 0)
              colnames(dat)[ncol(dat)] <- "NSenMob"
              entry_pos <- which(dat[,a_pos] > 67)
              if (length(entry_pos) > 0){
                dat[entry_pos,ncol(dat)] <- 1
              }
            }
            
          }
          
        }
       
        # write updated attribute table to file
        write.dbf(dat, file = paste(strsplit(thisFile, ".", fixed = T)[[1]][1], "dbf", sep = "."))
         
      }
      
    }
    
  }
  
}

# report to ArcGIS
print ("...finished execution of R-Script.")
