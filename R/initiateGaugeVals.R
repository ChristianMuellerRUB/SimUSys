# initiateGaugeVals.r
# initiates objects which contains information on what the gauges should display

initiateGaugeVals <- function(allRuleParameters, allAnalAtts){
  
  
  # get all rules
  all_y <- unique(allRuleParameters[, 4])
  
  # create data frame
  gobj <- data.frame(name = as.character(all_y), current = NA, before = NA,
                     current_actVal = NA, before_actVal = NA, start_actVal = NA,
                     current_local = NA, before_local = NA, local_rate = 0, local_pop = 0)
  
  # get values
  lapply(1:nrow(gobj), function(i){
    
    # get nice attribute name
    this_at <- as.character(gobj[i,"name"])
    
    # get computational attribute name
    this_at_c <- allAnalAtts[which(allAnalAtts[,2] == this_at), 1]
    
    # get layer name
    this_ly <- allAnalAtts[which(allAnalAtts[,2] == this_at), 4]
    
    # get spatial object
    this_sp <- get(this_ly)
    
    # get nummerical data
    this_dat <- this_sp@data[,this_at_c]
    
    # # rescale values
    # this_dat_rsc <- rescale(this_dat, from = c(min(this_dat, na.rm = T), max(this_dat, na.rm = T)), to = c(0, 1))
    
    # calculate actual value
    gobj[i,"current_actVal"] <<- mean(this_dat, na.rm = T)
    gobj[i,"before_actVal"] <<- gobj[i,"current_actVal"]
    gobj[i,"start_actVal"] <<- gobj[i,"current_actVal"]
    
    
    # reclassify value
    gobj[i,"current"] <<- 0
    gobj[i,"before"] <<- 0
    
    
    
  })
  
  return(gobj)
  
}