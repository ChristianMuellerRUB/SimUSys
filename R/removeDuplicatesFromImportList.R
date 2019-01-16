# removeDuplicatesFromImportList.r
# Removes duplicates from data import list


# get input arguments
args <- commandArgs()
provDat <- args[5]
ModelDataFolderName <- args[6]
rScript <- args[7]

# read data import list
csvPath <- paste(provDat, "\\", ModelDataFolderName, "\\use_spatialImport.csv", sep = "")
dat <- read.csv2(csvPath, as.is = T)

# go through all lines
temp <- character(nrow(dat))
for (i in 1:nrow(dat)){
  temp[i] <- paste(dat[i,], collapse = "this§Weird?Sep!String")
}

# remove duplicates
temp <- unique(temp)

# go through all non-duplicate lines and split into columns
out <- dat[1:length(temp),]
for (i in 1:length(temp)){
  out[i,] <- t(strsplit(temp[i], "this§Weird?Sep!String", fixed = T)[[1]])
}

# write to file
write.table(out, file = csvPath, sep = ";", dec = ".", row.name = F)

# report to ArcGIS
print ("...finished execution of R-Script.")
