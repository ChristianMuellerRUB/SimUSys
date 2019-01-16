# xlsxTocsv.r

xlsxTocsv <- function(xlsxPath, csvName, sheetNames){
  
  
  try(
    for (i in 1:2){
      if (!require("devtools")) install.packages("devtools")
      if (!require("XLConnectJars")) install.packages("XLConnectJars")
      if (!require("XLConnect")) install.packages("XLConnect")
    }
    , silent = T)
  
  
  # read xlsx
  wb <- loadWorkbook(xlsxPath)
  for (s in 1:length(csvName)){
    csvPath <- csvName
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