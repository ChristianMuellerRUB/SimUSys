# dissolveWithNoDataValue.r

# input from python
args <- commandArgs()
inShp <- args[5]
outShp <- args[6]
disField <- args[7]
attStats <- args[8]
noDataValue <- args[9]
scriptPath <- args[10]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("foreign", lib = paste(scriptPath, "libraries", sep = "/"))
}


# read in data
dat <- read.dbf(paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)
dat_target <- read.dbf(paste(strsplit(outShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)

# prepare no data value
noDataValue <- as.numeric(noDataValue)

# prepare dissolve algorithm
alg <- strsplit(attStats, ";")[[1]]
calc <- matrix("", nrow = length(alg), ncol = 2, dimnames = list(1:length(alg), c("fieldName", "calc")))
for (i in 1:length(alg)){
  calc[i,1] <- strsplit(alg[i], " ")[[1]][1]
  calc[i,2] <- strsplit(alg[i], " ")[[1]][2]
}


# create output 
keepEnts <- as.numeric(sort(unique(dat_target[,which(colnames(dat_target) == disField)])))
out <- cbind(grid_ID = keepEnts)
for (i in 1:nrow(calc)){
  out <- cbind(out, noDataValue)
  colnames(out)[ncol(out)] <- calc[i,1]
}

out <- out[,which(colnames(out) %in% colnames(dat))]

for (i in 1:length(keepEnts)){
  thisPos <- which(dat[,which(colnames(dat) == disField)] == keepEnts[i])
  if (length(thisPos) > 0){
    for (f in 1:nrow(calc)){
      colPos <- which(colnames(dat) == calc[f,1])
      if (length(colPos) > 0){
        calcVals <- dat[thisPos, colPos]
        calcVals <- calcVals[which(calcVals != noDataValue)]
        if (length(calcVals) > 0){
          if (calc[f,2] == "SUM") out[which(out[,1] == keepEnts[i]), f+1] <- sum(calcVals)
          if (calc[f,2] == "MEAN") out[which(out[,1] == keepEnts[i]), f+1] <- mean(calcVals)
        }
      }
    }
  }
}

# write to file
write.dbf(out, file = paste(strsplit(outShp, ".", fixed = T)[[1]][1], "dbf", sep = "."))


print("...completed execution of R-script")