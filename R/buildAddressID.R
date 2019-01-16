# buildAddressID.r
# Builds an address ID from address fields

# input from python
args <- commandArgs()
inShp <- args[5]
streetFieldName <- args[6]
houseNumberFieldName <- args[7]
houseNumberAdditionFieldName <- args[8]
cityFieldName <- args[9]
ZIPCodeFieldName <- args[10]
workspacePath <- args[11]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(workspacePath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(workspacePath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(workspacePath, "libraries", sep = "/"))
  if (!require("XLConnect", lib.loc = paste(workspacePath, "libraries", sep = "/"))) install.packages("XLConnect", lib = paste(workspacePath, "libraries", sep = "/"))
}


# determine file extension
fileExtension <- strsplit(inShp, ".", fixed = T)[[1]][2]

# read data
if (fileExtension == "shp"){
  dat <- read.dbf(paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
}
if (fileExtension == "csv"){
  dat <- read.table(inShp, header = T, sep = ";", dec = ".")
  for (i in 1:ncol(dat)){
    if (T %in% is.na(dat[,i])){
      dat[which(is.na(dat[,i])),i] <- ""
    }
  }
}



# add ID
dat$ID <- 1:nrow(dat)

# rename streets


# rename fields
colnames(dat)[which(colnames(dat) == streetFieldName)] <- "Strasse"
colnames(dat)[which(colnames(dat) == houseNumberFieldName)] <- "Hausnummer"
colnames(dat)[which(colnames(dat) == houseNumberAdditionFieldName)] <- "Zusatz"
colnames(dat)[which(colnames(dat) == cityFieldName)] <- "Stadt"
colnames(dat)[which(colnames(dat) == ZIPCodeFieldName)] <- "PLZ"


# build address ID
addressID <- character(nrow(dat))
for (r in 1:nrow(dat)){
  
  # earase house number additional info if it is empty
  additionalInfo <- dat[r,which(colnames(dat) == "Zusatz")]
  if (is.na(additionalInfo) || length(additionalInfo) == 0) additionalInfo <- ""
  
  # build address ID
  addressID[r] <- paste(dat[r,which(colnames(dat) == "Strasse")], dat[r,which(colnames(dat) == "Hausnummer")],
                        "_", dat[r,which(colnames(dat) == "Stadt")], dat[r,which(colnames(dat) == "PLZ")], sep = "")
}

dat$addressID <- addressID


# write  to file
if (fileExtension == "shp"){
  write.dbf(dat, file = paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."))
}
if (fileExtension == "csv"){
  write.table(dat, file = inShp, sep = ";", dec = ".", col.names = T, row.names = F)
}



print("...completed execution of R-script")
