# getVertexCoordinates.r

getVertexCoordinates <- function(so){
  if (class(so) == "SpatialPointsDataFrame"){
    coords <- coordinates(so)
  } else if (class(so) == "SpatialLinesDataFrame"){
    coords <- c()
    lines <- so@lines
    for (l in 1:length(lines)){
      thisLines <- lines[[l]]@Lines
      for (ls in 1:length(thisLines)){
        coords <- rbind(coords, thisLines[[ls]]@coords)
      }
    }
  } else if (class(so) == "SpatialPolygonsDataFrame"){
    coords <- c()
    polys <- so@polygons
    for (p in 1:length(polys)){
      thisPolys <- polys[[p]]@Polygons
      for (ps in 1:length(thisPolys)){
        coords <- rbind(coords, thisPolys[[ps]]@coords)
      }
    }
  }
  return(coords)
}