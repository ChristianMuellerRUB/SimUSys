# change_realtiveAndAbsolutePlEFolderNames.r
# Changes the names of absolute and relative planning entity folders

# select shapefiles and output shapefile path
args <- commandArgs()
modFolder <- args[5]
rScriptPath <- args[6]

# get folder names
abs_dir <- paste(modFolder, "/PlanungsEinheiten_absolut", sep = "")
rel_dir <- paste(modFolder, "/PlanungsEinheiten_relativ", sep = "")
def_dir <- paste(modFolder, "/PlanungsEinheiten", sep = "")


# copy entire folder to backup absoulte values
if (file.exists(abs_dir) && file.exists(def_dir)){
  file.rename(from = def_dir, to = rel_dir)
  file.rename(from = abs_dir, to = def_dir)
} else if (file.exists(rel_dir) && file.exists(def_dir)){
  file.rename(from = def_dir, to = abs_dir)
  file.rename(from = rel_dir, to = def_dir)
}

# report to ArcGIS
print ("...finished execution of R-Script.")
