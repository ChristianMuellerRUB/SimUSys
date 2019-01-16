# updateGaugePending.r

updateGaugePending <- function(gobj, allRuleParameters, clicked_cell){
  
  # get all regression coefficients (slider values)
  all_coef <- allRuleParameters[,"sldr_val"]
  
  # get population data
  pop <- get("PlanungseinheitenAggregiert_total_start")@data[,"NEinw"]
  pop[which(pop == -1)] <- 0
  
  # get values
  lapply(1:nrow(gobj), function(i){
    
    # set new 'before' value
    gobj[i,"before_actVal"] <<- gobj[i,"current_actVal"]
    gobj[i,"before"] <<- gobj[i,"current"]
    assign(gobj[i,"before_local"], get(gobj[i,"current_local"]), envir = .GlobalEnv)
    old_dat <<- get(gobj[i,"before_local"])
    
    
    # get number of locally effected population
    this_pos <- which(PlanungseinheitenAggregiert_total@data[,"grid_ID"] == clicked_cell[,"grid_ID"])
    gobj[i, "local_pop"] <<- pop[this_pos]
    
    
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
    
    # calculate local rate of change (positive or negative)
    local_rate <<- this_dat[this_pos] / old_dat[this_pos] * 100
    
    # save values
    gobj[i, "local_rate"] <<- local_rate
    assign(gobj[i,"before_local"], this_sp@data[,this_at_c], envir = .GlobalEnv)
    
    
    # use local rate (instead of overall rate)
    rate <- local_rate
    
    # reclassify value
    if (rate <= -100) addP <- -15
    if ((rate > -100) && (rate <= -90)) addP <- -10
    if ((rate > -90) && (rate <= -80)) addP <- -9
    if ((rate > -80) && (rate <= -70)) addP <- -8
    if ((rate > -70) && (rate <= -60)) addP <- -7
    if ((rate > -60) && (rate <= -50)) addP <- -6
    if ((rate > -50) && (rate <= -40)) addP <- -5
    if ((rate > -40) && (rate <= -30)) addP <- -4
    if ((rate > -30) && (rate <= -20)) addP <- -3
    if ((rate > -20) && (rate <= -10)) addP <- -2
    if ((rate > -10) && (rate <= 0)) addP <- -1
    if ((rate > 0) && (rate <= 10)) addP <- 1
    if ((rate > 10) && (rate <= 20)) addP <- 2
    if ((rate > 20) && (rate <= 30)) addP <- 3
    if ((rate > 30) && (rate <= 40)) addP <- 4
    if ((rate > 40) && (rate <= 50)) addP <- 5
    if ((rate > 50) && (rate <= 60)) addP <- 6
    if ((rate > 60) && (rate <= 70)) addP <- 7
    if ((rate > 70) && (rate <= 80)) addP <- 8
    if ((rate > 80) && (rate <= 90)) addP <- 9
    if ((rate > 90) && (rate <= 100)) addP <- 10
    if (rate >= 100) addP <- 15
    
    # add points to gauge
    gobj[i,"current"] <<- addP + gobj[i,"before"]
    
  })
  
  return(gobj)
  
}