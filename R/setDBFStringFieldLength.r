# setDBFStringFieldLength.r
# Function which sets field length of string fields of data frames for .dbf-attribute tables to a specified length

setDBFStringFieldLength <- function(dat, setLength = 254) {

  # loop over each column
  for (i in 1:ncol(dat)){
    
    # find columns which are strings
    if (mode(dat[,i]) == "character") {
      
      # loop over each line
      for (l in 1:length(dat[,i])) {
        
        # if is not NA
        if (is.na(dat[l,i]) == F) {
        
          # append data entry by spaces
          filler <- paste(character(setLength - nchar(dat[l,i])), collapse = " ")
          dat[l,i] <- paste(dat[l,i], filler, sep = "")
          
        }
      }
    }
  }
  
  return(dat)
  
}
