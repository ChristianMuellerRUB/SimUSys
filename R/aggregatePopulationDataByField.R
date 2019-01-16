# aggregatePopulationDataByField.r
# Aggregates demographic population data by fields

# input from python
args <- commandArgs()
inFile <- args[5]
birthDateFieldName <- args[6]
genderFieldName <- args[7]
migrationFieldNames <- args[8]
outFilePath <- args[9]
aggregateFieldName <- args[10]
aloneFieldName <- args[11]
rScriptPath <- args[12]
outSuffix <- args[13]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(rScriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("XLConnect", lib.loc = paste(rScriptPath, "libraries", sep = "/"))) install.packages("XLConnect", lib = paste(rScriptPath, "libraries", sep = "/"))
}


# determine file extension
fileExtension <- strsplit(inFile, ".", fixed = T)[[1]][2]

# read data
if (fileExtension == "shp"){
  dat <- read.dbf(paste(strsplit(inFile, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
}
if (fileExtension == "csv"){
  dat <- read.table(inFile, header = T, sep = ";", dec = ".")
  for (i in 1:ncol(dat)){
    if (T %in% is.na(dat[,i])){
      dat[which(is.na(dat[,i])),i] <- ""
    }
  }
}

# prepare birth data
birthPos <- which(colnames(dat) == birthDateFieldName)
thisYear <- as.numeric(substring(Sys.time(), 1, 4))
dat$age <- thisYear - dat[,birthPos]

# prepare gender data
genderPos <- which(colnames(dat) == genderFieldName)
dat$male <- 0
dat[which(dat[,genderPos] %in% c("m", "male", "maennlich", "maenn", "maen", "Mann", "mann")),ncol(dat)] <- 1
dat$female <- 0
dat[which(dat[,genderPos] %in% c("f", "female", "w", "weiblich", "weibl", "weib", "Frau", "frau")),ncol(dat)] <- 1

# prepare population number
dat$population <- 1


# prepare alone data
alonePos <- which(colnames(dat) == aloneFieldName)
dat$alone <- 0
dat[which(dat[,aloneFieldName] %in% c("LD", "GT", "GS", "VW", "LA", "LV")),ncol(dat)] <- 1



# combine migratory background fields
migrationFieldNames <- substring(migrationFieldNames, 2, nchar(migrationFieldNames) - 1)
migrationFieldNames <- strsplit(migrationFieldNames, ",", fixed = T)[[1]]
migrationFieldNames <- sub(x = migrationFieldNames, pattern = " ", replacement = "")
for (i in 1:length(migrationFieldNames)){
  migrationFieldNames[i] <- substring(migrationFieldNames[i], 2, nchar(migrationFieldNames[i]) - 1)
}

# prepare migration data
migrationPos <- which(colnames(dat) %in% migrationFieldNames)
dat$migratoryBackground <- 0
for (c in migrationPos){
  temp <- as.character(dat[,c])
  temp[which(is.na(temp))] <- ""
  dat[which(temp %in% c("deutsch", "Deutsch", "deutschland", "Deutschland", "0", "D", "") == F), ncol(dat)] <- 1
}


# get field positions
birthPos <- which(colnames(dat) == "age")
malePos <- which(colnames(dat) == "male")
femalePos <- which(colnames(dat) == "female")
migrationPos <- which(colnames(dat) == "migratoryBackground")
popPos <- which(colnames(dat) == "population")
alonePos <- which(colnames(dat) == "alone")


# get unique aggregate fields
aggFieldPos <- which(colnames(dat) == aggregateFieldName)
allAggs <- as.data.frame(unique(as.character(dat[,aggFieldPos])))
colnames(allAggs) <- "addressID"
allAggs$meanAge <- 0
allAggs$minAge <- 0
allAggs$maxAge <- 0
allAggs$male <- 0
allAggs$female <- 0
allAggs$migBack <- 0
allAggs$pop <- 0
allAggs$alone <- 0
allAggs$tar_child <- 0
allAggs$tar_young <- 0
allAggs$tar_senio <- 0


# loop over each unique aggregate entry
multicoreFunction <-  function(a){
  if (aggregateFieldName != "ID"){
    
    for (a in 1:nrow(allAggs)){
      
        thisAgg <- as.character(allAggs[a,1])
        thisRows <- which(dat[,aggFieldPos] == thisAgg)
        allAggs[a, which(colnames(allAggs) == "meanAge")] <- mean(dat[thisRows, birthPos])
        allAggs[a, which(colnames(allAggs) == "minAge")] <- min(dat[thisRows, birthPos])
        allAggs[a, which(colnames(allAggs) == "maxAge")] <- max(dat[thisRows, birthPos])
        allAggs[a, which(colnames(allAggs) == "male")] <- sum(dat[thisRows, malePos])
        allAggs[a, which(colnames(allAggs) == "female")] <- sum(dat[thisRows, femalePos])
        allAggs[a, which(colnames(allAggs) == "migBack")] <- sum(dat[thisRows, migrationPos])
        allAggs[a, which(colnames(allAggs) == "pop")] <- length(thisRows)
        allAggs[a, which(colnames(allAggs) == "alone")] <- sum(dat[thisRows, alonePos])
        allAggs[a, which(colnames(allAggs) == "tar_child")] <- length(which(dat[thisRows,birthPos] < 12))
        allAggs[a, which(colnames(allAggs) == "tar_young")] <- length(which((dat[thisRows,birthPos] >= 12) & (dat[thisRows,birthPos] < 18)))
        allAggs[a, which(colnames(allAggs) == "tar_senio")] <- length(which(dat[thisRows,birthPos] >= 65))
        if (length(thisRows) == 1) allAggs[a, "addressID"] <- as.character(dat[thisRows,"addressID"])
    }
            
  } else {
      
      allAggs[, "meanAge"] <- dat[,"age"]
      allAggs[, "minAge"] <- dat[,"age"]
      allAggs[, "maxAge"] <- dat[,"age"]
      allAggs[, "male"] <- dat[,"male"]
      allAggs[, "female"] <- dat[,"female"]
      allAggs[, "migBack"] <- dat[,"migratoryBackground"]
      allAggs[, "pop"] <- dat[,"population"]
      allAggs[, "alone"] <- dat[,"alone"]
      allAggs[which(dat[,"age"] < 12), "tar_child"] <- 1
      allAggs[which(dat[,"age"] >= 12 & dat[,"age"] < 18), "tar_young"] <- 1
      allAggs[which(dat[,"age"] >= 65), "tar_senio"] <- 1
      allAggs <- cbind(as.character(dat[,"addressID"]), allAggs[,2:ncol(allAggs)])
      colnames(allAggs)[1] <- "addressID"
      
  }
}

# prepare multicore processing
nUseCores <- detectCores() - 0
if (nUseCores == 0) nUseCores <- 1
cl <- makePSOCKcluster(nUseCores)
clusterExport(cl, ls(), envir = .GlobalEnv)

# run loop over each layer as multicore processing
parLapply(cl = cl, X = 1:nrow(allAggs), fun = multicoreFunction)

# close multicore processing
stopCluster(cl)


# add original data if attribute fields are not the same
if (nrow(allAggs) == nrow(dat)){
  allAggs <- cbind(allAggs, dat[,-which(colnames(dat) %in% colnames(allAggs))])
}

# write  to file
if (fileExtension == "shp"){
  write.dbf(allAggs, file = paste(strsplit(inFile, ".", fixed = T)[[1]][1], "dbf", sep = "."))
}
if (fileExtension == "csv"){
  write.table(allAggs, file = outFilePath, sep = ";", dec = ".", col.names = T, row.names = F)
}


print("...completed execution of R-script")
