# addFieldsToAttributeTableByFile.r
# Adds a new field to the attribute table which contains ones for features that are either in input field one or input field two true. Otherwise it will contain zero values.


# get input arguments
args <- commandArgs()
inShp <- args[5]
fromTab <- args[6]
toJoin <- args[7]
fromJoin <- args[8]
addFields <- args[9]
sumFields <- args[10]
wd <- args[11]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(wd, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("foreign", lib = paste(wd, "libraries", sep = "/"))
}


# prepare inputs
addFields <- strsplit(addFields, ";", fixed = T)[[1]]
sumFields <- strsplit(sumFields, ";", fixed = T)[[1]]

# read attribute table
attTab <- read.dbf(paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)

if (nrow(attTab) != 0){

  featJoins <- attTab[,toJoin]
  featJoins <- unique(featJoins)
  
  
  # read additional fields
  adddat <- read.table(fromTab, sep = ";", dec = ".", header = T, as.is = T)
  pos <- which(colnames(adddat) %in% addFields)
  
  # proceed if there are fields to add
  if (length(pos) > 0){
    
    # loop over all fields that should be added
    for (p in 1:length(pos)){
  
      # proceed if this field is to be added
      if (colnames(adddat)[pos[p]] %in% colnames(attTab) == F){
      
        # create new field in target table
        attTab$newField <- character(nrow(attTab))
        colnames(attTab)[ncol(attTab)] <- colnames(adddat)[pos[p]]
        
        # loop over each target feature
        for (f in 1:length(featJoins)){
          
          # get features to write to in this loop
          toPos <- which(attTab[,toJoin] == featJoins[f])
          
          # get positions of values from the source table that should be added
          hit <- which(adddat[,fromJoin] == featJoins[f])
          
          # proceed if there are data entries in the source table
          if (length(hit) > 0){
            
            # distinction between adding of raw values and distribution of values if there is more than one target feature
            if (colnames(adddat)[pos[p]] %in% sumFields){
              addVal <- adddat[hit,pos[p]][1]/length(toPos)
            } else {
              addVal <- adddat[hit,pos[p]][1]
            }
            
            # add values to target table
            attTab[toPos,ncol(attTab)] <- addVal
          }
              
        }
        
      }
    }
    
    # write .dbf to file
    write.dbf(attTab, file = paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."))

  }
    
}
  
# report to ArcGIS
print ("...completed execution of R script")
