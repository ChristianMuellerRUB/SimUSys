# regression_analysis_SimUSys.r

regression_analysis_SimUSys <- function(thisy_name_nice, thisx_name_nice, thisRule, performMoransI = T){
  
  
  # get y data
  hit <- which(allAnalAtts[,2] == thisy_name_nice)
  y_inf <- allAnalAtts[hit,]
  y_sp <- get(y_inf[4])
  y_dat <- y_sp@data[,y_inf[1]]
  
  # get x data
  x_dat <- matrix(NA, nrow = length(y_dat), ncol = length(thisx_name_nice), dimnames = list(c(), thisx_name_nice))
  noDataAv <- c()
  noDataAvNames <- c()
  for (x in 1:length(thisx_name_nice)){
    hit <- which(allAnalAtts[,2] == thisx_name_nice[x])
    if (length(hit) > 0){
      x_inf <- allAnalAtts[hit,]
      x_sp <- get(x_inf[4])
      x_dat[,x] <- x_sp@data[,x_inf[1]]
    } else {
      noDataAv <- c(noDataAv, x)
    }
  }
  if (length(noDataAv) > 0){
    noDataAvNames <- thisx_name_nice[noDataAv]
    thisx_name_nice <- thisx_name_nice[-noDataAv]
  }
  
  
  # standardize values
  y_dat_orig <- y_dat
  x_dat_orig <- x_dat
  y_dat <- normalize_fast(y_dat_orig)
  if (ncol(x_dat_orig) > 1){
    x_dat <- normalize_fast(x_dat_orig)[[1]]
  } else {
    x_dat <- normalize_fast(as.vector(x_dat_orig))
    x_dat <- as.matrix(x_dat)
  }
  
  # gather information on invalid rows
  invalidRows <- c()
  invalidRows <- c(invalidRows, which(is.na(y_dat)))
  for (r in 1:nrow(x_dat)){
    if (all(is.na(x_dat[r,]))) invalidRows <- c(invalidRows, r)
  }
  unique(invalidRows)
  
  # reduce sample size if necessary
  if (length(invalidRows) > 0) remains <- (1:length(y_dat))[-unique(invalidRows)] else remains <- 1:length(y_dat)
  if (length(remains) > 12000){
    treatAsInvalid <- sample(remains, length(remains) - 12000, replace = F)
    invalidRows <- c(invalidRows, treatAsInvalid)
  }
    
    
  
  # get information on sample size
  sampleSize <- length(y_dat) - length(invalidRows)
  if (length(invalidRows) > 0){
    y_use <- y_dat[-invalidRows]
    y_sp_use <- y_sp[-invalidRows,]
    x_use <- x_dat[-invalidRows,]
    gw <- PlanungseinheitenAggregiert_total@data[-invalidRows,"NEinw"]
  } else {
    y_use <- y_dat
    y_sp_use <- y_sp
    x_use <- x_dat
    gw <- PlanungseinheitenAggregiert_total@data[,"NEinw"]
  }
  invalidColumns <- c()
  for (c in 1:ncol(x_dat)){
    if (all(is.na(x_dat[,c]))) invalidColumns <- c(invalidColumns, c)
  }
  if (length(invalidColumns) > 0){
    noDataAvNames <- c(noDataAvNames, colnames(x_use)[invalidColumns])
    noDataAvNames <- unique(noDataAvNames)
    x_use <- x_use[,-invalidColumns]
  }
  dat <- cbind(y_use, x_use)
  
  # prepare data container
  addout <- data.frame(Nagelkerke_pseudo_R_squared = NA, AIC = NA, Lambda = NA, LLRatio = NA, pAutoCor = NA, Logllh = NA)
  sumTab <- NA
  
  if (sampleSize < 20){
    warning(paste("Sample size is to small (", sampleSize, ")", sep = ""))
  } else {
  
    try({
    
      # build neighbors
      nbObj <- poly2nb(y_sp_use)
      coords <- coordinates(y_sp_use)
      IDs <- row.names(y_sp_use)
      nbObj <- knn2nb(knearneigh(coords, k = 8), row.names = IDs)
      dsts <- unlist(nbdists(nbObj, coords))
      nbObj2 <- dnearneigh(coords, d1 = 0, d2 = 0.75 * max(dsts), row.names = IDs)
      
      pdf(paste(modDat, "/AnalysenErgebnisse/spatialDependencies_rule_", thisRule, ".pdf", sep = ""))
        plot(nbObj2, coords = coords)
      dev.off()
      
      # build spatial weights
      spw <- nb2listw(nbObj2)
      
      if (performMoransI){
        try({
          # test for spatial autocorrelation
          moransIres <- numeric(ncol(dat))
          Evalue <- numeric(ncol(dat))
          for (m in 1:(ncol(dat))){
            moransIres[m] <- as.numeric(moran.test(na.omit(dat[,m]), listw = spw)$estimate[1])
            Evalue[m] <- -1/((length(na.omit(dat[,m]))) - 1)
          }
          moransIres <- as.data.frame(cbind(Variable = colnames(dat), MoransI = moransIres, EValue = Evalue))
          
          # write moran' I to file
          fileName <- paste(modDat, "/AnalysenErgebnisse/moransI_rule_", thisRule, ".csv", sep = "")
          write.table(moransIres, file = fileName, sep = ";", dec = ".", col.names = T, row.names = F)
        }, silent = T)
      }
      
      
      # train the spatial autoregressive model
      spmodel <- spautolm(y_use ~ x_use, listw = spw, zero.policy = T, weights = gw)
      
      # get results
      sumTab <- summary(spmodel, Nagelkerke = T)$Coef
      if (length(noDataAvNames) > 0){
        for (na in 1:length(noDataAvNames)){
          sumTab <- rbind(sumTab, c(0, 0, 0, 1))
          row.names(sumTab)[nrow(sumTab)] <- paste("x_use", noDataAvNames[na], sep = "")
        }
      }
      row.names(sumTab)[1] <- thisy_name_nice
      row.names(sumTab) <- paste(gsub(row.names(sumTab), pattern = "x_use", replacement = ""), "_rule_", thisRule, sep = "")
      if (ncol(x_dat) == 1) row.names(sumTab)[2] <- paste(colnames(x_dat), "_rule_", thisRule, sep = "")
      
      # write summary table to file
      fileName <- paste(modDat, "/AnalysenErgebnisse/sumTab_rule_", thisRule, ".csv", sep = "")
      write.table(sumTab, file = fileName, sep = ";", dec = ".", col.names = T, row.names = T)
      
      # calculate VIF
      VIF_df <- as.data.frame(x_use)
      colnames(VIF_df) <- paste0("VIF_x_var_", 1:ncol(VIF_df))
      if (ncol(VIF_df) > 1){
        VIF <- vif_func(in_frame = VIF_df, thresh = 15, trace = T)[[2]]
      } else {
        VIF <- data.frame("VIF_x_var_1", 0)
      }
      colnames(VIF) <- c("Var", "VIF")
      fileName <- paste(modDat, "/AnalysenErgebnisse/VIF_rule_", thisRule, ".csv", sep = "")
      write.table(VIF, file = fileName, sep = ";", dec = ".", col.names = T, row.names = F)
      
      addout <- data.frame(Nagelkerke_pseudo_R_squared = summary(spmodel, Nagelkerke = T)$NK,
                           AIC = AIC(spmodel),
                           Lambda = as.numeric(summary(spmodel)[2]),
                           LLRatio = as.numeric(summary(spmodel)$LR1[[1]][1]),
                           pAutoCor = as.numeric(summary(spmodel)$LR1[[1]][3]),
                           Logllh = as.numeric(summary(spmodel)[3]),
                           sampleSize = sampleSize,
                           model_p = NA)
    
    
      # write additionaal information to file
      fileName <- paste(modDat, "/AnalysenErgebnisse/sumTab_addInfo_rule_", thisRule, ".csv", sep = "")
      write.table(addout, file = fileName, sep = ";", dec = ".", col.names = T, row.names = T)
      
      # create informative plots
      plotRegressionCoefficients(sumTab, addout, VIF, thisRule)
      
      if (is.na(sumTab)) cat ("Unable to perform regression analysis...")
    
    }, silent = T)
    
    # message to user in cases when regression did not work as expected
    if (is.na(sumTab)){
      
      showModal(modalDialog(title = labelNames[which(labelNames[,1] == "regressionErrorTitel"),lan],
                            labelNames[which(labelNames[,1] == "regressionError"),lan],
                            footer = modalButton(labelNames[which(labelNames[,1] == "close"),lan]), easyClose = T))
      
    }
    
    return(sumTab)
    
  }
}
