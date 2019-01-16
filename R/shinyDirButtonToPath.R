# shinyDirButtonToPath.r

shinyDirButtonToPath <- function(modDat){
  
  outDat <- ""
  if (length(modDat) > 1){
    temp1 <- glue::collapse(x = modDat[1:(length(modDat)-1)], sep = "/")
    if (substr(temp1, 1, 1) == "/") temp1 <- substr(temp1, 2, nchar(temp1))
    temp2 <- glue::collapse(x = modDat[length(modDat)])
    outDat <- paste0(temp2, temp1)
  }
  
  return(outDat)
  
}