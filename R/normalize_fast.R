# normalize_fast.r

# Script to column-wise normalize (standardize) values of a matrix

normalize_fast <- function(x){
  
  cat(paste("Normalization started at", Sys.time()))
  require(scales)
  
  if (class(x) == "matrix"){
  
    # this first step is to find out which columns are numerical and therefore normalizable:
    colnum <- numeric()                                                                                       # create a variable, to which numeric columns will be reported
    for (i in 1:ncol(x)){                                                                                     # check for each column...
      if (is.double(x[,i])) colnum <- c(colnum, i)                                                            # ...if it is numeric, and if so, make an entry for this column to the report variable
    }
    
    out <- x								                                                                                  # copy of the dataset to write the normalized data to
    
    # save minimum and maximum values
    minmax <- x[1:2,]
    rownames(minmax) <- c("min", "max")
    
    if (length(colnum) != 0){                                                                                 # if there is at least one numeric column in the data set, begin
      for (j in 1:length(colnum)){                                                                            # for each numeric column...
        i <- colnum[j]
        out[,i] <- rescale(x[,i], to = c(0,1))
        minmax[1,i] <- min(x[,i], na.rm = T)
        minmax[2,i] <- max(x[,i], na.rm = T)
      }
    }	
    
    output <- list(out, colnum, minmax)                                                                                # return the normalized data set and the variable which tells which columns are numeric
    
  } else if (class(x) == "numeric"){
    
    out <- rescale(x, to = c(0,1))
    
    output <- out
    
  } else {
    warning("invalid input type (provide matrix or vector)")
  }
  print(" ")
  cat(paste("Normalization ended at", Sys.time()))
  
  return(output)
  
}