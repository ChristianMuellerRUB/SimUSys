# repairSpecialCharactersInAttributeTable.r
# repairs special characters in attribute tables of shapefiles

# get input arguments
args <- commandArgs()
shapefilePath <- args[5]
rScriptPath <- args[6]

options(warn = -1)

# load packages
library(foreign, quietly = T, warn.conflicts = F)


# read analysis grid .dbf-table
incDBFPath <- paste(strsplit(shapefilePath, ".", fixed = T)[[1]][1], "dbf", sep = ".")
incdat <- read.dbf(incDBFPath, as.is = T)


# define replacements
repl1 <- cbind(c("\\xc3\\xa4", "\\xc3\\xb6", "\\xc3\\xbc", "\\xc3\\x84", "\\xc3\\x96", "\\xc3\\x9c", "\\xc3\\x9f", "\\x2d"),
               c("ae",         "oe",         "ue",         "Ae",         "Oe",         "Ue",         "ss",         "-"))
repl2 <- cbind(c("Ã¤", "Ã¶", "Ã¼", "Ã-", "Ão", "ï¿½", "ÃY", "ÃY",  "&#043;"),
               c("ae", "oe", "ue", "Oe", "Ue", "ss" , "ss", "ass", "-"))
replAll <- cbind(c("ä", "ö",  "ü",  "Ä",  "Ö",  "Ü",  "ß"),
                 c("ae",  "oe", "ue", "Ae", "Oe", "Ue", "ss"))
replStreets <- cbind(c("strasse", "str.", " ", "Strasse"),
                     c("str",     "str",  "",  "str"))




# loop over each field
for (c in 1:ncol(incdat)){
  
  # check if field is 'string'
  if (mode(incdat[,c]) == "character"){
  
    
    # replace special characters
    specCharTest1 <- grep(paste(repl1[,1], collapse = "|"), incdat[,c])
    specCharTest2 <- grep(paste(repl2[,1], collapse = "|"), incdat[,c])
    specCharTest3 <- grep(paste(replAll[,1], collapse = "|"), incdat[,c])
    if (length(specCharTest1) > 0){
      
      for (r in 1:nrow(repl1)){
    
        incdat[,c] <- gsub(x = incdat[,c], pattern = repl1[r,1], replacement = repl1[r,2])
      
      }

    } else if (length(specCharTest2) > 0) {
    
    
      for (r in 1:nrow(repl2)){
        
        incdat[,c] <- gsub(x = incdat[,c], pattern = repl2[r,1], replacement = repl2[r,2])
        
      }
    
    } else if (length(specCharTest3) > 0) {
      
      
      for (r in 1:nrow(repl1)){
        
        incdat[,c] <- gsub(x = incdat[,c], pattern = replAll[r,1], replacement = replAll[r,2])
        
      }
      
    }
    
    
    # replace street name abbreviations
    for (r in 1:nrow(replStreets)){
      
      incdat[,c] <- gsub(x = incdat[,c], pattern = replStreets[r,1], replacement = replStreets[r,2])
      
    }
    
  }
  
}


# write .dbf to file
write.dbf(incdat, file = paste(strsplit(shapefilePath, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# report to ArcGIS
print ("...completed execution of R script")
