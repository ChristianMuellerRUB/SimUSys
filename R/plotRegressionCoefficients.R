# plotRegressionCoefficients.r

plotRegressionCoefficients <- function(sumTab, addout, VIF, thisRule){
  
  showLan <- "ge"
  
  # plot
  pdf(paste(modDat, "/AnalysenErgebnisse/rule_", thisRule, "_plot.pdf", sep = ""), paper = "a4r", onefile = T, width = 10, height = 6)
  
  
    for (c in 1:2){           # c = 1: german, c = 2: english
    
      if (c >= 2) showLan <- "en"
      
      # influence bar plot
      heights <- sumTab[-1,1]
      if (length(names(heights)) == 0) names(heights) <- rownames(sumTab)[-1]
      deviation <- sumTab[-1,2]
      y <- rownames(sumTab)[1]
      
      ord <- order(heights)
      heights <- heights[ord]
      deviation <- deviation[ord]
      VIF <- VIF[ord,]
      
      deviation[which(heights < 0)] <- deviation[which(heights < 0)] * -1
      
      # define colors
      cols <- rep("coral", times = length(heights))
      cols[which(heights < 0)] <- "cyan4"
      
      # define plot names
      xtext <- "Regressionskoeffizienten"
      if (showLan == "en") xtext <- "Regression coefficients"
      show_names <- unlist(lapply(names(heights), function(x) strsplit(x, "_", fixed = T)[[1]][length(strsplit(x, "_", fixed = T))]))
      y <- strsplit(y, "_", fixed = T)[[1]][1]
      if (showLan == "en"){
        show_names <- unlist(lapply(1:length(show_names), function(x) attNames[which(attNames[,2] == show_names[x]),3]))
        y <- attNames[which(attNames[,2] == y),3]
      }
      show_names <- unlist(lapply(1:length(show_names), function(x){
        if (nchar(show_names[x]) > 25){
          temp <- strsplit(show_names[x], " ", fixed = T)[[1]]
          string_mid <- round(median(1:nchar(show_names[x])))
          space_pos <- gregexpr(text = show_names[x], pattern = " ", fixed = T)[[1]]
          space_mid_dif <- abs(string_mid - space_pos)
          space_close_mid_pos <- which(space_mid_dif == min(space_mid_dif))
          temp[space_close_mid_pos - 1]
          paste(paste(temp[1:(space_close_mid_pos - 1)], collapse = " "), "\n", paste(temp[(space_close_mid_pos):length(temp)], collapse = " "), sep = "")
        } else {
          show_names[x]
        }
      }))
      
      VIF_show <- VIF[nrow(VIF):(nrow(VIF)-length(heights)),2]
      VIF_show <- paste("VIF = ", round(as.numeric(VIF_show), digits = 2), sep = "")
      
      x_add <- sumTab[-1,4]
      x_add <- unlist(lapply(1:length(x_add), function(x){
        if (x_add[x] > 0.1) out <- paste("p > 0.1\n", VIF_show[x], sep = "")
        if (x_add[x] < 0.1) out <- paste("p < 0.1\n", VIF_show[x], sep = "")
        if (x_add[x] < 0.05) out <- paste("p < 0.05\n", VIF_show[x], sep = "")
        if (x_add[x] < 0.01) out <- paste("p < 0.01\n", VIF_show[x], sep = "")
        if (x_add[x] < 0.001) out <- paste("p < 0.001\n", VIF_show[x], sep = "")
        return(out)
      }))
      
      # define axis limits
      xlim <- c(floor(min(heights - abs(deviation)) * 100),
                ceiling(max(heights + abs(deviation)) * 100))/100
      if (xlim[1] > 0) xlim[1] <- 0
      if (xlim[2] < 0) xlim[2] <- 0
      
      
      
      for (b in 1:2){     # b = 1: color, b = 2: greyscale
        
        if (b >= 2) cols[which(cols == "coral")] <- "grey25"
        if (b >= 2) cols[which(cols == "cyan4")] <- "grey35"
        
        for (a in 1:3){     # a = 1: influence of significant variables, a = 2: additional inforamtion on variables, a = 3: influence + information on regression
        
          par(mar = c(5.1, 18, 2, 12), xpd = T)
          
          # barplot
          mp <- barplot(heights, beside = T, horiz = T, col = cols, border = F, xlim = xlim,
                         xlab = xtext, names.arg = "", las = 1, xpd = T, main = y)
          
          # error bars
          segments(y0 = mp, x0 = heights, y1 = mp, x1 = heights + deviation)
          segments(y0 = mp, x0 = heights + deviation, y1 = mp - length(heights)/50, x1 = heights + deviation)
          segments(y0 = mp, x0 = heights + deviation, y1 = mp + length(heights)/50, x1 = heights + deviation)
          
          # labels
          mtext(text = show_names, side = 2, line = 2 + abs(min(heights - deviation)), at = mp, las = 2, cex = 1)
          
          if (a >= 2){
            mtext(text = x_add, side = 4, line = 2 + max(heights + deviation), at = mp, las = 2, cex = 0.8)
          }
          
          # add additional information on the model
          if (a >= 3){
            p.show  <- round(addout[8], digits = 3)
            if (p.show < 0.01) p.show <- "< 0.01" else p.show <- paste("= p.show")
            R2  <- round(addout[1], digits = 3)
            AIC <- round(addout[2], digits = 1)
            lambda <- round(addout[3], digits = 3)
            LLRatio <- round(addout[4], digits = 1)
            Logllh <- round(addout[6], digits = 1)
            n <- round(addout[7], digits = 0)
            addText <- paste("p ", p.show, ", R² = ", R2, paste(", AIC = ", AIC), paste(", lambda = ", lambda), paste(", LLRatio = ", LLRatio), paste(", Logllh = ", Logllh),", n = ", n, sep = "")
            mtext(text = addText, side = 1, line = 2, at = par("usr")[1] + 0.5 * diff(par("usr")[1:2]), cex = 0.8)
          }
        }
      }
  }
    

  
  dev.off()
   
}
