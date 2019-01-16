# unselectAllLayers.r

unselectAllLayers <- function(session){
  
  updateSelectInput(session, inputId = Envtree, selected = NULL)
  updateSelectInput(session, inputId = Nettree, selected = NULL)
  updateSelectInput(session, inputId = PlEtree, selected = NULL)
  updateSelectInput(session, inputId = POItree, selected = NULL)
  updateSelectInput(session, inputId = Restree, selected = NULL)
  
}