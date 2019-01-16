# global.r
# This scripts assigns variables in the global environment 

options(java.parameters = "-Xmx1024m")

# package installation
print("Loading R-Packages...")
try(for (i in 1:2) {
  if (!require("dplyr"))
    install.packages("dplyr", dependencies = T)
  if (!require("maptools"))
    install.packages("maptools", dependencies = T)
  if (!require("sp"))
    install.packages("sp", dependencies = T)
  if (!require("XLConnectJars"))
    install.packages("XLConnectJars", dependencies = T)
  if (!require("XLConnect"))
    install.packages("XLConnect", dependencies = T)
  if (!require("rgdal"))
    install.packages("rgdal", dependencies = T)
  if (!require("spdep"))
    install.packages("spdep", dependencies = T)
  if (!require("leaflet"))
    install.packages("leaflet", dependencies = T)
  if (!require("RColorBrewer"))
    install.packages("RColorBrewer", dependencies = T)
  if (!require("scales"))
    install.packages("scales", dependencies = T)
  if (!require("lattice"))
    install.packages("lattice", dependencies = T)
  if (!require("raster"))
    install.packages("raster", dependencies = T)
  if (!require("gdistance"))
    install.packages("gdistance", dependencies = T)
  if (!require("png"))
    install.packages("png", dependencies = T)
  if (!require("fmsb"))
    install.packages("fmsb", dependencies = T)
  if (!require("gplots"))
    install.packages("gplots", dependencies = T)
  if (!require("shinyjs"))
    install.packages("shinyjs", dependencies = T)
  if (!require("flexdashboard"))
    install.packages("flexdashboard", dependencies = T)
  if (!require("shinydashboard"))
    install.packages("shinydashboard", dependencies = T)
  if (!require("yaml"))
    install.packages("yaml", dependencies = T)
}
, silent = T)



# source functions
source("makeListOfNoneEmptyLayers.r")
source("createPopUpText.r")
source("addLegendToLeafletMap_POI.r")
source("addLegendToLeafletMap.r")
source("getSpatialObjectsFromSelectTree.r")
source("addDataToLeafletMap.r")
source("getInformativeAttributes.r")
source("getAllAvailableAnalysisAttributes.r")
source("createRulePanel.r")
source("createXVarSlider.r")
source("normalize_fast.r")
source("regression_analysis_SimUSys.r")
source("getSliderValues.r")
source("setParametersAccordingToPredefinedFile.r")
source("applyRule.r")
source("setReactiveValuesToDefault.r")
source("getAllSpatialObjects.r")
source("setAllContainersToDefault.r")
source("calculateGamePoints.r")
source("unselectAllLayers.r")
source("xlsxTocsv.r")
source("getOneSpatialObject.r")
source("getVertexCoordinates.r")
source("update_Distances.r")
source("defineRuleOrder.r")
source("loadAllObjects.r")
source("vif_func.r")
source("plotRegressionCoefficients.r")
source("shinyDirButtonToPath.r")
source("createGauge.r")
source("initiateGaugeVals.r")
source("updateGaugePending.r")
source("translateLabels.r")


# set default starting values for model data
modDat <- ""
thisModelCity <- "Herdecke"

# update .csv-libraries?
updateCSVLibs <- F

# load all objects
preload <- T

# recalculate distances
recalculateDistances <- F

# define layer load method
layer_load_method <- "non_reload"

# define projection
WGSproj <- CRS("+init=epsg:4326")
UTMproj <- CRS("+init=epsg:25832")

# define language
language <- "English"
lan <<- 2

# define layer names and paths
lyrNames <- read.table("LayerNamen.csv", header = T, sep = ";", dec = ".", as.is = T)
labelNames <- read.table("labelNames.csv", header = T, sep = ";", dec = ".", as.is = T, quote = "")
if (language == "English") labelNames <- labelNames[,c(1,3,2)]

