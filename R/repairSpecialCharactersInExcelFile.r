# repairSpecialCharactersInExcelFile.r
# repairs special characters in an excel file


# get input arguments
args <- commandArgs()
excelFilePath <- args[5]
outCSVPath <- args[6]
rScriptPath <- args[7]

options(warn = -1)

# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("XLConnect", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("XLConnect", lib = paste(scriptPath, "libraries", sep = "/"))
}


# read excel file
incdat <- readWorksheet(loadWorkbook(excelFilePath), sheet = 1)


# define replacements
repl1 <- cbind(c("\\xc3\\xa4", "\\xc3\\xb6", "\\xc3\\xbc", "\\xc3\\x84", "\\xc3\\x96", "\\xc3\\x9c", "\\xc3\\x9f", "\\x2d", "Dr.", "Prof."),
               c("ae",         "oe",         "ue",         "Ae",         "Oe",         "Ue",         "ss",         "-",     "Dr", "Prof"))
repl2 <- cbind(c("Ã¤", "Ã¶", "Ã¼", "Ã-", "Ão", "ï¿½", "ÃY", "ÃY",  "&#043;", "Dr.", "Prof."),
               c("ae", "oe", "ue", "Oe", "Ue", "ss" , "ss", "ass", "-"     , "Dr", "Prof"))
replAll <- cbind(c("ä", "ö",  "ü",  "Ä",  "Ö",  "Ü",  "ß", "Dr.", "Prof."),
                 c("ae",  "oe", "ue", "Ae", "Oe", "Ue", "ss", "Dr", "Prof"))
replStreets <- cbind(c("strasse", "str.", " ", "Strasse", "Dr.", "Prof"),
                     c("str",     "str",  "",  "str",     "Dr", "Prof"))

origColumns <- character()

# loop over each field
for (c in 1:ncol(incdat)){
  
  # remove na values
  if (T %in% is.na(incdat[,c])){
    incdat[which(is.na(incdat[,c])),c] <- ""
  }
  
  
  # check if field is 'string'
  if (mode(incdat[,c]) == "character"){
    
    
    # replace special characters
    specCharTest1 <- grep(paste(repl1[,1], collapse = "|"), incdat[,c])
    specCharTest2 <- grep(paste(repl2[,1], collapse = "|"), incdat[,c])
    specCharTest3 <- grep(paste(replAll[,1], collapse = "|"), incdat[,c])
    if (length(specCharTest1) > 0){
      
      origColumns <- cbind(origColumns, incdat[,c])
      colnames(origColumns)[ncol(origColumns)] <- "beforeUTFReplacement"
      
      for (r in 1:nrow(repl1)){
        
        incdat[,c] <- gsub(x = incdat[,c], pattern = repl1[r,1], replacement = repl1[r,2])
        
      }
      
    } else if (length(specCharTest2) > 0) {
      
      origColumns <- cbind(origColumns, incdat[,c])
      colnames(origColumns)[ncol(origColumns)] <- "beforeUnicodeReplacement"
      
      for (r in 1:nrow(repl2)){
        
        incdat[,c] <- gsub(x = incdat[,c], pattern = repl2[r,1], replacement = repl2[r,2])
        
      }
      
    } else if (length(specCharTest3) > 0) {
      
      origColumns <- cbind(origColumns, incdat[,c])
      colnames(origColumns)[ncol(origColumns)] <- "beforeGermanSymbolsReplacement"
      
      for (r in 1:nrow(replAll)){
        
        incdat[,c] <- gsub(x = incdat[,c], pattern = replAll[r,1], replacement = replAll[r,2])
        
      }
      
    }
    
    
    # replace street name abbreviations
    specCharTest4 <- grep(paste(replStreets[,1], collapse = "|"), incdat[,c])
    if (length(specCharTest1) > 0){
      
      origColumns <- cbind(origColumns, incdat[,c])
      colnames(origColumns)[ncol(origColumns)] <- "beforeStreetNameReplacement"
      
      for (r in 1:nrow(replStreets)){
        incdat[,c] <- gsub(x = incdat[,c], pattern = replStreets[r,1], replacement = replStreets[r,2])
      }
    }
        
    
    # remove na values
    if (T %in% is.na(incdat[,c])){
      incdat[which(is.na(incdat[,c])),c] <- ""
    }
    
  }
  
}


# add original columns
incdat <- cbind(incdat, origColumns)


# write data to file
write.table(incdat, file = outCSVPath, sep = ";", dec = ".", col.names = T, row.names = F)

# report to ArcGIS
print ("...completed execution of R script")
