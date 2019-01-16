# translateLabels.r

# this function translates labels for SimUSys
# it depends on a dictionary which is defined as a global varialbe in global.r

# inStr <- "Erreichbarkeit (zu Fuß)"

translateLabels <- function(inStr, method = "to_engl"){
  
  if (method == "to_engl") if (inStr %in% transList[,2]) outStr <- transList[which(transList[,2] == inStr)[1], 1]
  if (method == "to_germ") if (inStr %in% transList[,1]) outStr <- transList[which(transList[,1] == inStr)[1], 2]
  
  return(outStr)
  
}