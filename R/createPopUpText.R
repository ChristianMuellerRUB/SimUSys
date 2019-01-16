# createPopUpText.r

# creates a html text for pop ups in leaflet

createPopUpText <- function(id, lat, lng){

  if (class(cSpEnvPg) != "character"){
    pos <- which(cSpEnvPg@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpEnvPg
      showThisAtt <- Env_att
    }
  }
  if (class(cSpEnvL) != "character"){
    pos <- which(cSpEnvL@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpEnvL
      showThisAtt <- Env_att
    }
  }
  if (class(cSpEnvP) != "character"){
    pos <- which(cSpEnvP@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpEnvP
      showThisAtt <- Env_att
    }
  }
  if (class(cSpPlEPg) != "character"){
    pos <- which(cSpPlEPg@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpPlEPg
      showThisAtt <- PlE_att
    }
  }
  if (class(cSpPlEL) != "character"){
    pos <- which(cSpPlEL@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpPlEL
      showThisAtt <- PlE_att
    }
  }
  if (class(cSpPlEP) != "character"){
    pos <- which(cSpPlEP@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpPlEP
      showThisAtt <- PlE_att
    }
  }
  if (class(cSpNetPg) != "character"){
    pos <- which(cSpNetPg@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpNetPg
      showThisAtt <- Net_att
    }
  }
  if (class(cSpNetL) != "character"){
    pos <- which(cSpNetL@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpNetL
      showThisAtt <- Net_att
    }
  }
  if (class(cSpNetP) != "character"){
    pos <- which(cSpNetP@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpNetP
      showThisAtt <- Net_att
    }
  }
  if (class(cSpPOIPg) != "character"){
    pos <- which(cSpPOIPg@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpPOIPg
      showThisAtt <- POI_att
    }
  }
  if (class(cSpPOIL) != "character"){
    pos <- which(cSpPOIL@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpPOIL
      showThisAtt <- POI_att
    }
  }
  if (class(cSpPOIP) != "character"){
    pos <- which(cSpPOIP@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpPOIP
      showThisAtt <- POI_att
    }
  }
  if (class(cSpResPg) != "character"){
    pos <- which(cSpResPg@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpResPg
      showThisAtt <- Res_att
    }
  }
  if (class(cSpResL) != "character"){
    pos <- which(cSpResL@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpResL
      showThisAtt <- Res_att
    }
  }
  if (class(cSpResP) != "character"){
    pos <- which(cSpResP@data[,"cID"] == id)
    if (length(pos) > 0){
      spdat <- cSpResP
      showThisAtt <- Res_att
    }
  }
  
  dat <- spdat@data
  if (length(as.character(dat[id,"ObjArtN"])) == 0){
    showtext <- paste("<h5> </h5>", sep = "")
  } else {
    showtext <- paste("<h5>", as.character(dat[id,"ObjArtN"]), "</h5>", sep = "")
  }
  pos <- which(colnames(dat) %in% showThisAtt)
  if (length(pos) > 0){
    isFirst <- T
    for (i in 1:length(pos)){
      thisAttName <- attNames[which(attNames[,1] == colnames(dat)[pos[i]]), lan]
      thisVal <- dat[id, pos[i]]
      if (class(thisVal) == "numeric") thisVal <- round(thisVal, digits = 2)
      addVal <- as.character(thisVal)
      if (is.na(addVal) == F){
        newEntry <- paste(thisAttName, ": ", addVal, sep = "")
        if (isFirst){
          showtext <- paste(showtext, newEntry, sep = "")
          isFirst <- F
        } else {
          showtext <- paste(showtext, "<br/>", newEntry, sep = "")
        }
      }
    }
  }
  
  return(showtext)
  
}