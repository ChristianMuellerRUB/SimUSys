# Christian Mueller, christian1.mueller@hs-bochum.de, Bochum University of Applied Sciences

# input from python
# inShp = "C:/HochschuleBochum/Daten/Bochum/OSMData/OSMData_roads.shp"
# inShp = "C:/HochschuleBochum/Daten/Bochum/Netzwerke/Fusswegenetz_korrigiert_workingData.shp"
# inField1 = "Tunnel_int"
# inField2 = "Bruecke_int"
# outField = "brOTu"
# wd  = 'C:\\HochschuleBochum\\CodesScripts\\R'


args <- commandArgs()
inShp = args[5]
inField1 = args[6]
inField2 = args[7]
outField  = args[8]
wd  = args[9]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(wd, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("foreign", lib.loc = paste(wd, "libraries", sep = "/"))) install.packages("foreign", lib = paste(wd, "libraries", sep = "/"))
}


# read attribute table
attTab <- read.dbf(paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."), as.is = T)

# get field data
tunhit <- grep(x = colnames(attTab), pattern = substr(inField1, 1, 9))
dat1 <- attTab[,tunhit]
brihit <- grep(x = colnames(attTab), pattern = substr(inField2, 1, 9))
dat2 <- attTab[,brihit]

# add field
outdat <- numeric(nrow(attTab))
for (i in 1:nrow(attTab)){
  if ((dat1[i] != 0) || (dat2[i] != 0)) outdat[i] <- 1
}
outTab <- cbind(attTab, outdat)
colnames(outTab)[ncol(outTab)] <- outField

# write .dbf to file
write.dbf(outTab, file = paste(strsplit(inShp, ".", fixed = T)[[1]][1], "dbf", sep = "."))

# report to ArcGIS
print ("...finished execution of R-Script.")
