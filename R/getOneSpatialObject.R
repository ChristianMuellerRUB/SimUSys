# getOneSpatialObject.r

getOneSpatialObject <- function(sp_obj_name){
  
  # test if spatial object has already been loaded
  if (((sp_obj_name %in% ls(name = .GlobalEnv)) == F) || ((paste0(sp_obj_name, "_col") %in% ls(name = .GlobalEnv)) == F)){
    
    # get data path
    pos <- which(lyrNames == sp_obj_name, arr.ind = T)
    tempPath <- paste(modDat, lyrNames[pos[1,1],"path"], sep = "/")
    
    # test if file contains features
    nFeatures <- 0
    try(nFeatures <- ogrInfo(dirname(tempPath), strsplit(basename(tempPath), ".", fixed = T)[[1]][1])[1], silent = T) 
    
    # load and project data if it contains features
    if (nFeatures > 0){
      tempSp <- readOGR(dirname(tempPath), strsplit(basename(tempPath), ".", fixed = T)[[1]][1], useC = F)
      tempSp <- spTransform(tempSp, WGSproj)
    } else {
      thisGeomDef <- paste("DefaultGeometry/", datStructTab[which(datStructTab[,"Objektart_N"] == sp_obj_name), "Objektartenbereich"], "_", datStructTab[which(datStructTab[,"Objektart_N"] == sp_obj_name), "Geometry"], "_def.shp", sep = "")
      tempSp <- readOGR(dirname(thisGeomDef), strsplit(basename(thisGeomDef), ".", fixed = T)[[1]][1], useC = F)
      tempSp <- tempSp[-1,]
      tempSp@bbox <- cbind(c(0,0), c(0,0))
      proj4string(tempSp) <- WGSproj
    }
    
    
    # rescale values for spatial attractiveness
    if ("wohlUn" %in% colnames(tempSp@data)){
      temp_data <- tempSp@data
      temp_data[,"wohlUn"] <- rescale(temp_data[,"wohlUn"], to = c(0,1))
      tempSp@data <- temp_data
    }
    
    
    # save spatial object and corresponding colors to global variables
    assign(sp_obj_name, tempSp, envir = .GlobalEnv)
    if (length(tempSp) > 0){
      cols <- rep(lyrNames[which(lyrNames == sp_obj_name, arr.ind = T)[1,1], "col"], times = length(tempSp))
    } else {
      cols <- lyrNames[which(lyrNames == sp_obj_name, arr.ind = T)[1,1], "col"]
    }
    col_obj_name <- paste(sp_obj_name, "col", sep = "_")
    assign(col_obj_name, cols, envir = .GlobalEnv)
    
    # get computer name for variable
    path_n <- lyrNames[which(lyrNames == sp_obj_name, arr.ind = T)[1,1], 7]
    if (path_n == "") path_n <- lyrNames[which(lyrNames == sp_obj_name, arr.ind = T)[1,1], 4]
    path_col_n <- paste0(path_n, "_col")
    
    # save spatial object to .rds-file
    if (sp_obj_name %in% ls(name = .GlobalEnv)) saveRDS(tempSp, paste(saveObjDir, "/beforeGame_", path_n, ".rds", sep = ""))
    if (col_obj_name %in% ls(name = .GlobalEnv)) saveRDS(cols, paste(saveObjDir, "/beforeGame_", path_col_n, ".rds", sep = ""))
    
  }
}