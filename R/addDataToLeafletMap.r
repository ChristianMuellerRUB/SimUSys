# addDataToLeafletMap.r

addDataToLeafletMap <- function(thisName, attSel, thisGeom){

  
  # get spatial data collection
  thiscSp <<- paste("cSp", thisName, thisGeom, sep = "")
  
  # get colors collection
  thiscCols <<- paste("cCols", thisName, thisGeom, sep = "")
  
  # get and assign selected attributes
  thisattSel <<- paste("attSel", thisName, sep = "")
  assign(thisattSel, attSel, envir = .GlobalEnv)
  thisattSel_O <<- paste("attSel_O", thisName, sep = "")
  assign(thisattSel_O, attNames[which(attNames[,lan] == get(thisattSel)), 1], envir = .GlobalEnv)
  
  # create data containers for map layout
  thisshow <<- paste(thiscCols, "show", sep = "_")
  thisshow2 <<- paste("legendCol", thisName, thisGeom, sep = "")
  thislegendLabel <<- paste("legendLabel", thisName, thisGeom, sep = "")
  assign(thisshow, get(thiscCols), envir = .GlobalEnv)
  assign(thisshow2, get(thiscCols), envir = .GlobalEnv)
  
  
  # define map layout
  if (length(names(get(thiscSp))) > 0){
    if (T %in% (get(thisattSel_O) != "oGeom")){
      
      # get spatial data
      spdat <<- get(thiscSp)
      
      # specify attribute column for ambiguous cases
      if (length(get(thisattSel_O)) > 1){
        hitpos <- which(get(thisattSel_O) %in% colnames(spdat@data))[1]
        if (length(hitpos) > 0) assign(thisattSel_O, get(thisattSel_O)[hitpos], envir = .GlobalEnv)
      }
      
      # get attribute data
      dat <<- spdat@data[, get(thisattSel_O)]
      
      # diferentiated methods depending on data type
      tempTest <- F
      if (class(dat) != "factor"){
        if (length(unique(quantile(dat, na.rm = T))) < 5) tempTest <- T
      }
      if ((class(dat) == "factor") || tempTest) {
        
        if (class(dat) != "factor"){
          thisPal <- usePal
          cuts <- round(c(min(dat, na.rm = T),
                          seq(quantile(dat, na.rm = T)[4], max(dat, na.rm = T), length.out = 4)))
          if (length(unique(cuts)) < 5) cuts <- unique(round(seq(min(dat, na.rm = T), max(dat, na.rm = T), length.out = 5), digits = 2))
          cuts_nice <- cuts
          if (cuts[length(cuts)] < max(dat, na.rm = T)) cuts[length(cuts)] <- max(dat)
          if (cuts[length(cuts)] == 0){
            assign(thisshow, "#808080", envir = .GlobalEnv)
            assign(thisshow2, "#808080", envir = .GlobalEnv)
            assign(thislegendLabel, "_", envir = .GlobalEnv)
          } else {
            assign(thisshow, colorBin(palette = thisPal, domain = dat, bins = cuts)(dat), envir = .GlobalEnv)
            assign(thisshow2, colorBin(palette = thisPal, domain = dat, bins = cuts)(dat), envir = .GlobalEnv)
            assign(thislegendLabel, cuts_nice[2:5], envir = .GlobalEnv)
          }
          
        } else {
          thisPal <- usePal2
          n <- length(unique(dat))
          assign(thisshow, colorFactor(palette = thisPal, domain = dat, n = n)(dat), envir = .GlobalEnv)
          assign(thisshow2, colorFactor(palette = thisPal, domain = dat, n = n)(dat), envir = .GlobalEnv)
          assign(thislegendLabel, unique(dat), envir = .GlobalEnv)
        }
        
        if (thisGeom == "Pg") assign("addStroke", T, envir = .GlobalEnv)
        if (thisGeom == "L") assign("addStroke", T, envir = .GlobalEnv)
        if (thisGeom == "P") assign("addStroke", T, envir = .GlobalEnv)
      
      } else if (class(dat) == "numeric"){
        cuts <- quantile(dat, na.rm = T)
        assign(thisshow, colorBin(palette = usePal, domain = dat, bins = cuts)(dat), envir = .GlobalEnv)
        assign(thisshow2, colorBin(palette = usePal, domain = dat, bins = cuts)(dat), envir = .GlobalEnv)
        assign(thislegendLabel, dat, envir = .GlobalEnv)
        if (thisGeom == "Pg") assign("addStroke", F, envir = .GlobalEnv)
        if (thisGeom == "L") assign("addStroke", T, envir = .GlobalEnv)
        if (thisGeom == "P") assign("addStroke", T, envir = .GlobalEnv)
        
      } else {
        assign(thisshow, get(thiscCols), envir = .GlobalEnv)
        assign(thisshow2, get(thiscCols), envir = .GlobalEnv)
        if (thisGeom == "Pg") assign("addStroke", T, envir = .GlobalEnv)
        if (thisGeom == "L") assign("addStroke", T, envir = .GlobalEnv)
        if (thisGeom == "P") assign("addStroke", T, envir = .GlobalEnv)
      }
      
    } else {
      assign(thisshow, get(thiscCols), envir = .GlobalEnv)
      assign(thisshow2, get(thiscCols), envir = .GlobalEnv)
      assign(thislegendLabel, "", envir = .GlobalEnv)
      if (thisGeom == "Pg") assign("addStroke", T, envir = .GlobalEnv)
      if (thisGeom == "L") assign("addStroke", T, envir = .GlobalEnv)
      if (thisGeom == "P") assign("addStroke", T, envir = .GlobalEnv)
      
    }
    
  }
  
}
