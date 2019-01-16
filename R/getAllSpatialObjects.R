getAllSpatialObjects <- function(input, reactVals){
  
  getSpatialObjectsFromSelectTree(isolate(input$Restree), "Res", reactVals)
  getSpatialObjectsFromSelectTree(isolate(input$POItree), "POI", reactVals)
  getSpatialObjectsFromSelectTree(isolate(input$PlEtree), "PlE", reactVals)
  getSpatialObjectsFromSelectTree(isolate(input$Nettree), "Net", reactVals)
  getSpatialObjectsFromSelectTree(isolate(input$Envtree), "Env", reactVals)
  
}