# loadAllObjects.r

loadAllObjects <- function(modDat, checkTreeList, method = "non_reload", recalculateDistances = T){
  
  # get layer names for distance calculation
  dist_calc_n <- c()
  dist_calc_n <- c(dist_calc_n, lyrNames[which(lyrNames[,"calcEucDist"] == 1), 3+lan])
  dist_calc_n <- c(dist_calc_n, lyrNames[which(lyrNames[,"calcEucDist"] == 1), 5+lan])
  dist_calc_n <- c(dist_calc_n, lyrNames[which(lyrNames[,"calcAccess"] == 1), 3+lan])
  dist_calc_n <- c(dist_calc_n, lyrNames[which(lyrNames[,"calcAccess"] == 1), 5+lan])
  dist_calc_n <- unique(dist_calc_n)
  
  # get all layer names
  all_ln <- unlist(checkTreeList)
  names(all_ln) <- NULL
  
  # get list of saved objects
  all_s <- list.files(paste0(modDat, "/savedRObjects"))
  
  # create container for observation of distance calculation
  dist_calculated <- F
  
  
  # iterate over each layer
  for (n in 1:length(all_ln)){
    
    # get current layer name
    this_ln <- all_ln[n]
    path_n <- lyrNames[which(lyrNames == this_ln, arr.ind = T)[1,1], 7]
    if (path_n == "") path_n <- lyrNames[which(lyrNames == this_ln, arr.ind = T)[1,1], 4]
    rds_n <- paste0("beforeGame_", path_n, ".rds")
    rds_col_n <- paste0("beforeGame_", path_n, "_col.rds")
    rds_path <- paste(modDat, "savedRObjects", rds_n, sep = "/")
    rds_col_path <- paste(modDat, "savedRObjects", rds_col_n, sep = "/")
    
    # reload if specified
    if ((method == "reload") || ((rds_n %in% all_s) == F) || ((rds_col_n %in% all_s) == F)) {
      
      try({
      
        # delete .rds-files
        if (file.exists(rds_path)) unlink(rds_path)
        if (file.exists(rds_col_path)) unlink(rds_col_path)
        if (path_n %in% ls(name = .GlobalEnv)) rm(get(path_n))
        if (paste0(path_n, "_col") %in% ls(name = .GlobalEnv)) rm(get((paste0(path_n, "_col"))))
        
        # load data
        getOneSpatialObject(this_ln)
        
        # save to .rds-files
        if (length(get(this_ln)) > 0){
          saveRDS(get(this_ln), rds_path)
          saveRDS(get(paste0(this_ln, "_col")), rds_col_path)
        }
        
      }, silent = T)
    
    } else {
      
      try({
      
        # read .rds-files
        assign(this_ln, readRDS(rds_path), envir = .GlobalEnv)
        assign(paste0(this_ln, "_col"), readRDS(rds_col_path), envir = .GlobalEnv)
        
      }, silent = T)
      
    }
    
    
    # recalculate distances
    if (recalculateDistances){
      
      # recalculate distances if distances should be calculated for this layer
      if (this_ln %in% dist_calc_n){
        
        # recalculate distances if the layer object is available
        if (this_ln %in% ls(name = .GlobalEnv)){
        
          # recalculate distances if there are objects in this layer
          if (length(get(this_ln)) > 0){
            
            update_Distances(this_ln)
            
            # save information on recalculation of distances
            dist_calculated <- T
          
          }
          
        }
        
      }
      
    }

  }
  
  
  if (dist_calculated){
    
    # save to RDS files
    if (recalculateDistances){
      try({
        saveRDS(LuftlinienDistanzen, paste0(modDat, "/savedRObjects/beforeGame_LuftlinienDistanzen.rds"))
        saveRDS(LuftlinienDistanzen_col, paste0(modDat, "/savedRObjects/beforeGame_LuftlinienDistanzen_col.rds"))
        saveRDS(Erreichbarkeit_mitFahrrad, paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitFahrrad.rds"))
        saveRDS(Erreichbarkeit_mitFahrrad_col, paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitFahrrad_col.rds"))
        saveRDS(Erreichbarkeit_mitPKW, paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitPKW.rds"))
        saveRDS(Erreichbarkeit_mitPKW_col, paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitPKW_col.rds"))
        saveRDS(Erreichbarkeit_zuFuss, paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_zuFuss.rds"))
        saveRDS(Erreichbarkeit_zuFuss_col, paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_zuFuss_col.rds"))
      }, silent = T)
    }
    
  } else {
    
    # try to load distances
    try({
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_LuftlinienDistanzen.rds"))) assign("LuftlinienDistanzen", readRDS(paste0(modDat, "/savedRObjects/beforeGame_LuftlinienDistanzen.rds")), envir = .GlobalEnv)
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_LuftlinienDistanzen_col.rds"))) assign("LuftlinienDistanzen_col", readRDS(paste0(modDat, "/savedRObjects/beforeGame_LuftlinienDistanzen_col.rds")), envir = .GlobalEnv)
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitFahrrad.rds"))) assign("Erreichbarkeit_mitFahrrad", readRDS(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitFahrrad.rds")), envir = .GlobalEnv)
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitFahrrad_col.rds"))) assign("Erreichbarkeit_mitFahrrad_col", readRDS(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitFahrrad_col.rds")), envir = .GlobalEnv)
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitPKW.rds"))) assign("Erreichbarkeit_mitPKW", readRDS(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitPKW.rds")), envir = .GlobalEnv)
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitPKW_col.rds"))) assign("Erreichbarkeit_mitPKW_col", readRDS(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_mitPKW_col.rds")), envir = .GlobalEnv)
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_zuFuss.rds"))) assign("Erreichbarkeit_zuFuss", readRDS(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_zuFuss.rds")), envir = .GlobalEnv)
      if (file.exists(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_zuFuss_col.rds"))) assign("Erreichbarkeit_zuFuss_col", readRDS(paste0(modDat, "/savedRObjects/beforeGame_Erreichbarkeit_zuFuss_col.rds")), envir = .GlobalEnv)
    }, silent = T)
    
  }
    
}