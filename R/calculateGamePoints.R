# calculateGamePoints.r

calculateGamePoints <- function(gameScoreVals_noAct, gamePoints, gameActionPoints, Score_scalingFactor){
  
    # calculate game points in game rounds relative to start game points
    addP <- 0
    rate <- ((gameScoreVals_noAct[2,7] - gameScoreVals_noAct[1,7]) / abs(gameScoreVals_noAct[1,7])) * 100
    rate <- rate * Score_scalingFactor
  
    if (is.na(rate)){
      
      addP <- 0
      
    } else {
      
      if (rate <= -1.0) addP <- -1100
      if ((rate > -1.0) && (rate <= -0.9)) addP <- -1000
      if ((rate > -0.9) && (rate <= -0.8)) addP <- -900
      if ((rate > -0.8) && (rate <= -0.7)) addP <- -800
      if ((rate > -0.7) && (rate <= -0.6)) addP <- -700
      if ((rate > -0.6) && (rate <= -0.5)) addP <- -600
      if ((rate > -0.5) && (rate <= -0.4)) addP <- -500
      if ((rate > -0.4) && (rate <= -0.3)) addP <- -400
      if ((rate > -0.3) && (rate <= -0.2)) addP <- -300
      if ((rate > -0.2) && (rate <= -0.1)) addP <- -200
      if ((rate > -0.1) && (rate <= 0.0)) addP <- -100
      if ((rate > 0.0) && (rate <= 0.1)) addP <- 0
      if ((rate > 0.1) && (rate <= 0.2)) addP <- 100
      if ((rate > 0.2) && (rate <= 0.3)) addP <- 200
      if ((rate > 0.3) && (rate <= 0.4)) addP <- 300
      if ((rate > 0.4) && (rate <= 0.5)) addP <- 400
      if ((rate > 0.5) && (rate <= 0.6)) addP <- 500
      if ((rate > 0.6) && (rate <= 0.7)) addP <- 600
      if ((rate > 0.7) && (rate <= 0.8)) addP <- 700
      if ((rate > 0.8) && (rate <= 0.9)) addP <- 800
      if ((rate > 0.9) && (rate <= 1.0)) addP <- 900
      if (rate >= 1.0) addP <- 1000
      
    }
    
    # if ((spAtt_temp - spAtt_start) < 0) addP <- addP * (-1)
    gamePoints <- gamePoints + addP
    
    # calculate action points in dependence of game points
    addAP <- round(gamePoints/100, digits = 0)
    gameActionPoints <- gameActionPoints + addAP
    
    # reactVals$gameActionPoints <<- gameActionPoints
    return(list(gamePoints = gamePoints, gameActionPoints = gameActionPoints))
  
}