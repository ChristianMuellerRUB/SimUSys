# renameFiles.r
# Searches for data and renames them according to a .csv-Table

# input from python
args <- commandArgs()
provDat <- args[5]
wd <- args[6]

# prepare data path
provDat <- gsub(pattern = "\\", replacement = "/", x = provDat, fixed = T)
wd <- gsub(pattern = "\\", replacement = "/", x = wd, fixed = T)


setwd(wd)

if (substring(wd, nchar(wd), nchar(wd)) != "/") wd <- paste(wd, "/", sep = "")


# change file names if they contain a "."
withPoints <- character()
allFiles <- list.files(provDat, pattern = "*", full.names = T, recursive = T)
for (i in 1:length(allFiles)){
  fileName <- strsplit(basename(allFiles[i]), ".", fixed = T)[[1]][1]
  if (length(fileName) > 0){
    collapseFilename <- paste(strsplit(basename(allFiles[i]), ".", fixed = T)[[1]][1:(length(strsplit(basename(allFiles[i]), ".", fixed = T)[[1]])-1)], sep = "", collapse = "")
    fileExt <- strsplit(basename(allFiles[i]), ".", fixed = T)[[1]][length(strsplit(basename(allFiles[i]), ".", fixed = T)[[1]])]
    outName <- paste(dirname(allFiles[i]), "/", collapseFilename, ".", fileExt, sep = "")
    try(file.rename(from = allFiles[i], to = outName), silent = T)
  }
}


# read in rename library
lib <- read.table("renameFiles.csv", sep = ";", dec = ".", header = T, stringsAsFactors = F)


# find data according to rename library
for (i in 1:nrow(lib)){
  allFiles <- list.files(provDat, pattern = paste(lib[i,1], ".*", sep = ""), full.names = T, recursive = T)
  if (length(allFiles) != 0){
    for (f in 1:length(allFiles)){
      thisFileName <- strsplit(allFiles[f], split = ".", fixed = T)[[1]]
      thisFileTest <- strsplit(allFiles[f], split = paste(lib[i,1], ".", sep = ""), fixed = T)[[1]]
      if (length(thisFileTest) == 2){
        toName <- paste(dirname(thisFileName[1]), "/", lib[i,2], ".", thisFileName[2], sep = "")
        file.rename(from = allFiles[f], to = toName)
      }
    }
  }
}

print("...completed execution of R script")