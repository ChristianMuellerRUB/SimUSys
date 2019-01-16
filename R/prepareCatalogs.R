# prepareCatalogs.r
# Prepares data catalogs for SimUSys

# get input arguments
args <- commandArgs()
provDat <- args[5]
modelDataPath <- args[6]
scriptPath <- args[7]

# prepare input
provDat <- gsub(provDat, pattern = "\\\\", replacement = "/")
modelDataPath <- gsub(modelDataPath, pattern = "\\\\", replacement = "/")
scriptPath <- gsub(scriptPath, pattern = "\\\\", replacement = "/")

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("XLConnectJars", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnectJars", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("XLConnect", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("XLConnect", lib = paste(scriptPath, "libraries", sep = "/"))
}


# define conversion function
xlsxTocsv <- function(xlsxPath, csvName, sheetNames, scriptPath){
  
  # read xlsx
  wb <- loadWorkbook(xlsxPath)
  for (s in 1:length(csvName)){
    csvPath <- paste(scriptPath, csvName[s], sep = "/")
    sheetName <- sheetNames[s]
    dat <- readWorksheet(wb, sheet = sheetName, header = T)
    
    # reformat NA
    dat[which(is.na(dat), arr.ind = T)] <- ""
    
    if (sheetName == "Datenimporte"){
    
      # reassure that all filenames have extensions
      allf <- dat[,"Dateiname_out"]
      for (a in 1:length(allf)){
        if (length(strsplit(allf[a], ".", fixed = T)[[1]]) == 1){
          dat[a,"Dateiname_out"] <- paste(allf[a], ".shp", sep = "")
        }
      }
      
    }
      
    # write to csv
    write.table(dat, file = csvPath, sep = ";", dec = ".", row.name = F)
  }
}

# execute conversion
xlsxPath <- paste(scriptPath, "DatenKatalog_Datenmodell.xlsx", sep = "/")
csvName <- c("DataSourceBib.csv", "DataStructure.csv", "AttributeStructure.csv", "LayerNamen.csv")
sheetNames <- c("Datenimporte", "Datenstruktur_fuer_R", "Attributstruktur_fuer_R", "LayerNamen")
xlsxTocsv(xlsxPath, csvName, sheetNames, scriptPath)


# report to ArcGIS
print ("...finished execution of R-Script.")
