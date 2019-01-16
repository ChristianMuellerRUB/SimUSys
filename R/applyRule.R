# applyRule.r

applyRule <- function(allRuleParameters, thisR, allAnalAtts, WGSproj){

  # get rule overview and extract information about the rule to be applied
  tab <- allRuleParameters[which(allRuleParameters[,1] == thisR),]
  
  # adjust data structure if necessary
  if (class(ncol(tab)) == "NULL") tab <- t(tab)
  
  # get dependent variable
  thisy <- tab[1,4]
  
  # get information on dependent variable
  y_info <- allAnalAtts[which(allAnalAtts[,2] == thisy),]
  
  # get dependent variable as spatial object
  y_sp <- get(y_info[4])
  
  # get dependent variable as data frame
  y_dat <- y_sp@data
  
  # get dependent variable as vector
  y <- y_dat[,y_info[1]]
  
  # build matrix for independent variable
  mat <- matrix(NA, nrow = length(y), ncol = nrow(tab), dimnames = list(c(), paste("x", 1:nrow(tab), sep = "")))
  
  # iterate over each independent variable
  for (i in 1:nrow(tab)){
    
    # get independent variable
    thisx <- tab[i,6]
    
    # get information on independent variable
    x_info <- allAnalAtts[which(allAnalAtts[,2] == thisx),]
    
    # get independent variable as spatial object
    x_sp <- get(x_info[4])
    
    # get independent variable as data frame
    x_dat <- x_sp@data
    
    # get independent variable as vector
    x <- x_dat[,x_info[1]]
    
    # standardize (normalize) independent variable
    x <- rescale(x, to = c(0,1))
    
    # save standardized (normalized) independent variable in matrix
    mat[,i] <- x * as.numeric(tab[i,10])
    
  }
  
  # calculate new y-values according to regression equation as sum of products of standardized (normalized) independent variables and respective regression coefficient plus intercept
  new_y <- rowSums(mat, na.rm = T) + as.numeric(tab[1,13])
  
  # save new y-values to data frame
  y_dat[,y_info[1]] <- new_y
  
  # save updated data frame as attribute table of spatial object
  y_sp@data <- y_dat
  
  # transform spatial object according to simulation projection
  y_sp <- spTransform(y_sp, WGSproj)
  
  # write updated spatial object to global environment
  assign(y_info[4], y_sp, envir = .GlobalEnv)
  
}