# execute conversion
accNames <- read.table("ErreichNamen.csv", header = F, sep = ";", dec = ".", as.is = T, quote = "")
temp <- unlist(strsplit(as.character(accNames), "X", fixed = T))
accNames <- temp[which(temp != "")]


# create list for checkbox tree
checkTreeList <- as.list(unique(lyrNames[, lan]))
names(checkTreeList) <- unique(lyrNames[, lan])
for (i in 1:length(checkTreeList)) {
  tempList <-
    as.list(unique(lyrNames[which(lyrNames[, lan] == checkTreeList[i]), lan + 3]))
  names(tempList) <-
    unique(lyrNames[which(lyrNames[, lan] == checkTreeList[[i]]), lan + 3])
  if (length(which(lyrNames[, lan + 3] == tempList[1])) > 1) {
    for (j in 1:length(tempList)) {
      tempList2 <-
        as.list(unique(lyrNames[which(lyrNames[, lan + 3] == tempList[j]), lan + 6]))
      names(tempList2) <-
        unique(lyrNames[which(lyrNames[, lan + 3] == tempList[j]), lan + 6])
      tempList[[j]] <- tempList2
    }
  }
  checkTreeList[[i]] <- tempList
}

# set default value before they are reactive
input <- list(tree = "")
gaugeVals <- data.frame(name = "Raumattraktivitaet", pending = NA, current = 0, before = 0,
                        pending_actVal = NA, current_actVal = 0, before_actVal = 0,
                        start_actVal = 0)

# read data structure table
datStructTab <- read.table("DataStructure.csv", header = T, sep = ";", dec = ".", as.is = T, quote = "")


# execute conversion
attNames <- read.table( "AttributNamen.csv", header = T, sep = ";", dec = ".", as.is = T, quote = "")
shortNames <- unlist(lapply(1:nrow(attNames), function(i) {
  temp_att_nice <- attNames[i, 2]
  temp_att_nice <- strsplit(temp_att_nice, " ", fixed = T)[[1]]
  return(temp_att_nice[length(temp_att_nice)])
}))
attNames <- cbind(attNames, shortNames)


# create new container for valid attribute list
attTemp <- attNames[which(attNames[, 1] == "oGeom"), 1]
Res_att <- attNames[which(attNames[, 1] == "oGeom"), 1]
POI_att <- attNames[which(attNames[, 1] == "oGeom"), 1]
PlE_att <- attNames[which(attNames[, 1] == "oGeom"), 1]
Net_att <- attNames[which(attNames[, 1] == "oGeom"), 1]
Env_att <- attNames[which(attNames[, 1] == "oGeom"), 1]
Res_att_nice <- attNames[which(attNames[, 1] == "oGeom"), 2]
POI_att_nice <- attNames[which(attNames[, 1] == "oGeom"), 2]
PlE_att_nice <- attNames[which(attNames[, 1] == "oGeom"), 2]
Net_att_nice <- attNames[which(attNames[, 1] == "oGeom"), 2]
Env_att_nice <- attNames[which(attNames[, 1] == "oGeom"), 2]
setAllContainersToDefault(method = "full")

# prepare rule overview
yOverview <-matrix(NA, nrow = 0, ncol = 9,
         dimnames = list(c(), c("rule_num", "rule_id", "yvar_id", "yvar_name", "xvar_ids",
                                "xvar_names", "y_allx", "preDatAvailable", "yIntersect")))


# prepare variables
nRules <- 1
allRules_ids <- ""
lastRule <- ""
lastXVar <- ""
lastYvar_sel <- ""
lastXvar_sel <- ""
plsChoose <- labelNames[which(labelNames[, 1] == "plsChoose"), lan]
addText <- labelNames[which(labelNames[, 1] == "addText"), lan]
lastSelNewFac <- labelNames[which(labelNames[, 1] == "addText"), lan]
thisYPreset <- plsChoose
preDatAvailable <- ""


# get pre-defined rules from file
preDefAv <- matrix(NA, nrow = 0, ncol = 3,
         dimnames = list(c(), c("yVar", "places", "rObjName")))
