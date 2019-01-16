# ui.r
# This script defines the graphical user interface SimUSys


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
for (i in 1:2) {
  if (!require("leaflet"))
    install.packages("leaflet")
  if (!require("DT"))
    install.packages("DT")
  if (!require("dplyr"))
    install.packages("dplyr")
  if (!require("rgdal"))
    install.packages("rgdal")
  if (!require("sp"))
    install.packages("sp")
  if (!require("leaflet"))
    install.packages("leaflet")
  if (!require("rgeos"))
    install.packages("rgeos")
  if (!require("raster"))
    install.packages("raster")
  if (!require("shinyFiles"))
    install.packages("shinyFiles")
  if (!require("shinyTree"))
    install.packages("shinyTree")
  if (!require("XLConnectJars"))
    install.packages("XLConnectJars")
  if (!require("XLConnect"))
    install.packages("XLConnect")
}

# prepare JavaScript for disabeling panel control
disTabJS <- "
shinyjs.disableTab = function(name) {
var tab = $('.nav li a[data-value=' + name + ']');
tab.bind('click.tab', function(e) {
e.preventDefault();
return false;
});
tab.addClass('disabled');
}

shinyjs.enableTab = function(name) {
var tab = $('.nav li a[data-value=' + name + ']');
tab.unbind('click.tab');
tab.removeClass('disabled');
}
"

disTabCSS <- "
.nav li a.disabled {
background-color: rgb(248, 248, 248);
color: rgb(192, 192, 192);
cursor: not-allowed;
}"


