# aggregateSpatialAttractivenessPointsToGrid.r
# Aggregates spatial attractiveness point data to analysis grid


# get input
args <- commandArgs()
modelFolder <- args[5]
scriptPath <- args[6]


# load packages
print("Loading R-Packages...")
options(repos = c(CRAN = "http://cran.rstudio.com"))
.libPaths(paste(scriptPath, "libraries", sep = "/"))
for (i in 1:2){
  if (!require("rgdal", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("rgdal", lib = paste(scriptPath, "libraries", sep = "/"))
  if (!require("raster", lib.loc = paste(scriptPath, "libraries", sep = "/"))) install.packages("raster", lib = paste(scriptPath, "libraries", sep = "/"))
}

# get spatial attractiveness points
sa_path <- paste(modelFolder, "/AnalysenErgebnisse/1200_AnalysenErgebnisse/1200_001_Wohlfuehlpunkt.shp", sep = "")
nFeatures <- 0
try(nFeatures <- ogrInfo(dirname(sa_path), strsplit(basename(sa_path), ".", fixed = T)[[1]][1])[1], silent = T)
if (nFeatures > 0){
  
  sa <- readOGR(dirname(sa_path), strsplit(basename(sa_path), ".", fixed = T)[[1]][1])
  
  # get analysis grid
  grid_path <- paste(modelFolder, "/AnalysenErgebnisse/Gitter.shp", sep = "")
  grid <- readOGR(dirname(grid_path), strsplit(basename(grid_path), ".", fixed = T)[[1]][1])
  
  # spatial querry for selected values
  within <- over(sa, grid)
  within$point_ID <- 1:nrow(within)
  
  # extract attribute tables
  sa_dat <- sa@data
  grid_dat <- grid@data
  
  # create new attribute fields
  fields <- colnames(sa_dat)
  exFields <- c("Id", "ObjID", "ObjAB", "ObjAG", "ObjAGN", "ObjArt", "ObjArtN", "KooN", "KooE", "coords_x1", "coords_x2", "coords_x3", "OldID")
  use_fields_pos <- which(fields %in% exFields == F)
  use_fields <- fields[use_fields_pos]
  for (f in 1:length(use_fields)){
    if (is.double(sa_dat[,use_fields_pos[f]])) {
      grid_dat <- cbind(grid_dat, NA)
      colnames(grid_dat)[ncol(grid_dat)] <- use_fields[f]
    }
  }
  
  # get aggregation fields
  agg_fields <- colnames(grid_dat)[which(colnames(grid_dat) %in% use_fields)]
  
  # get unique grid IDs
  grid_IDs <- unique(within[,1])
  
  # perform aggregation
  aggregatePointsToGrid <- function(g){
    
    # get all points which are located within this cell
    pos <- which(within[,1] == g)
    
    if (length(pos) > 0){
      
      p_temp_pos <- within[pos,2]
      
      # calculate sums
      for (f in 1:length(agg_fields)){
        sumVal <- sum(sa_dat[p_temp_pos,agg_fields[f]])
        grid_dat[which(grid_dat[,"grid_ID"] == g), agg_fields[f]] <- sumVal
        grid_dat <<- grid_dat
      }
      
    }
    
  }
  for (g in grid_IDs) aggregatePointsToGrid(g)
  
  
  # calcuate well-unwell value
  grid_dat[,"wohlUn"] <- grid_dat[,"wohl"] - grid_dat[,"unwohl"]
  
  # add attribute table to spatial object
  grid@data <- grid_dat
  
  # write to file
  out_file = paste(dirname(grid_path), "/Raumattraktivitaet.shp", sep = "")
  writeOGR(grid, dsn = dirname(out_file), layer = strsplit(basename(out_file), ".", fixed = T)[[1]][1],
           driver = 'ESRI Shapefile', overwrite_layer = T)
  
}


# report to ArcGIS
print ("...finished execution of R-Script.")