lookplaces <- thisModelCity
for (i in 1:20) {
  for (j in 1:4) {
    thisName <- paste("sumTab_rule_", as.character(i), "_", lookplaces[j], sep = "")
    thisNameExt <- paste(thisName, ".csv", sep = "")
    if (file.exists(thisNameExt)) {
      temp <- read.table(thisNameExt, dec = ".", sep = ";", header = T, as.is = T, row.names = NULL, quote = "")
      assign(thisName, temp)
      preDefAv <- rbind(preDefAv, NA)
      preDefAv[nrow(preDefAv), 1] <- strsplit(get(thisName)[1, 1], "_", fixed = T)[[1]][1]
      preDefAv[nrow(preDefAv), 2] <- lookplaces[j]
      preDefAv[nrow(preDefAv), 3] <- thisName
    }
  }
}


# get initial rule overview
initRuleAtts <- attNames[which(attNames[,4] != 0),]

if (nrow(preDefAv) > 0) {
  allRuleParameters <- matrix(NA, nrow = 0, ncol = 13,
           dimnames = list(c(), c("rule_num", "rule_id", "yvar_id", "yvar_name", "xvar_id", "xvar_name", "allComb",
               "sliderID_short", "sliderID_full", "sldr_val", "minSliderVal", "maxSliderVal", "yIntersect")))
  for (i in 1:nrow(preDefAv)) {
    
    thisPreDefR <- read.table(paste0(preDefAv[i, 3], ".csv"), sep = ";", dec = ".", header = T, as.is = T, quote = "")
    
    for (j in 2:nrow(thisPreDefR)) {
      allRuleParameters <- rbind(allRuleParameters, NA)
      allRuleParameters[nrow(allRuleParameters), 1] <- as.character(i)
      allRuleParameters[nrow(allRuleParameters), 2] <- paste0("tabPanel_rule_", as.character(i))
      allRuleParameters[nrow(allRuleParameters), 3] <- paste0("rule_", as.character(i), "_y")
      allRuleParameters[nrow(allRuleParameters), 4] <- strsplit(thisPreDefR[1, 1], "_", fixed = T)[[1]][1]
      allRuleParameters[nrow(allRuleParameters), 5] <- paste0("rule_", i, "_xSel")
      allRuleParameters[nrow(allRuleParameters), 6] <- strsplit(thisPreDefR[j, 1], "_", fixed = T)[[1]][1]
      allRuleParameters[nrow(allRuleParameters), 10] <- thisPreDefR[j, 2]
      allRuleParameters[nrow(allRuleParameters), 13] <- thisPreDefR[1, 2]
    }
  }
  
} else {
  
  allRuleParameters <- matrix(NA, nrow = nrow(initRuleAtts), ncol = 13,
      dimnames = list( c(), c("rule_num", "rule_id", "yvar_id", "yvar_name", "xvar_id", "xvar_name", "allComb",
          "sliderID_short", "sliderID_full", "sldr_val", "minSliderVal", "maxSliderVal", "yIntersect")))
  
  allRuleParameters[, 6] <- initRuleAtts[,2]
  allRuleParameters[, 1] <- "1"
  allRuleParameters[, 2] <- "tabPanel_rule_1"
  allRuleParameters[, 3] <- "rule_1_y"
  allRuleParameters[, 4] <- lyrNames[which(lyrNames[, 4] == "Raumattraktivitaet"), 5]
  allRuleParameters[, 5] <- "rule_1_xSel"
  allRuleParameters[, 10] <- initRuleAtts[,4]
  allRuleParameters[, 13] <- "1"
  allRuleParameters[which(initRuleAtts[,4] < 0), 13] <- "0"
  
}

allRuleParameters[, 7] <-unlist(lapply(1:nrow(allRuleParameters), function(i) {
    paste(allRuleParameters[i, 1:6], collapse = "_")
}))