shinyUI(fluidPage(
  useShinyjs(),
  extendShinyjs(text = disTabJS),
  inlineCSS(disTabCSS),
  navbarPage(
    "SimUSys",
    id = "nav",
    
    # data selection tab ----------------------------------------------
    
    tabPanel(
      paste(" ", labelNames[which(labelNames[, 1] == "loadDataHeader"), lan], sep = ""),
      value = "dataTab",
      
      div(
        class = "outer",
        align = "center",
        
        # Panel one
        wellPanel(
          id = "controls",
          class = "panel panel-default",
          fixed = TRUE,
          draggable = TRUE,
          top = 80,
          left = 50,
          right = 20,
          bottom = "auto",
          width = 330,
          height = "auto",
          
          # section header
          h3(labelNames[which(labelNames[, 1] == "selModFolder"), lan]),
          
          
          # folder choose button
          shinyDirButton(
            id = "modDatChoose",
            label = labelNames[which(labelNames[, 1] == "provDat"), lan],
            title = labelNames[which(labelNames[, 1] == "provDat"), lan]
          ),
          
          # explanation
          br(),
          h5(labelNames[which(labelNames[, 1] == "selModFolderExpl"), lan])
          
        )
        
      ),
      
      # send selected folder to GUI
      div(align = "center",
          br(),
          h4(labelNames[which(labelNames[, 1] == "selectedModFolder"), lan]),
          tags$style(type='text/css', '#selTxt {background-color: rgba(86,170,179,1); color: white; font-weight: bold;}'), 
          verbatimTextOutput("selTxt"))
      
      
    ),
    
    
    
    
    # map tab ----------------------------------------------
    
    tabPanel(
      paste(" ", labelNames[which(labelNames[, 1] == "map"), lan], sep = ""),
      value = "mapTab",
      
      div(
        class = "outer",
        
        # left panel
        absolutePanel(
          id = "controls",
          class = "panel panel-default",
          fixed = TRUE,
          draggable = F,
          top = 60,
          left = 5,
          right = 20,
          bottom = "auto",
          width = 310,
          height = 40,
          
          h4(labelNames[which(labelNames[, 1] == "lyrSel"), lan]),
          align = "center"
        ),
        
        
        absolutePanel(
          id = "controls",
          class = "panel panel-default",
          fixed = TRUE,
          draggable = F,
          top = 105,
          left = 5,
          right = 20,
          bottom = 145,
          width = 310,
          height = "auto",
          style = "overflow-y: auto; max-height: 90%",
          
          
          # Layer selection tree
          h4(labelNames[which(labelNames[, 1] == "analysisResFolder"), lan], align = "center"),
          shinyTree("Restree", checkbox = TRUE),
          
          conditionalPanel(
            condition = "output.showResattSel",
            selectInput(
              inputId = "ResattSel",
              label = NULL,
              choices = sort(Res_att),
              size = 0,
              selectize = F
            )
          ),
          tags$hr(),
          
          # Layer selection tree
          h4(labelNames[which(labelNames[, 1] == "poisFolder"), lan], align = "center"),
          shinyTree("POItree", checkbox = TRUE),
          conditionalPanel(
            condition = "output.showPOIattSel",
            selectInput(
              inputId = "POIattSel",
              label = NULL,
              choices = sort(POI_att),
              size = 0,
              selectize = F
            )
          ),
          tags$hr(),
          
          # Layer selection tree
          h4(labelNames[which(labelNames[, 1] == "planingEntitiesFolder"), lan], align = "center"),
          shinyTree("PlEtree", checkbox = TRUE),
          conditionalPanel(
            condition = "output.showPlEattSel",
            selectInput(
              inputId = "PlEattSel",
              label = NULL,
              choices = sort(PlE_att),
              size = 0,
              selectize = F
            )
          ),
          tags$hr(),
          
          
          # Layer selection tree
          h4(labelNames[which(labelNames[, 1] == "networkFolder"), lan], align = "center"),
          shinyTree("Nettree", checkbox = TRUE),
          conditionalPanel(
            condition = "output.showNetattSel",
            selectInput(
              inputId = "NetattSel",
              label = NULL,
              choices = sort(Net_att),
              size = 0,
              selectize = F
            )
          ),
          tags$hr(),
          
          # Layer selection tree
          h4(labelNames[which(labelNames[, 1] == "environFolder"), lan], align = "center"),
          shinyTree("Envtree", checkbox = TRUE),
          conditionalPanel(
            condition = "output.showEnvattSel",
            selectInput(
              inputId = "EnvattSel",
              label = NULL,
              choices = sort(Env_att),
              size = 0,
              selectize = F
            )
          )
          
        ),
        
        # map panel
        absolutePanel(
          id = "mapPanel",
          class = "panel panel-default",
          fixed = TRUE,
          draggable = F,
          top = 60,
          left = 320,
          right = 200,
          bottom = 145,
          width = "auto",
          height = "auto",
          # 745
          
          # map
          leafletOutput("map", width = "100%", height = "100%")
          
        ),
        
        # right control panel - top
        absolutePanel(
          id = "righttopPanel",
          class = "panel panel-default",
          fixed = TRUE,
          draggable = F,
          top = 60,
          left = "auto",
          right = 5,
          bottom = "auto",
          width = 190,
          height = "auto",
          
          h4(labelNames[which(labelNames[, 1] == "scores"), lan], align = "center"),
          flexdashboard::gaugeOutput("gamePointsOutput", height = "120px", width = "200px"),
          flexdashboard::gaugeOutput("gameActionPointsOutput", height = "120px", width = "200px"),
          
          h5(labelNames[which(labelNames[, 1] == "timestep"), lan], align = "center"),
          uiOutput("timestepOutput")
          
        ),
        
        # right control panel - bottom
        absolutePanel(
          id = "rightbottomPanel",
          class = "panel panel-default",
          fixed = T,
          draggable = F,
          top = "auto",
          left = "auto",
          right = 5,
          bottom = 145,
          width = 190,
          height = "auto",
          
          uiOutput("StartGameOutput")
          
        ),
        
        uiOutput("gauges")
        
        # )
        
      , style = "overflow-x: auto; overflow-y: auto")
    ),
    
    
    
    # rules tab ----------------------------------------------
    
    tabPanel(
      paste(" ", labelNames[which(labelNames[, 1] == "rules"), lan], sep = ""),
      value = "rulesTab",
      
      navbarPage(
        labelNames[which(labelNames[, 1] == "rules"), lan],
        id = "rulesnav",
        
        tabPanel(
          paste(" ", labelNames[which(labelNames[, 1] == "depen"), lan], sep = ""),
          
          uiOutput("ruleHeader"),
          uiOutput("rulesPage")
          
        ),
        
        tabPanel(paste(" ", labelNames[which(labelNames[, 1] == "spatialImplicit"), lan], sep = ""),
                 
                 plotOutput("pngPlot"))
        
        
      )
      
    )
    
  )
  
))
