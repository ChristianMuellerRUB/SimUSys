# getInformativeAttributes.r

getInformativeAttributes <- function(thisLayer_nice){
  
  # get full file path
  thisPath <- paste(modDat, "AnalysenErgebnisse", sep = "/")
  
  # get position in layer information table
  lyrNames_pos <- which(lyrNames[,5] == thisLayer_nice)
  if (length(lyrNames_pos) == 0) lyrNames_pos <- which(lyrNames[,6] == thisLayer_nice)
  
  # get layer object variable names
  thisSpVar <- lyrNames[lyrNames_pos, 4]
  thisCol <- lyrNames[lyrNames_pos, "col"]
  thisColVar <- paste(lyrNames[lyrNames_pos, 4], "col", sep = "_")
  
  # try to load .rds-files
  rds_n <- paste0("beforeGame_", thisSpVar, ".rds")
  rds_col_n <- paste0("beforeGame_", thisSpVar, "_col.rds")
  rds_path <- paste(modDat, "savedRObjects", rds_n, sep = "/")
  rds_col_path <- paste(modDat, "savedRObjects", rds_col_n, sep = "/")
  if (file.exists(rds_path)) assign(thisSpVar, readRDS(rds_path), envir = .GlobalEnv)
  if (file.exists(rds_col_path)) assign(paste0(thisSpVar, "_col"), readRDS(rds_col_path), envir = .GlobalEnv)
  
  
  # load spatial data if not yet in environment
  if (((thisSpVar %in% ls(envir = .GlobalEnv)) == F) || ((paste0(thisSpVar, "_col") %in% ls(envir = .GlobalEnv)) == F)){
    
    # read or load data
    getOneSpatialObject(thisSpVar)
    
  }
  
  # get informative attributes
  useObj <- get(thisSpVar)
  valAtts <- colnames(useObj@data)
  valAtts <- valAtts[which(valAtts %in% attNames[,1])]
  outCases <- c()
  for (c in 1:length(valAtts)){
    if (all(is.na(useObj@data[,valAtts[c]]))){
      outCases <- c(outCases, c)
    } else if (all(useObj@data[which(is.na(useObj@data[,valAtts[c]]) == F),valAtts[c]] == 0)){
      outCases <- c(outCases, c)
    }
  }
  if (length(outCases) > 0) valAtts <- valAtts[-outCases]
  
  return(valAtts)
  
}