allRuleParameters[, 8] <- paste("xSlider", 1:nrow(allRuleParameters), sep = "_")
allRuleParameters[, 9] <- paste("xSlider", allRuleParameters[1:nrow(allRuleParameters), 6], "rule", allRuleParameters[1:nrow(allRuleParameters), 1], sep = "_")
allRuleParameters[, 11] <- "-1"
allRuleParameters[, 12] <- "1"


# get information on creatable facilities
pos <- which(lyrNames[, "creatableFacility"] == 1)
creatable_info <- matrix(NA, nrow = length(pos), ncol = 4,
                         dimnames = list(c(), c("lyrName", "lyrName_nice", "actionPoints" , "show_select")))
creatable_info[, "lyrName"] <- lyrNames[pos, "subList2"]
creatable_info[, "lyrName_nice"] <- lyrNames[pos, 6 + 2]
creatable_info[which(lyrNames[pos, "subList2"] == ""), "lyrName"] <-
  lyrNames[pos, "subList1"][which(lyrNames[pos, "subList2"] == "")]
creatable_info[which(lyrNames[pos, 6 + 2] == ""), "lyrName_nice"] <-
  lyrNames[pos, 3 + 2][which(lyrNames[pos, 6 + 2] == "")]
creatable_info[, "actionPoints"] <- lyrNames[pos, "actionPointCost"]
creatable_info[, "show_select"] <-
  unlist(lapply(1:nrow(creatable_info), function(i) {
    paste(creatable_info[i, "lyrName_nice"],
          " (",
          creatable_info[i, "actionPoints"],
          " ",
          labelNames[which(labelNames[, 1] == "gameactionpoints"), 2],
          ")",
          sep = "")
  }))
creatable_info[, "show_select"] <-
  unlist(lapply(1:nrow(creatable_info), function(i) {
    if (creatable_info[i, "actionPoints"] == "1")
      paste(substr(creatable_info[i, 4], 1, nchar(creatable_info[i, 4]) - 2), ")", sep = "")
    else
      creatable_info[i, 4]
  }))


# load png image to show in rules
png <- readPNG("RaeumlichImpliziteZusammenhaenge_b.png")
if (language == "English") png <- readPNG("RaeumlichImpliziteZusammenhaenge_eng_b.png")


if (language == "English"){
  transList <- lyrNames[,c(2,3)]
  colnames(transList) <- c("2", "3")
  transList_temp <- lyrNames[,c(5,6)]
  colnames(transList_temp) <- c("2", "3")
  transList <- rbind(transList, transList_temp)
  transList_temp <- lyrNames[,c(8,9)]
  colnames(transList_temp) <- c("2", "3")
  transList <- rbind(transList, transList_temp)
  transList_temp <- labelNames[,c(2,3)]
  colnames(transList_temp) <- c("2", "3")
  transList <- rbind(transList, transList_temp)
  transList_temp <- attNames[,c(3,2)]
  colnames(transList_temp) <- c("2", "3")
  transList <- rbind(transList, transList_temp)
  transList <- transList[-which(transList[,1] == ""),]
}

# create container for no action scenarios
gameScoreVals_noAct <- matrix(NA, nrow = 2, ncol = 8,
                              dimnames = list(c("no_act", "act"),
                                              c("local", "loc_pop", "loc_score", "vicinity", "vic_score", "global", "glob_score", "vic_pop")))

# set default values
spAtt_start <- 0
rate_min <- 0.00
rate_max <- 15.00
times_points_calculated <- 0
currentlyAdded <- ""
gamePoints <- 0
gameActionPoints <- 3
Score_scalingFactor <- 1
timestep <- 0


# set game score start values
gameScoreVals_noAct_start <- gameScoreVals_noAct


# prepare auxillary value container for gauges
all_y <- unique(allRuleParameters[,"yvar_name"])
before_Gauges <- as.data.frame(matrix(NA, nrow = length(all_y), ncol = 2,
                          dimnames = list(c(), c("name", "before"))))
before_Gauges[,1] <- all_y
