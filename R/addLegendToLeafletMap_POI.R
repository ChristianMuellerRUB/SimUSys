# addLegendToLeafletMap_POI.r

# adds a legend to the leaflet map based on datatypes and geometry

addLegendToLeafletMap_POI <- function(thisName){
  
  legendColPOIP <- cColsPOIP_show
  legendColPOIL <- cColsPOIL_show
  legendColPOIPg <- cColsPOIPg_show
  
  if ((length(names(cSpPOIP)) > 0) || (length(names(cSpPOIL)) > 0) || (length(names(cSpPOIPg)) > 0)){
    legendColPOI <<- unique(c(legendColPOIP, legendColPOIL, legendColPOIPg))
    legendColPOI <<- legendColPOI[-which(legendColPOI == "")]
    if (attSel_OPOI == "oGeom"){
      poiPos <<- which(lyrNames[,"rootList"] == "POI")
      legendLabelPOI <<- unique(lyrNames[poiPos,][which(lyrNames[poiPos, "col"] %in% legendColPOI),lan + 3])
      legendTitlePOI <<- paste(labelNames[which(labelNames[,1] == "poisFolder"),lan], ": ",
                              labelNames[which(labelNames[,1] == "topic"),lan], sep = "")
    } else {
      if ((class(legendLabelPOIP) == "factor") || (class(legendLabelPOIL) == "factor") || (class(legendLabelPOIPg) == "factor")){
        legendLabelPOI <<- unique(c(as.character(legendLabelPOIP), as.character(legendLabelPOIL), as.character(legendLabelPOIPg)))
        legendLabelPOI <<- legendLabelPOI[-which(legendLabelPOI == "")]
      } else {
        if (class(legendLabelPOIP) == "numeric"){
          legendLabelPOI <<- legendLabelPOIP
          legendColPOI <<- legendColPOIP
        }
        if (class(legendLabelPOIL) == "numeric"){
          legendLabelPOI <<- legendLabelPOIL
          legendColPOI <<- legendColPOIL
        }
        if (class(legendLabelPOIPg) == "numeric"){
          legendLabelPOI <<- c(as.character(quantile(legendLabelPOIPg, na.rm = T)), "kein Wert")
          legendColPOI <<- unique(legendColPOIPg)
        }
      }
      legendTitlePOI <<- paste(labelNames[which(labelNames[,1] == "poisFolder"),lan], ": ",
                              attSelPOI, sep = "")
    }
  }
}