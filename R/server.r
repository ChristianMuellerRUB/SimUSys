# server.r
# This script defines the behavior of the handlers for the web user interface for SimUSys

function(input, output, session){
  
  # deactivate panels on page load
  js$disableTab("mapTab")
  js$disableTab("rulesTab")
  
  # define dir choose button
  shinyDirChoose(input, "modDatChoose", roots = c('C:/' = "C:/"))
  
  # create reactive values container
  reactVals <<- reactiveValues()
  setReactiveValuesToDefault(reactVals)
    
  # get selected language
  observeEvent(input$lanButton1, {

    if (lan == 2){
      lan <<- 3
    } else if (lan == 3){
      lan <<- 2
    }
    reactVals$lan <- lan
    output$test <- renderUI(h3(labelNames[which(labelNames[,1] == "selModFolder"),lan]))
    
  })
  
  
  # ------------------------------------------------------------------------
  # data handling -----------------------------------------------------------
  # ------------------------------------------------------------------------
  
  # get model data folder
  observeEvent(input$modDatChoose, {
    
    tempDat <- unlist(isolate(input$modDatChoose))
    modDat <<- shinyDirButtonToPath(tempDat)
    reactVals$modDat <<- modDat
    
    if (length(modDat) > 0){
    
        if ((modDat != "") & (as.character(modDat) != "1")){
      
          withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
            
            stdAreaPath <- paste(modDat, "/PlanungsEinheiten/8000_PlanungsEinheiten/8000_001_Untersuchungsgebiet.shp", sep = "/")
            
            # check if the selected data source is valid
            if (file.exists(stdAreaPath)){
              
              stdArea <<- readOGR(dirname(stdAreaPath), strsplit(basename(stdAreaPath), ".", fixed = T)[[1]][1])
              reactVals$stdArea <<- spTransform(stdArea, WGSproj)
              
              # activate panels
              js$enableTab("mapTab")
              js$enableTab("rulesTab")
              
            } else {
              
              # reset selected directory
              modDat <<- ""
              reactVals$modDat <<- modDat
              
              # deactivate panels
              js$disableTab("mapTab")
              js$disableTab("rulesTab")
              
            }
            
          })
      
        }
      
    }
    
  })
  

  observeEvent(reactVals$modDat, {
  
    modDat <<- isolate(reactVals$modDat)
    
    if (length(modDat) > 0){
      
      if ((modDat != "") & (as.character(modDat) != "1")){
          
          withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
            
            # define variables to be saved before the game starts
            saveVars <<- unique(c(lyrNames[,4], lyrNames[,5], lyrNames[,6], lyrNames[,7], lyrNames[,8], lyrNames[,9]))
            saveVars <<- saveVars[which(saveVars != "")]
            saveObjDir <<- paste(reactVals$modDat, "/savedRObjects", sep = "")
            if (dir.exists(saveObjDir) == F) dir.create(saveObjDir)
            
            # get all available analysis grids
            allAnalysisLayers_nice <<- unlist(makeListOfNoneEmptyLayers(checkTreeList[5], modDat))
            allAnalysisLayers_nice <<- rev(unname(allAnalysisLayers_nice))
            allAnalAtts <<- getAllAvailableAnalysisAttributes(allAnalysisLayers_nice)
            reactVals$allAnalAtts <- allAnalAtts
            
            
            # create backup for all available layers and normalize data
            analLyr <- unique(allAnalAtts[,4])
            lapply(1:length(analLyr), function(i){
              sp_temp <- get(analLyr[i])
              data_temp <- sp_temp@data
              data_temp[data_temp == -1] <- NA
              sp_temp@data <- data_temp
              assign(analLyr[i], sp_temp, envir = .GlobalEnv)
              assign(paste0(analLyr[i], "_start"), sp_temp, envir = .GlobalEnv)
              norm_temp <- normalize_fast(as.matrix(data_temp[,-1]))
              assign(paste0(analLyr[i], "_origrange"), norm_temp[[3]], envir = .GlobalEnv)
              norm_temp <- norm_temp[[1]]
              norm_out <- cbind(grid_ID = sp_temp@data[,1], norm_temp)
              sp_temp@data <- as.data.frame(norm_out)
              assign(paste0(analLyr[i], "_normalized"), sp_temp, envir = .GlobalEnv)
            })
            
            # pre-build first rule (spatial attractiveness)
            allRuleParameters <<- isolate(reactVals$allRuleParameters)
            hits <- which(allRuleParameters[,6] %in% allAnalAtts[,2])
            allRuleParameters <<- allRuleParameters[hits,]
            reactVals$allRuleParameters <<- allRuleParameters
            
        })
      }
    }
  })
  
  output$selTxt <- renderText({reactVals$modDat})
    

  # load all layers
  observeEvent(reactVals$modDat, {
   
    if (preload == T){
      
      modDat <<- isolate(reactVals$modDat)
      
      if ((modDat != "") & (as.character(modDat) != "1")){
      
        withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
        
          loadAllObjects(modDat = modDat, checkTreeList = checkTreeList, method = layer_load_method, recalculateDistances = recalculateDistances)
          
        })
        
      }
      
    }
  })
  
  # get layer from checkbox tree (environment)
  output$Envtree <- renderTree({
   
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
      env_avLyr <<- makeListOfNoneEmptyLayers(checkTreeList[4], reactVals$modDat)
    })
  })
  output$showEnvattSel <- reactive(if (length(get_selected(input$Envtree)) > 0) TRUE else FALSE)
  outputOptions(output, 'showEnvattSel', suspendWhenHidden = FALSE)
  
  
  # get layer from checkbox tree (POI)
  output$POItree <- renderTree({
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.2, {
      poi_avLyr <<- makeListOfNoneEmptyLayers(checkTreeList[1], reactVals$modDat)
    })
  })
  output$showPOIattSel <- reactive(if (length(get_selected(input$POItree)) > 0) TRUE else FALSE)
  outputOptions(output, 'showPOIattSel', suspendWhenHidden = FALSE)
  
  # get layer from checkbox tree (planning entities)
  output$PlEtree <- renderTree({
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.4, {
      plE_avLyr <<- makeListOfNoneEmptyLayers(checkTreeList[2], reactVals$modDat)
    })
  })
  output$showPlEattSel <- reactive(if (length(get_selected(input$PlEtree)) > 0) TRUE else FALSE)
  outputOptions(output, 'showPlEattSel', suspendWhenHidden = FALSE)
  
  
  # get layer from checkbox tree (networks)
  output$Nettree <- renderTree({
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.6, {
      net_avLyr <<- makeListOfNoneEmptyLayers(checkTreeList[3], reactVals$modDat)
    })
  })
  output$showNetattSel <- reactive(if (length(get_selected(input$Nettree)) > 0) TRUE else FALSE)
  outputOptions(output, 'showNetattSel', suspendWhenHidden = FALSE)
  
  
  # get layer from checkbox tree (analysis and results)
  output$Restree <- renderTree({
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.8, {
      res_avLyr <<- makeListOfNoneEmptyLayers(checkTreeList[5], reactVals$modDat)
    })
  })
  output$showResattSel <- reactive(if (length(get_selected(input$Restree)) > 0) TRUE else FALSE)
  outputOptions(output, 'showResattSel', suspendWhenHidden = FALSE)
  
  
  # get spatial objects and colors for each selected layer (environment)
  observeEvent(input$Envtree, {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 1.0, {
    
      setAllContainersToDefault(method = "full")
      getSpatialObjectsFromSelectTree(input$Envtree, "Env", reactVals)
      
      # update attribute selection
      sel <- NULL
      if ("Lage/Geometrie" %in% Env_att_nice) sel <- "Lage/Geometrie"
      if ("Einwohneranzahl" %in% Env_att_nice) sel <- "Einwohneranzahl"
      for (i in 1:length(Env_att_nice)){
        pos <- grep(x = Env_att_nice[i], pattern = "Raumattraktivit")
        if (length(pos) > 0) sel <- Env_att_nice[i]
      }
      updateSelectInput(session, inputId = "EnvattSel", label = NULL,
                        choices = sort(Env_att_nice), selected = sel)
    })
    
  })
  
  # get spatial objects and colors for each selected layer (networks)
  observeEvent(input$Nettree, {
   
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0, {
    
      setAllContainersToDefault(method = "full")
      getSpatialObjectsFromSelectTree(input$Nettree, "Net", reactVals)
      
      # update attribute selection
      sel <- NULL
      if ("Lage/Geometrie" %in% Net_att_nice) sel <- "Lage/Geometrie"
      updateSelectInput(session, inputId = "NetattSel", label = NULL,
                        choices = sort(Net_att_nice), selected = sel)
      
    })
    
  })
  
  
  # get spatial objects and colors for each selected layer (planing entities)
  observeEvent(input$PlEtree, {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0, {
    
      setAllContainersToDefault(method = "full")
      getSpatialObjectsFromSelectTree(input$PlEtree, "PlE", reactVals)
      
      # update attribute selection
      sel <- NULL
      if ("Lage/Geometrie" %in% PlE_att_nice) sel <- "Lage/Geometrie"
      updateSelectInput(session, inputId = "PlEattSel", label = NULL,
                        choices = sort(PlE_att_nice), selected = sel)
      
      
    })
      
  })
      
  # get spatial objects and colors for each selected layer (POI)
  observeEvent(input$POItree, {
   
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0, {
    
      setAllContainersToDefault(method = "full")
      getSpatialObjectsFromSelectTree(input$POItree, "POI", reactVals)
      
      # update attribute selection
      sel <- NULL
      if ("Lage/Geometrie" %in% POI_att_nice) sel <- "Lage/Geometrie"
      updateSelectInput(session, inputId = "POIattSel", label = NULL,
                        choices = sort(POI_att_nice), selected = sel)
      
    })
    
  })
  
  # get spatial objects and colors for each selected layer (analyses and results)
  observeEvent(input$Restree, {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0, {
      
      # setAllContainersToDefault(method = "colors")
      setAllContainersToDefault(method = "full")
      getSpatialObjectsFromSelectTree(input$Restree, "Res", reactVals)
      
      # update attribute selection
      sel <- NULL
      if ("Lage/Geometrie" %in% Res_att_nice) sel <- "Lage/Geometrie"
      updateSelectInput(session, inputId = "ResattSel", label = NULL,
                        choices = sort(Res_att_nice), selected = sel)
      
      
    })
    
  })
    
    
  # create a map ------------------------------------------------------
  output$map <- renderLeaflet({
    # output$selTxt2 <- renderText({
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0, {
    
      # get study area
      stdArea <- reactVals$stdArea
      
      # build map with backgroud
      thisMap <- leaflet() %>%
        addProviderTiles("OpenStreetMap.BlackAndWhite", group = "OSM Black & White") %>%
        addProviderTiles("CartoDB.DarkMatterNoLabels", group = "Dark") %>%
        addProviderTiles("OpenStreetMap.DE", group = "OpenStreetMap") %>%
        addProviderTiles("OpenStreetMap.Mapnik", group = "OSM Mapnik") %>%
        addProviderTiles("OpenStreetMap.HOT", group = "OSM HOT") %>%
        addProviderTiles("OpenTopoMap", group = "OpenTopoMap") %>%
        addProviderTiles("Thunderforest.OpenCycleMap", group = "OpenCycleMap") %>%
        addProviderTiles("Thunderforest.Transport", group = "Transport") %>%
        addProviderTiles("Thunderforest.TransportDark", group = "Transport Dark") %>%
        addProviderTiles("Thunderforest.Landscape", group = "Landscape") %>%
        addProviderTiles("Thunderforest.Outdoors", group = "Outdoors") %>%
        addProviderTiles("OpenMapSurfer.Grayscale", group = "Grayscale") %>%
        addProviderTiles("CartoDB.Positron", group = "Positron") %>%
        addProviderTiles("Hydda.Full", group = "Hydda Full") %>%
        addProviderTiles("Hydda.Base", group = "Hydda Base") %>%
        addProviderTiles("Stamen.Watercolor", group = "Watercolor") %>%
        addProviderTiles("Stamen.Terrain", group = "Terrain") %>%
        addProviderTiles("Stamen.TerrainBackground", group = "TerrainBackground") %>%
        addProviderTiles("NASAGIBS.ViirsEarthAtNight2012", group = "Night") %>%
        addProviderTiles("OpenWeatherMap.Clouds", group = "Clouds") %>%
        addProviderTiles("OpenWeatherMap.Pressure", group = "Pressure") %>%
        addProviderTiles("OpenWeatherMap.Wind", group = "Wind") %>%
        addProviderTiles("NASAGIBS.ModisTerraSnowCover", group = "Snow") %>%
        
        addWMSTiles("http://www.wms.nrw.de/geobasis/wms_nw_dtk?", layers = "wms_nw_dtk", group = "Topographische Karte (DTK)") %>%
        addWMSTiles("http://www.wms.nrw.de/geobasis/wms_nw_dtk10?", layers = "wms_nw_dtk10", group = "DTK 10") %>%
        addWMSTiles("http://www.wms.nrw.de/geobasis/wms_nw_dtk25?", layers = "wms_nw_dtk25", group = "DTK 25") %>%
        addWMSTiles("https://www.wms.nrw.de/geobasis/wms_nw_dop20?", layers = "wms_nw_dop20", group = "Luftbild NRW") %>%
        addWMSTiles("http://geodaten.metropoleruhr.de/dop/dop?", layers = "dop", group = "Luftbild Ruhrgebiet") %>%
        addWMSTiles("http://www.wms.nrw.de/geobasis/wms_nw_dgm-schummerung?", layers = "wms_nw_dgm-schummerung", group = "Schummerung") %>%
        
        fitBounds(
          lng1 = stdArea@bbox[1, 1],
          lng2 = stdArea@bbox[1, 2],
          lat1 = stdArea@bbox[2, 1],
          lat2 = stdArea@bbox[2, 2]
        ) %>% 
        addLayersControl(
          baseGroups = c("OSM Black & White", "Dark", "OpenStreetMap", "OSM Mapnik", "OSM HOT", "OpenTopoMap",
                         "OpenCycleMap", "Transport", "Transport Dark", "Landscape", "Outdoors", "Grayscale",
                         "Positron", "Hydda Full", "Hydda Base", "Watercolor", "Terrain", "TerrainBackground",
                         "Night", "Clouds", "Pressure", "Wind", "Snow", "Topographische Karte (DTK)", "DTK 10",
                         "DTK 25", "Luftbild NRW", "Luftbild Ruhrgebiet", "Schummerung"), 
          options = layersControlOptions(collapsed = T),
          position = "bottomleft"
        )
      
      
      # define color palette
      usePal <<- "Blues"
      usePal2 <<- "Set3"
      
      
      # add data if at least one layer is selected which contains data ----------------------------------------------
      
      # analyses and results
      if (length(names(reactVals$cSpResPg)) > 0) {
        addDataToLeafletMap(thisName = "Res", attSel = input$ResattSel, thisGeom = "Pg")
        thisMap <- addPolygons(map = thisMap, data = reactVals$cSpResPg, stroke = addStroke, color = "white",
                               fillColor = cColsResPg_show, weight = 1, opacity = 0.6, fillOpacity = 0.6,
                               layerId = reactVals$cSpResPg@data[, "cID"])
      } else {
        legendLabelResPg <<- ""
        cColsResPg_show <<- ""
      }
      if (length(names(reactVals$cSpResL)) > 0) {
        addDataToLeafletMap(thisName = "Res", attSel = input$ResattSel, thisGeom = "L")
        thisMap <- addPolylines(map = thisMap, data = reactVals$cSpResL, stroke = addStroke, weight = 1,
                                color = cColsResL_show, opacity = 0.9, fillOpacity = 0.9,
                                layerId = reactVals$cSpResL@data[, "cID"])
      } else {
        legendLabelResL <<- ""
        cColsResL_show <<- ""
      }
      if (length(names(reactVals$cSpResP)) > 0) {
        addDataToLeafletMap(thisName = "Res", attSel = input$ResattSel, thisGeom = "P")
        thisMap <- addCircleMarkers(map = thisMap, data = reactVals$cSpResP, radius = 3, stroke = addStroke,
                                    color = cColsResP_show, fillColor = cColsResP_show, opacity = 0.9, fillOpacity = 0.9,
                                    layerId = reactVals$cSpResP@data[, "cID"])
      } else {
        legendLabelResP <<- ""
        cColsResP_show <<- ""
      }
      
      # environment
      if (length(names(reactVals$cSpEnvPg)) > 0) {
        addDataToLeafletMap(thisName = "Env", attSel = input$EnvattSel, thisGeom = "Pg")
        thisMap <- addPolygons(map = thisMap, data = reactVals$cSpEnvPg, stroke = addStroke, color = "white",
                               fillColor = cColsEnvPg_show, weight = 1, opacity = 0.6, fillOpacity = 0.6,
                               layerId = reactVals$cSpEnvPg@data[, "cID"])
      } else {
        legendLabelEnvPg <<- ""
        cColsEnvPg_show <<- ""
      }
      if (length(names(reactVals$cSpEnvL)) > 0) {
        addDataToLeafletMap(thisName = "Env", attSel = input$EnvattSel, thisGeom = "L")
        thisMap <- addPolylines(map = thisMap, data = reactVals$cSpEnvL, stroke = addStroke, weight = 1,
                                color = cColsEnvL_show, opacity = 0.9, fillOpacity = 0.9,
                                layerId = reactVals$cSpEnvL@data[, "cID"])
      } else {
        legendLabelEnvL <<- ""
        cColsEnvL_show <<- ""
      }
      if (length(names(reactVals$cSpEnvP)) > 0) {
        addDataToLeafletMap(thisName = "Env", attSel = input$EnvattSel, thisGeom = "P")
        thisMap <- addCircleMarkers(map = thisMap,data = reactVals$cSpEnvP, radius = 3, stroke = addStroke,
                                    color = cColsEnvP_show, fillColor = cColsEnvP_show, opacity = 0.9, fillOpacity = 0.9,
                                    layerId = reactVals$cSpEnvP@data[, "cID"])
      } else {
        legendLabelEnvP <<- ""
        cColsEnvP_show <<- ""
      }
      
      
      # planning entities
      if (length(names(reactVals$cSpPlEPg)) > 0) {
        addDataToLeafletMap(thisName = "PlE", attSel = input$PlEattSel, thisGeom = "Pg")
        thisMap <- addPolygons(map = thisMap, data = reactVals$cSpPlEPg, stroke = addStroke, color = "white",
                               fillColor = cColsPlEPg_show, weight = 1, opacity = 0.6, fillOpacity = 0.6,
                               layerId = reactVals$cSpPlEPg@data[, "cID"])
      } else {
        legendLabelPlEPg <<- ""
        cColsPlEPg_show <<- ""
      }
      if (length(names(reactVals$cSpPlEL)) > 0) {
        addDataToLeafletMap(thisName = "PlE", attSel = input$PlEattSel, thisGeom = "L")
        thisMap <- addPolylines(map = thisMap, data = reactVals$cSpPlEL, stroke = addStroke, weight = 1,
                                color = cColsPlEL_show, opacity = 0.9, fillOpacity = 0.9,
                                layerId = reactVals$cSpPlEL@data[, "cID"])
      } else {
        legendLabelPlEL <<- ""
        cColsPlEL_show <<- ""
      }
      if (length(names(reactVals$cSpPlEP)) > 0) {
        addDataToLeafletMap(thisName = "PlE", attSel = input$PlEattSel, thisGeom = "P")
        thisMap <- addCircleMarkers(map = thisMap, data = reactVals$cSpPlEP, radius = 3, stroke = addStroke,
                                    color = cColsPlEP_show, fillColor = cColsPlEP_show, opacity = 0.9, fillOpacity = 0.9,
                                    layerId = reactVals$cSpPlEP@data[, "cID"])
      } else {
        legendLabelPlEP <<- ""
        cColsPlEP_show <<- ""
      }
      
      # networks
      if (length(names(reactVals$cSpNetPg)) > 0) {
        addDataToLeafletMap(thisName = "Net", attSel = input$NetattSel, thisGeom = "Pg")
        thisMap <-
          addPolygons(map = thisMap, data = reactVals$cSpNetPg, stroke = addStroke, color = "white",
                      fillColor = cColsNetPg_show, weight = 1, opacity = 0.6, fillOpacity = 0.6,
                      layerId = reactVals$cSpNetPg@data[, "cID"])
      } else {
        legendLabelNetPg <<- ""
        cColsNetPg_show <<- ""
      }
      if (length(names(reactVals$cSpNetL)) > 0) {
        addDataToLeafletMap(thisName = "Net", attSel = input$NetattSel, thisGeom = "L")
        thisMap <-
          addPolylines(map = thisMap, data = reactVals$cSpNetL, stroke = addStroke, weight = 1,
                       color = cColsNetL_show, opacity = 0.9, fillOpacity = 0.9,
                       layerId = reactVals$cSpNetL@data[, "cID"])
      } else {
        legendLabelNetL <<- ""
        cColsNetL_show <<- ""
      }
      if (length(names(reactVals$cSpNetP)) > 0) {
        addDataToLeafletMap(thisName = "Net", attSel = input$NetattSel, thisGeom = "P")
        thisMap <-
          addCircleMarkers(map = thisMap, data = reactVals$cSpNetP, radius = 3, stroke = addStroke,
                           color = cColsNetP_show, fillColor = cColsNetP_show, opacity = 0.9, fillOpacity = 0.9,
                           layerId = reactVals$cSpNetP@data[, "cID"])
      } else {
        legendLabelNetP <<- ""
        cColsNetP_show <<- ""
      }
      
      # POI
      if (length(names(reactVals$cSpPOIPg)) > 0) {
        addDataToLeafletMap(thisName = "POI", attSel = input$POIattSel, thisGeom = "Pg")
        thisMap <-
          addPolygons(map = thisMap, data = reactVals$cSpPOIPg, stroke = addStroke, color = "white",
                      fillColor = cColsPOIPg_show, weight = 1, opacity = 0.6, fillOpacity = 0.6,
                      layerId = reactVals$cSpPOIPg@data[, "cID"])
      } else {
        legendLabelPOIPg <<- ""
        cColsPOIPg_show <<- ""
      }
      if (length(names(reactVals$cSpPOIL)) > 0) {
        addDataToLeafletMap(thisName = "POI", attSel = input$POIattSel, thisGeom = "L")
        thisMap <- addPolylines(map = thisMap, data = reactVals$cSpPOIL, stroke = addStroke, weight = 1,
                                color = cColsPOIL_show, opacity = 0.9, fillOpacity = 0.9,
                                layerId = reactVals$cSpPOIL@data[, "cID"])
      } else {
        legendLabelPOIL <<- ""
        cColsPOIL_show <<- ""
      }
      if (length(names(reactVals$cSpPOIP)) > 0) {
        addDataToLeafletMap(thisName = "POI", attSel = input$POIattSel, thisGeom = "P" )
        thisMap <- addCircleMarkers(map = thisMap, data = reactVals$cSpPOIP, radius = 3, stroke = addStroke,
                                    color = cColsPOIP_show, fillColor = cColsPOIP_show, opacity = 0.9, fillOpacity = 0.9,
                                    layerId = reactVals$cSpPOIP@data[, "cID"])
      } else {
        legendLabelPOIP <<- ""
        cColsPOIP_show <<- ""
      }
      
      
      # add legends ----------------------------------------------
      
      # Analyses and results
      if ((length(names(cSpResP)) > 0) ||
          (length(names(cSpResL)) > 0) || (length(names(cSpResPg)) > 0)) {
        if (attSel_ORes != "oGeom") {
          legendTitleRes <- paste(labelNames[which(labelNames[, 1] == "analysisResFolder"), lan], ": ", attSelRes, sep = "")
          addLegendToLeafletMap("Res")
          thisMap <- addLegend(map = thisMap, colors = legendColRes, label = legendLabelRes, title = legendTitleRes)
        }
      }
      
      # POI
      if ((length(names(cSpPOIP)) > 0) ||
          (length(names(cSpPOIL)) > 0) || (length(names(cSpPOIPg)) > 0)) {
        addLegendToLeafletMap_POI("POI")
        thisMap <- addLegend(map = thisMap, colors = legendColPOI, label = legendLabelPOI, title = legendTitlePOI)
      }
      
      # Planning entities
      if ((length(names(cSpPlEP)) > 0) ||
          (length(names(cSpPlEL)) > 0) || (length(names(cSpPlEPg)) > 0)) {
        if (attSel_OPlE != "oGeom") {
          legendTitlePlE <- paste(labelNames[which(labelNames[, 1] == "planingEntitiesFolder"), lan], ": ", attSelPlE, sep = "")
          addLegendToLeafletMap("PlE")
          thisMap <- addLegend(map = thisMap, colors = legendColPlE, label = legendLabelPlE, title = legendTitlePlE)
        }
      }
      
      
      # Networks
      if ((length(names(cSpNetP)) > 0) ||
          (length(names(cSpNetL)) > 0) || (length(names(cSpNetPg)) > 0)) {
        if (attSel_ONet != "oGeom") {
          legendTitleNet <- paste(labelNames[which(labelNames[, 1] == "networkFolder"), lan], ": ", attSelNet, sep = "")
          addLegendToLeafletMap("Net")
          thisMap <- addLegend(map = thisMap, colors = legendColNet, label = legendLabelNet, title = legendTitleNet)
        }
      }
      
      # Environment
      if ((length(names(cSpEnvP)) > 0) ||
          (length(names(cSpEnvL)) > 0) || (length(names(cSpEnvPg)) > 0)) {
        if (attSel_OEnv != "oGeom") {
          legendTitleEnv <- paste(labelNames[which(labelNames[, 1] == "environFolder"), lan], ": ", attSelEnv, sep = "")
          addLegendToLeafletMap("Env")
          thisMap <- addLegend(map = thisMap, colors = legendColEnv, label = legendLabelEnv, title = legendTitleEnv)
        }
      }
      
      
      
      # add new facility
      if (class(reactVals$temp_fac) != "character") {
        thisMap <- addCircleMarkers(map = thisMap, data = temp_fac, radius = 4, stroke = F, color = "lightblue",
                                    fillColor = "lightblue", opacity = 0.9, fillOpacity = 0.9)
      }
      
      # show map
      thisMap
      
    })    
    
  })


  # show pop-ups
  popUpOberserver_shape <- observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_shape_click
    if (is.null(event))
      return()

    isolate({
      showtext <- createPopUpText(event$id, event$lat, event$lng)
      leafletProxy("map") %>% addPopups(event$lng, event$lat, showtext, layerId = event$id)
    })
  })
  popUpOberserver_point <- observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_marker_click
    if (is.null(event))
      return()

    isolate({
      showtext <- createPopUpText(event$id, event$lat, event$lng)
      leafletProxy("map") %>% addPopups(event$lng, event$lat, showtext, layerId = event$id)
    })
  })



  # ------------------------------------------------------------------------
  # create dynamic rules page ----------------------------------------------
  # ------------------------------------------------------------------------
  
  # add new rule
  observeEvent(input$addRule, {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      reactVals$nRules <- reactVals$nRules + 1
      for (i in 1:reactVals$nRules){
        thisRule <- paste("tabPanel_rule", i, sep = "_")
        if ((thisRule %in% allRules_ids) == F) allRules_ids <<- c(thisRule, allRules_ids)
      }
      reactVals$activeRule <- paste("tabPanel_rule", i, sep = "_")
      
    })
  })
  
  # remove last rule
  observeEvent(input$rmvRule, {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
      
      reactVals$nRules <- reactVals$nRules - 1
      for (i in 1:reactVals$nRules){
        thisRule <- paste("tabPanel_rule", i, sep = "_")
        if ((thisRule %in% allRules_ids) == F) allRules_ids <<- c(thisRule, allRules_ids)
      }
      
      # remove rule set from rules overview
      allRuleParameters <- isolate(reactVals$allRuleParameters)
      allRuleParameters <- allRuleParameters[which(allRuleParameters[,1] <= isolate(reactVals$nRules)),]
      reactVals$allRuleParameters <- allRuleParameters
      warning("clicked")
      
    })
  })
  
  # remove last slider
  observeEvent(input[[paste("rmvSlider", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], sep = "_")]], {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      allRuleParameters <<- reactVals$allRuleParameters
      thisR <<- strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3]
      remPos <- which(allRuleParameters[,1] == thisR)
      if (length(remPos) > 0){
        pa_temp <- as.matrix(allRuleParameters[-remPos[length(remPos)],])
        if (ncol(pa_temp) != ncol(allRuleParameters)) pa_temp <- t(pa_temp)
        allRuleParameters <<- pa_temp
        allRuleParameters <<- allRuleParameters
        reactVals$allRuleParameters <- allRuleParameters
      }
      
    })
  })
  
  # observe y variable
  observeEvent(input[[paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "y", sep = "_")]], {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      allRuleParameters <<- reactVals$allRuleParameters
      thisR <<- strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3]
      remPos <- which(allRuleParameters[,1] == thisR)
      if (length(remPos) > 0){
        allRuleParameters[remPos, 4] <- input[[paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "y", sep = "_")]]
        for (l in 1:length(remPos)){
          allRuleParameters[remPos[l],7] <- paste(allRuleParameters[remPos[l], 1], allRuleParameters[remPos[l], 2], allRuleParameters[remPos[l], 3], allRuleParameters[remPos[l], 4], allRuleParameters[remPos[l], 5], allRuleParameters[remPos[l], 6], collapse = "_")
        }
        allRuleParameters <<- allRuleParameters
        reactVals$allRuleParameters <- allRuleParameters
      }
      reactVals$lastYvar_sel <- input[[paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "y", sep = "_")]]
      
    })
  })
  
  
  # get last clicked tab and save information on defined rules
  observeEvent(input$thisNavList, {
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      reactVals$activeRule <- input$thisNavList
      if ((reactVals$lastRule %in% allRules_ids) == F) allRules_ids <<- c(allRules_ids, reactVals$lastRule)
      if ((T %in% allRules_ids != "") && ("" %in% allRules_ids)) allRules_ids <<- allRules_ids[-which(allRules_ids == "")]
    
    })
  })

  # observe last clicked independent variable
  observeEvent(input[[paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "xSel", sep = "_")]],{
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      reactVals$lastXvar_sel <<- input[[paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "xSel", sep = "_")]]
      if ((reactVals$lastXvar_sel != addText) && (reactVals$lastXvar_sel != plsChoose)){
        thisxID <- paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "xSel", sep = "_")
        thisyID <- paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "y", sep = "_")
        thisxInput <<- input[[thisxID]]
        thisyInput <<- input[[thisyID]]
        reactVals$lastXvar <- thisxInput
        reactVals$lastXvar_id <- thisxID
        allRuleParameters <- reactVals$allRuleParameters
        val1 <<- strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3]
        val2 <<- reactVals$activeRule
        val3 <<- thisyID
        val4 <<- thisyInput
        val5 <<- thisxID
        val6 <<- thisxInput
        val7 <<- paste(val1, val2, val3, val4, val5, val6, collapse = "_")
        if ((val7 %in% paste(allRuleParameters[nrow(allRuleParameters), 1:6], collapse = "_")) == F){
          allRuleParameters <- rbind(allRuleParameters, NA)
          allRuleParameters[nrow(allRuleParameters),1] <- val1
          allRuleParameters[nrow(allRuleParameters),2] <- val2
          allRuleParameters[nrow(allRuleParameters),3] <- val3
          allRuleParameters[nrow(allRuleParameters),4] <- val4
          allRuleParameters[nrow(allRuleParameters),5] <- val5
          allRuleParameters[nrow(allRuleParameters),6] <- val6
          allRuleParameters[nrow(allRuleParameters),7] <- val7
          allRuleParameters[nrow(allRuleParameters),8] <- paste("xSlider", nrow(allRuleParameters), sep = "_")
          allRuleParameters[nrow(allRuleParameters),9] <- paste("xSlider", allRuleParameters[nrow(allRuleParameters),6], "rule", allRuleParameters[nrow(allRuleParameters),1], sep = "_")
          allRuleParameters[nrow(allRuleParameters),10] <- "0" 
          allRuleParameters[nrow(allRuleParameters),11] <- "-1" 
          allRuleParameters[nrow(allRuleParameters),12] <- "1"
          allRuleParameters[nrow(allRuleParameters),13] <- "1"
          allRuleParameters <<- allRuleParameters
          reactVals$allRuleParameters <<- allRuleParameters
        }
      }
      reactVals$lastXvar_sel <- input[[paste("rule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], "xSel", sep = "_")]]
      
    })
  })
  
  # observe overview table
  observeEvent(reactVals$allRuleParameters,{
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      allRuleParameters <<- reactVals$allRuleParameters
      rUni <- unique(allRuleParameters[,1])
      yOverview <- matrix(NA, nrow = 0, ncol = 9, dimnames = list(c(), c("rule_num", "rule_id", "yvar_id", "yvar_name", "xvar_ids", "xvar_names", "y_allx", "preDatAvailable", "yIntersect")))
      for (r in 1:length(rUni)){
        hits <- which(allRuleParameters[,1] == r)
        yOverview <- rbind(yOverview, NA)
        yOverview[r,1] <- allRuleParameters[hits[1], 1]
        yOverview[r,2] <- allRuleParameters[hits[1], 2]
        yOverview[r,3] <- allRuleParameters[hits[1], 3]
        yOverview[r,4] <- allRuleParameters[hits[1], 4]
        yOverview[r,5] <- paste(allRuleParameters[hits, 5], collapse = ";")
        yOverview[r,6] <- paste(allRuleParameters[hits, 6], collapse = ";")
        yOverview[r,7] <- paste(c(yOverview[r,4], yOverview[r,6]), collapse = ";")
        pos <- which(preDefAv[,1] == yOverview[r,4])
        if (length(pos) > 0){
          yOverview[r,8] <- paste(preDefAv[pos,2], collapse = ";")
        } else {
          yOverview[r,8] <- ""
        }
        yOverview[r,9] <- allRuleParameters[hits[1], 13]
        
      }
      yOverview <<- yOverview
      reactVals$yOverview <- yOverview
      
    })
  })
    
  
  # render rule header
  output$ruleHeader <- renderUI({
    well_args <- list(id = "addRemRules", class = "panel panel-default", fixed = TRUE, align = "center")
    well_args[[length(well_args)+1]] <- actionButton(inputId = "addRule", label = labelNames[which(labelNames[,1] == "addRule"),lan])
    if (reactVals$nRules > 1){
      well_args[[length(well_args)+1]] <- actionButton(inputId = "rmvRule", label = labelNames[which(labelNames[,1] == "rmvRule"),lan])
    }
    do.call(wellPanel, well_args)
  })
  
        
  # start output
  output$rulesPage <- renderUI({
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      myTabPanels <- list()
      for(r in 1:reactVals$nRules){
        yOverview <- reactVals$yOverview
        allRuleParameters <- reactVals$allRuleParameters
        pos <- which(allRuleParameters[,1] == as.character(r))
        addSlider_names <- ""
        addSlider_ids <- ""
        if (length(pos) > 0){
          addSlider_names <- allRuleParameters[pos, 6]
          addSlider_ids <- allRuleParameters[pos, 8]
          thisYPreset <- allRuleParameters[pos, 4][1]
          preDatAvailable <- yOverview[as.numeric(r),8]
          slider_vals <- allRuleParameters[pos, 10]
          slider_mins <- allRuleParameters[pos, 11]
          slider_maxs <- allRuleParameters[pos, 12]
        }
          
        myTabPanels[[r]] <- createRulePanel(r, addSlider_names, addSlider_ids, thisYPreset, reactVals$lastxvar_sel, preDatAvailable, slider_vals, slider_mins, slider_maxs)
    
      }
      myTabPanels <- append(list(id = "thisNavList", selected = reactVals$activeRule), myTabPanels)
      
      do.call(navlistPanel, myTabPanels)
      
    })
      
  })
  
  
  
  # handle manual input
  observe({

    allRuleParameters <- reactVals$allRuleParameters
    lapply(1:nrow(allRuleParameters), function(s){
      observeEvent(input[[allRuleParameters[s,8]]], ignoreInit = T,{
        newVal <<- as.character(input[[allRuleParameters[s,8]]])
        allRuleParameters[s,10] <- newVal
        allRuleParameters <<- allRuleParameters
        reactVals$allRuleParameters <- allRuleParameters
      })
    })

  })
  
  
  
  
  # perform regression analysis ----------------------------------------------
  
  # derive regression coefficients from data
  observeEvent(input[[paste("derrule", strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3], sep = "_")]], {

    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      allRuleParameters <- reactVals$allRuleParameters
      yOverview <- reactVals$yOverview

      thisRule <- strsplit(reactVals$activeRule, "_", fixed = T)[[1]][3]
      thisy_name_nice <- yOverview[which(yOverview[,1] == thisRule), 4]
      thisx_name_nice <- allRuleParameters[which(allRuleParameters[,1] == thisRule),6]
  
      temp <<- regression_analysis_SimUSys(thisy_name_nice, thisx_name_nice, thisRule)
      if (is.na(temp) == F) reactVals$sumTab <- temp
      
    })
  })
  
  # set sliders according to regression results
  observe({

    sumTab <- reactVals$sumTab
    if (sumTab != ""){
      sliderNames_nice <- unlist(lapply(1:nrow(allRuleParameters), function(i) paste(strsplit(allRuleParameters[i,9], "_", fixed = T)[[1]][2], strsplit(allRuleParameters[i,9], "_", fixed = T)[[1]][3], strsplit(allRuleParameters[i,9], "_", fixed = T)[[1]][4], sep = "_")))
      for (s in 2:nrow(sumTab)){
        pos <- which(sliderNames_nice == row.names(sumTab)[s])
        if (length(pos) > 0){
          sliderID <- unname(allRuleParameters[pos, 8])
          thisVal <- sumTab[s,1]
          if (sumTab[s,4] > 0.05) thisVal <- 0
          updateSliderInput(session = session, inputId = sliderID, value = as.numeric(thisVal), min = round(min(sumTab[,1], na.rm = T), digits = 2), max = round(max(sumTab[,1], na.rm = T), digits = 2))
          allRuleParameters[pos, 10] <- as.character(thisVal)
          allRuleParameters[pos, 13] <- as.character(sumTab[1,1])
          allRuleParameters <<- allRuleParameters
          reactVals$allRuleParameters <- allRuleParameters
        }
      }
    }

  })
  
  
  # plot png about spatially implicit relations
  output$pngPlot <- renderPlot(grid::grid.raster(png))
  
  
  
  
  # ------------------------------------------------------------------------
  # game control and rule application --------------------------------------
  # ------------------------------------------------------------------------
  
  # display game points
  output$gamePointsOutput <- flexdashboard::renderGauge({
    
    gamePoints <- reactVals$gamePoints
    gp_label <- labelNames[which(labelNames[, 1] == "gamepoints"), lan]
    
    flexdashboard::gauge(value = gamePoints, min = -500, max = 1000, label = gp_label,
          gaugeSectors(danger = c(-500, -1), warning = c(0, 900), success = c(901, 1500)))
    
    
  })
  
  # display action points
  output$gameActionPointsOutput <- flexdashboard::renderGauge({

    gameActionPoints <- reactVals$gameActionPoints
    ap_label <- labelNames[which(labelNames[, 1] == "gameactionpoints"), lan]

    flexdashboard::gauge(value = gameActionPoints, min = 0, max = 10, label = ap_label,
          gaugeSectors(danger = c(0, 2), warning = c(3, 5), success = c(6, 10)))


  })
  
  
  # display time step
  output$timestepOutput <- renderUI({
    timestep <- reactVals$timestep
    h4(timestep, align = "center")
  })
  
  
  # create Start/End and additional game buttons according to time step
  observe({
   
     timestep <- reactVals$timestep
    
    output$StartGameOutput <- renderUI({
      
      if (timestep == 0){
        
        div(actionButton(inputId = "startGameId", label = labelNames[which(labelNames[,1] == "startGame"),lan], width = 190), align = "center")
      
      } else {
        
        div_args <- list(align = "center")
        div_args[[length(div_args)+1]] <- h5(labelNames[which(labelNames[,1] == "createFacility"),lan])
        
        # filter for objects for which data is available
        avLyr <- c(unlist(env_avLyr), unlist(poi_avLyr), unlist(plE_avLyr), unlist(net_avLyr), unlist(res_avLyr))
        avLyr <<- avLyr
        avPos <- creatable_info[,2] %in% avLyr
        choicesFiltered <- as.list(sort(c(labelNames[which(labelNames[avPos,2] == "addText"),lan], creatable_info[avPos,4])))

        # create drop down list
        div_args[[length(div_args)+1]] <- selectInput(inputId = "createFacility_selInput", label = NULL, choices = choicesFiltered, selected = lastSelNewFac)
        
        if (class(reactVals$temp_fac) != "character"){
          div_args[[length(div_args)+1]] <- actionButton(inputId = "createFacility_action", label = labelNames[which(labelNames[,1] == "createFacility"),lan], width = 190)
          div_args[[length(div_args)+1]] <- actionButton(inputId = "createFacility_dismiss", label = labelNames[which(labelNames[,1] == "dismiss"),lan], width = 190)
        }
        
        div_args[[length(div_args)+1]] <- br("")
        div_args[[length(div_args)+1]] <- br("")
        div_args[[length(div_args)+1]] <- actionButton(inputId = "NextRoundId", label = labelNames[which(labelNames[,1] == "nextround"),lan], width = 190)
        div_args[[length(div_args)+1]] <- br("")
        div_args[[length(div_args)+1]] <- actionButton(inputId = "EndGameId", label = labelNames[which(labelNames[,1] == "endGame"),lan], width = 190)
        div_args[[length(div_args)+1]] <- 
        do.call(div, div_args)
      }
    })
  })
  
  
  # observe start game button
  observeEvent(input$startGameId,{
    
    # disable other tabs
    js$disableTab("dataTab")
    js$disableTab("rulesTab")
    
    withProgress(message = labelNames[which(labelNames[,1] == "loading"),lan], value = 0.0, {
    
      # increase timestep
      reactVals$timestep <- isolate(reactVals$timestep + 1)
      
      # set flag for creating facilities
      firstClick <<- T
      
      # define order for rules to be applied
      allRuleParameters <- isolate(reactVals$allRuleParameters)
      allRuleNumbers <- defineRuleOrder(allRuleParameters)
      
      # get affected layers and create backup
      all_y <- unique(allRuleParameters[, 4])
      afLyr <- unlist(lapply(1:length(all_y), function(i){
        this_lyr <- allAnalAtts[which(allAnalAtts[,2] == all_y[i]), 4]
        assign(paste0(this_lyr, "_backup"), get(this_lyr), envir = .GlobalEnv)
      }))
      
      # use normalized data during game
      analLyr <- unique(allAnalAtts[,4])
      lapply(1:length(analLyr), function(i){
        assign(analLyr[i], get(paste0(analLyr[i], "_normalized")), envir = .GlobalEnv)
      })
      
      # apply rules for pending state
      for (r in allRuleNumbers) applyRule(allRuleParameters, r, allAnalAtts, WGSproj)
      
      # re-initiate gauge value object
      allRuleParameters <- isolate(reactVals$allRuleParameters)
      allAnalAtts <- isolate(reactVals$allAnalAtts)
      gaugeVals <- initiateGaugeVals(allRuleParameters, allAnalAtts)
      gaugeVals <<- gaugeVals
      reactVals$gaugeVals <- gaugeVals
      
      
    })
    
  })
  
    

  # create map click observer and create temporary spatial point at clicked location
  MapClickOberserver <<- observe(suspended = T, {
    
    reactVals$clicked <- input$map_click
    clicked <<- reactVals$clicked
    
    if (length(clicked[[1]]) != 0){
      
      withProgress(message = labelNames[which(labelNames[,1] == "perfSim"),lan], value = 0.0, {
      
        if (firstClick == F){
          if (currentlyAdded != ""){
            assign(currentlyAdded, get(paste0(currentlyAdded, "_backup")), envir = .GlobalEnv)
            assign(paste0(currentlyAdded, "_col"), get(paste0(currentlyAdded, "col_backup")), envir = .GlobalEnv)
          }
        }
        
        # extract spatial information and create new spatial object
        firstClick <<- F
        lat <<- clicked$lat
        lng <<- clicked$lng

        clickedCoords <- cbind(coords.x1 = lng, coords.x2 = lat, coords.x3 = 0)
        temp_fac <<- SpatialPointsDataFrame(coords = clickedCoords, proj4string = WGSproj, data = as.data.frame(NA))
        
        
        # get information on object to be created and create backup
        this_show_select <- input$createFacility_selInput
        pos <- which(creatable_info[,4] == this_show_select)
        this_lyrName <- creatable_info[pos,2]
        assign(paste0(this_lyrName, "_backup"), get(this_lyrName), envir = .GlobalEnv)
        assign(paste0(this_lyrName, "col_backup"), get(paste0(this_lyrName, "_col")), envir = .GlobalEnv)
        currentlyAdded <<- this_lyrName
        
        #---------------
        # create no action scenario for game score
        
        
        # create accessibility backups
        Erreichbarkeit_zuFuss_backup <<- Erreichbarkeit_zuFuss
        Erreichbarkeit_mitFahrrad_backup <<- Erreichbarkeit_mitFahrrad
        Erreichbarkeit_mitPKW_backup <<- Erreichbarkeit_mitPKW
        LuftlinienDistanzen_backup <<- LuftlinienDistanzen
        
        # create pending distances information
        update_Distances(updateToFeatures_name = this_lyrName)
        
        # get affected layers and create backup
        all_y <- unique(allRuleParameters[, 4])
        afLyr <- unlist(lapply(1:length(all_y), function(i){
          this_lyr <- allAnalAtts[which(allAnalAtts[,2] == all_y[i]), 4]
          assign(paste0(this_lyr, "_backup"), get(this_lyr), envir = .GlobalEnv)
        }))
        
        # apply rules for pending state
        allRuleParameters <- isolate(reactVals$allRuleParameters)
        allRuleNumbers <- defineRuleOrder(allRuleParameters)
        for (r in allRuleNumbers) applyRule(allRuleParameters, r, allAnalAtts, WGSproj)
        
        
        #---
        
        # get no action values which affect the game score...
        gameScoreVals_noAct <- isolate(reactVals$gameScoreVals_noAct)
        
        #...local
        clicked_cell <- over(temp_fac, PlanungseinheitenAggregiert_total)
        clicked_cell_id <- clicked_cell[,"grid_ID"]
        gameScoreVals_noAct[1,1] <- Raumattraktivitaet@data[clicked_cell_id,"wohlUn"]
        gameScoreVals_noAct[1,2] <- PlanungseinheitenAggregiert_total@data[clicked_cell_id,"NEinw"]
        gameScoreVals_noAct[1,3] <- gameScoreVals_noAct[1,1] * gameScoreVals_noAct[1,2]
        
        #...vicinity
        clicked_cells <- as.data.frame(sp::over(spTransform(buffer(spTransform(temp_fac, UTMproj), 300), WGSproj),
                                                PlanungseinheitenAggregiert_total, returnList = T))
        clicked_cells_ids <- clicked_cells[,"grid_ID"]
        gameScoreVals_noAct[1,4] <- mean(Raumattraktivitaet@data[clicked_cells_ids,"wohlUn"], na.rm = T)
        gameScoreVals_noAct[1,5] <- mean(Raumattraktivitaet@data[clicked_cells_ids,"wohlUn"] *
                                           PlanungseinheitenAggregiert_total@data[clicked_cells_ids,"NEinw"], na.rm = T)
        local_pop <- sum(PlanungseinheitenAggregiert_total_start@data[clicked_cells_ids,"NEinw"], na.rm = T)
        gameScoreVals_noAct[,"vic_pop"] <- local_pop
        
        #...vicinity (other rules)
        if (length(allRuleNumbers) > 0){
          for (r in allRuleNumbers){
            temp_att_1 <- allRuleParameters[which(allRuleParameters[,1] == r)[1],4]
            temp_att_2 <- allAnalAtts[which(allAnalAtts[,2] == temp_att_1),]
            temp_att_3 <- get(temp_att_2[4])
            temp_att_4 <- temp_att_3@data[clicked_cells_ids,temp_att_2[1]]
            newVal <- mean(temp_att_4, na.rm = T)
            if (temp_att_2[2] %in% colnames(gameScoreVals_noAct)){
              gameScoreVals_noAct[,temp_att_2[2]] <- c(newVal, NA)
            } else {
              gameScoreVals_noAct <- cbind(gameScoreVals_noAct, c(newVal, NA))
              colnames(gameScoreVals_noAct)[ncol(gameScoreVals_noAct)] <- temp_att_2[2]
            }
          }
        }
        
        
        #...global
        gameScoreVals_noAct[1,6] <- mean(Raumattraktivitaet@data[,"wohlUn"], na.rm = T)
        gameScoreVals_noAct[1,7] <- mean(Raumattraktivitaet@data[,"wohlUn"] *
                                           PlanungseinheitenAggregiert_total@data[,"NEinw"], na.rm = T)
        
        gameScoreVals_noAct <<- gameScoreVals_noAct
        reactVals$gameScoreVals_noAct <- gameScoreVals_noAct
        
        
        #---
        
        
        # role back rule affected layers
        Erreichbarkeit_zuFuss <<- Erreichbarkeit_zuFuss_backup
        Erreichbarkeit_mitFahrrad <<- Erreichbarkeit_mitFahrrad_backup
        Erreichbarkeit_mitPKW <<- Erreichbarkeit_mitPKW_backup
        LuftlinienDistanzen <<- LuftlinienDistanzen_backup
        afLyr <- unlist(lapply(1:length(all_y), function(i){
          this_lyr <- allAnalAtts[which(allAnalAtts[,2] == all_y[i]), 4]
          assign(this_lyr, get(paste0(this_lyr, "_backup")), envir = .GlobalEnv)
        }))
        
        
        
        
        #---------------
        
        
        # append spatial object and colors
        temp_add <- temp_fac
        this_sp <- get(this_lyrName)
        temp_dat <- this_sp@data
        temp_dat <- temp_dat[-(1:nrow(temp_dat)),]
        temp_dat[1,] <- NA
        temp_add@data <- temp_dat
        this_sp <- rbind(this_sp, temp_add)
        this_col <- get(paste0(this_lyrName, "_col"))
        if (typeof(this_col) == "S4"){
          this_col <- rep("black", times = length(this_sp))
        } else {
          this_col <- c(this_col, rep(this_col[length(this_col)], times = nrow(temp_add)))
        }
        assign(this_lyrName, this_sp, envir = .GlobalEnv)
        assign(paste(this_lyrName, "col", sep = "_"), this_col, envir = .GlobalEnv)
        
        
        # create accessibility backups
        Erreichbarkeit_zuFuss_backup <<- Erreichbarkeit_zuFuss
        Erreichbarkeit_mitFahrrad_backup <<- Erreichbarkeit_mitFahrrad
        Erreichbarkeit_mitPKW_backup <<- Erreichbarkeit_mitPKW
        LuftlinienDistanzen_backup <<- LuftlinienDistanzen

        # create pending distances information
        update_Distances(updateToFeatures_name = this_lyrName)
        
        # define order for rules to be applied
        allRuleParameters <- isolate(reactVals$allRuleParameters)
        allRuleNumbers <- defineRuleOrder(allRuleParameters)
        
        # get affected layers and create backup
        all_y <- unique(allRuleParameters[, 4])
        afLyr <- unlist(lapply(1:length(all_y), function(i){
          this_lyr <- allAnalAtts[which(allAnalAtts[,2] == all_y[i]), 4]
          assign(paste0(this_lyr, "_backup"), get(this_lyr), envir = .GlobalEnv)
          }))
        
        # apply rules for pending state
        for (r in allRuleNumbers) applyRule(allRuleParameters, r, allAnalAtts, WGSproj)
        
        
        #---------------
        
        # get values regarding game points
        
        #---
        
        # get no action values which affect the game score...
        gameScoreVals_noAct <- isolate(reactVals$gameScoreVals_noAct)
        
        #...local
        clicked_cell <- over(temp_fac, PlanungseinheitenAggregiert_total)
        clicked_cell_id <- clicked_cell[,"grid_ID"]
        gameScoreVals_noAct[2,1] <- Raumattraktivitaet@data[clicked_cell_id,"wohlUn"]
        gameScoreVals_noAct[2,2] <- PlanungseinheitenAggregiert_total@data[clicked_cell_id,"NEinw"]
        gameScoreVals_noAct[2,3] <- gameScoreVals_noAct[2,1] * gameScoreVals_noAct[2,2]
        
        #...vicinity
        clicked_cells <- as.data.frame(sp::over(spTransform(buffer(spTransform(temp_fac, UTMproj), 300), WGSproj),
                                                PlanungseinheitenAggregiert_total, returnList = T))
        clicked_cells_ids <- clicked_cells[,"grid_ID"]
        gameScoreVals_noAct[2,4] <- mean(Raumattraktivitaet@data[clicked_cells_ids,"wohlUn"], na.rm = T)
        gameScoreVals_noAct[2,5] <- mean(Raumattraktivitaet@data[clicked_cells_ids,"wohlUn"] *
                                           PlanungseinheitenAggregiert_total@data[clicked_cells_ids,"NEinw"], na.rm = T)
        
        #...vicinity (other rules)
        if (length(allRuleNumbers) > 0){
          for (r in allRuleNumbers){
            temp_att_1 <- allRuleParameters[which(allRuleParameters[,1] == r)[1],4]
            temp_att_2 <- allAnalAtts[which(allAnalAtts[,2] == temp_att_1),]
            temp_att_3 <- get(temp_att_2[4])
            temp_att_4 <- temp_att_3@data[clicked_cells_ids,temp_att_2[1]]
            newVal <- mean(temp_att_4, na.rm = T)
            pos <- which(colnames(gameScoreVals_noAct) == temp_att_2[2])
            gameScoreVals_noAct[2, pos] <- newVal
          }
        }
        
        
        #...global
        gameScoreVals_noAct[2,6] <- mean(Raumattraktivitaet@data[,"wohlUn"], na.rm = T)
        gameScoreVals_noAct[2,7] <- mean(Raumattraktivitaet@data[,"wohlUn"] *
                                           PlanungseinheitenAggregiert_total@data[,"NEinw"], na.rm = T)
        
        # save for higher order functions
        gameScoreVals_noAct <<- gameScoreVals_noAct
        reactVals$gameScoreVals_noAct <- gameScoreVals_noAct
        reactVals$temp_fac <- temp_fac
        
        
        #---
        
        
        #---------------
        
      })
      
    }
  })
  
  # observe selection to create new facility
  observeEvent(input$createFacility_selInput, {
    
    # get value
    createFacility_selInput <<- input$createFacility_selInput
    lastSelNewFac <<- createFacility_selInput
    
    
    # execute if a value other than the default value is selected
    if (createFacility_selInput != labelNames[which(labelNames[,1] == "addText"),lan]){
      
      MapClickOberserver$resume()
      
    } else {
      
      MapClickOberserver$suspend()
      
    }
    
  })
  
  
  # observe dismiss button
  observeEvent(input$createFacility_dismiss, {
    
    # set everything back to the state is was in before the pending state was initiated
    if (currentlyAdded != ""){
      assign(currentlyAdded, get(paste0(currentlyAdded, "_backup")), envir = .GlobalEnv)
      assign(paste0(currentlyAdded, "_col"), get(paste0(currentlyAdded, "col_backup")), envir = .GlobalEnv)
      firstClick <<- T
    }
    
    reactVals$gaugeVals <- gaugeVals_backup
    
  })
    
  
  # observe create facility button
  observeEvent(input$createFacility_action, {

    firstClick <<- T
    
    # trigger gauge update
    gaugeVals <- reactVals$gaugeVals
    gaugeVals[1,2] <- NA
    reactVals$gaugeVals <- gaugeVals
    gaugeVals[1,2] <- 0
    reactVals$gaugeVals <- gaugeVals
    
    # get information on created object
    this_show_select <- input$createFacility_selInput
    pos <- which(creatable_info[,4] == this_show_select)
    this_lyrName <- creatable_info[pos,1]

    # get required action points
    this_actionPoints <- as.numeric(creatable_info[pos,3])
    
    # only create new feature if action points are sufficient
    newACP <- reactVals$gameActionPoints - this_actionPoints
    if (newACP < 0){
      
      # showNotification("Test", type = "error")
      showModal(modalDialog(title = labelNames[which(labelNames[,1] == "noSufAP_title"),lan],
                            labelNames[which(labelNames[,1] == "noSufAP"),lan],
                            footer = modalButton(labelNames[which(labelNames[,1] == "close"),lan]), easyClose = T))
      
      # clear temporary feature
      temp_fac <<- ""
      reactVals$temp_fac <- temp_fac
      
      
    } else {
    
      # reduce action points
      gameActionPoints <<- newACP
      reactVals$gameActionPoints <- gameActionPoints
      
      # clear temporary feature
      temp_fac <<- ""
      reactVals$temp_fac <- temp_fac
      
    }

  })

  
  # observe next round button
  observeEvent(input$NextRoundId,{
    
    firstClick <<- T
    
    # increase timestep
    reactVals$timestep <- reactVals$timestep + 1
    
    # define order for rules to be applied
    allRuleParameters <- isolate(reactVals$allRuleParameters)
    allRuleNumbers <- defineRuleOrder(allRuleParameters)
    
    # set before gauge values for new round
    gameScoreVals_noAct <- isolate(reactVals$gameScoreVals_noAct)
    before_Gauges <- isolate(reactVals$before_Gauges)
    all_y <- as.character(before_Gauges[, "name"])
    for (s in all_y){
      pos1 <- which(colnames(gameScoreVals_noAct) == s)
      pos2 <- which(before_Gauges[,1] == s)
      newGaugeVal <- NA
      newGaugeVal <- ((gameScoreVals_noAct[2,pos1] - gameScoreVals_noAct[1,pos1]) / abs(gameScoreVals_noAct[1,pos1])) * 100
      if (is.na(newGaugeVal)) before_Gauges[pos2,2] <- 0 else before_Gauges[pos2,2] <- newGaugeVal
    }
    before_Gauges <<- before_Gauges
    reactVals$before_Gauges <- before_Gauges
    
    
    
    # calculate game points
    temp <- calculateGamePoints(isolate(reactVals$gameScoreVals_noAct),
                                isolate(reactVals$gamePoints),
                                isolate(reactVals$gameActionPoints),
                                Score_scalingFactor)
    reactVals$gamePoints <- temp[[1]]
    reactVals$gameActionPoints <- temp[[2]]
    
  })
  
  
  # observe end game button
  observeEvent(input$EndGameId,{
    
    
    # activate panels
    js$enableTab("dataTab")
    js$enableTab("rulesTab")
    
    setAllContainersToDefault(method = "full")
    
    # restore (the) environment
    loadThis_file <- list.files(paste(reactVals$modDat, "/savedRObjects", sep = ""))
    loadThis <- unlist(lapply(1:length(loadThis_file), function(i){
      temp <- gsub(x = loadThis_file[i], pattern = "beforeGame_", replacement = "")
      temp <- gsub(x = temp, pattern = ".rds", replacement = "")
      return(temp)}))
    loadThis_filepath <- paste(reactVals$modDat, "/savedRObjects/", loadThis_file, sep = "")
    for (i in 1:length(loadThis)) assign(loadThis[i], readRDS(loadThis_filepath[i]), envir = .GlobalEnv)

    
    # call reactive timestep
    reactVals$timestep <- 0
    
    # reset points
    reactVals$gamePoints <- 0
    reactVals$gameActionPoints <- 3
    
    # reset gauges
    reactVals$gaugeVals <- gaugeVals_start
    reactVals$gameScoreVals_noAct <- gameScoreVals_noAct_start
    
    assign("spAtt_start", 0, envir = .GlobalEnv)
    assign("times_points_calculated", 0, envir = .GlobalEnv)
    
  })
  
  
  # observe game action points and inform in case of game over
  observe({
    if (reactVals$gameActionPoints < 0){
      showModal(modalDialog(title = labelNames[which(labelNames[,1] == "gameOver_title"),lan],
                            labelNames[which(labelNames[,1] == "gameOver"),lan],
                            footer = modalButton(labelNames[which(labelNames[,1] == "close"),lan]), easyClose = T))
    }
  })
  
  
  # ------------------------------------------------------------------------
  # gauges -----------------------------------------------------------------
  # ------------------------------------------------------------------------
  
  
  # initiate gauge value object
  observe({
    
    allRuleParameters <- reactVals$allRuleParameters
    allRuleNumbers <- defineRuleOrder(allRuleParameters)
    allAnalAtts <- reactVals$allAnalAtts
    if (allAnalAtts != ""){
      
      # keep gauges up to date
      gaugeVals <- initiateGaugeVals(allRuleParameters, allAnalAtts)
      gaugeVals <<- gaugeVals
      reactVals$gaugeVals <- gaugeVals
      gaugeVals_start <<- gaugeVals
      reactVals$allRuleParameters <- allRuleParameters
      reactVals$allRuleParameters <<- allRuleParameters
      
      # keep score container up to date
      if (length(allRuleNumbers) > 0){
        for (r in allRuleNumbers){
          temp_att_1 <- allRuleParameters[which(allRuleParameters[,1] == r)[1],4]
          temp_att_2 <- allAnalAtts[which(allAnalAtts[,2] == temp_att_1),]
          if ((temp_att_2[2] %in% colnames(gameScoreVals_noAct)) == F){
            gameScoreVals_noAct <- cbind(gameScoreVals_noAct, c(NA, NA))
            colnames(gameScoreVals_noAct)[ncol(gameScoreVals_noAct)] <- temp_att_2[2]
          }
        }
        gameScoreVals_noAct <<- gameScoreVals_noAct
        reactVals$gameScoreVals_noAct <- gameScoreVals_noAct
        reactVals$gameScoreVals_noAct <<- gameScoreVals_noAct
      }
    }
    
  })
  
  # start output
  output$gauges <- renderUI({
    
    # create arguments list
    argsList <- list(id = "dashboardPanel", class = "panel panel-default", fixed = F, draggable = F,
                     top = "auto", left = 5, right = 5, bottom = 0, height = 140)
    
    
    # get names
    gaugeVals <- reactVals$gaugeVals
    all_y <- as.character(gaugeVals[, "name"])
    gameScoreVals_noAct <- isolate(reactVals$gameScoreVals_noAct)
    
    
    # iterate over each rule
    lapply(1:length(all_y), function(s){
      
      # get gauge value
      pos1 <- which(colnames(gameScoreVals_noAct) == all_y[s])
      if (length(pos1) > 0){
        val_delta <- ((gameScoreVals_noAct[2,pos1] - gameScoreVals_noAct[1,pos1]) / abs(gameScoreVals_noAct[1,pos1])) * 100
      } else {
        val_delta <- 0
      }
      pos2 <- which(before_Gauges[,1] == all_y[s])
      val_old <- before_Gauges[pos2,2]
      if (is.na(val_old)) val_old <- 0
      val <- val_old + val_delta
      if (is.na(val)) val <- 0
      
      
      
      # prepare label: Introduce line break if label is too long
      tempLab <- all_y[s]
      if (language == "English") tempLab <- translateLabels(tempLab, method = "to_engl")
      thisLab <- as.character(abbreviate(tempLab, minlength = 22, strict = T, method = "legt.kept", named = T))
      
      # create gauges and append arguments list
      this_gaugeName <- paste0("gauge_", as.character(s))
      output[[this_gaugeName]] <- createGauge(gauge_val = round(val, 1), gauge_min = -10,
                                              gauge_max = 10, gauge_label = thisLab)
      
      this_panelName <- paste0("gaugePanel_", as.character(s))
      argsList[[length(argsList) + 1]] <<- absolutePanel(id = this_panelName, class = "panel panel-default", fixed = F,
                                                        draggable = F, top = 5, width = 200, bottom = "auto",
                                                        left = ((5 * s) + (200 * (s-1))),
                                                        
                                                        gaugeOutput(this_gaugeName, height = "110px", width = "200px"))
                                                        
      # create rate panel and append arguments list
      this_rate <- round(val_delta, 2)
      this_pop <- gameScoreVals_noAct[1, "vic_pop"]
      if (is.na(this_rate)) this_rate <- 0
      if (is.na(this_pop)) this_pop <- 0
      if (this_rate >= 0){
        show_this_rate <- paste0(labelNames[which(labelNames[, 1] == "local"), lan],  " +", this_rate, "%, ",
                                 labelNames[which(labelNames[, 1] == "pop"), lan], " ", this_pop)
      } else {
        show_this_rate <- paste0(labelNames[which(labelNames[, 1] == "local"), lan], " ", this_rate, "% ",
                                 labelNames[which(labelNames[, 1] == "pop"), lan], " ", this_pop)
      }
      this_style <- "font-size:11px; text-align:center; color:#56AAB3"
      this_ratePanelName <- paste0("gaugeRatePanel_", as.character(s))
      argsList[[length(argsList) + 1]] <<- absolutePanel(id = this_ratePanelName, class = "panel rate-panel", fixed = F,
                                                         draggable = F, bottom = "auto", width = 200, top = 120, height = 15,
                                                         left = ((5 * s) + (200 * (s-1))),

                                                         p(show_this_rate, style = this_style))
      
                                                        
      
    })
    
    
    # call the function for creating a well panel with produced arguments
    argsList <<- argsList
    do.call(absolutePanel, argsList)
    
  })
  
}