# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: repairAllShapefilesInFolder.py
# Finds all shapefiles in folder and repairs geometries  
# --------------------------------------------------------------------


import arcpy
import os
import fnmatch


# inputs from ArcGIS
inFolder = arcpy.GetParameterAsText(0)
subFolder = arcpy.GetParameterAsText(1)
studyArea = arcpy.GetParameterAsText(2)

# define search folder and intermediate data paths
searchFolder = os.path.join(inFolder, subFolder)
interm = searchFolder + "/intermediateData.shp"

# find all shapefiles
allshp = []
for root, dirnames, filenames in os.walk(searchFolder):
    for filename in fnmatch.filter(filenames, "*.shp"):
        allshp.append(os.path.join(root, filename))
        
# repair each shapefile
for i in range(0, len(allshp)):
    thisShp = allshp[i]
    arcpy.AddMessage("Checking and repairing geometry of " + thisShp + "...(" + str(i+1) + "/" + str(len(allshp)) + ")")
    arcpy.RepairGeometry_management(thisShp)
    
    # ensure right extent
    if arcpy.Exists(interm):
        arcpy.Delete_management(interm)
    arcpy.Clip_analysis(thisShp, studyArea, interm)
    arcpy.Delete_management(thisShp)
    arcpy.Copy_management(interm, thisShp)
    arcpy.Delete_management(interm)
    

arcpy.SetParameterAsText(3, inFolder)