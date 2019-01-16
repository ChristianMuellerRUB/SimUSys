# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: defineSimulationCoordinateSystem.py
# Defines the Coordinate System for the Simulation
# --------------------------------------------------------------------


import arcpy
import os
import fnmatch


# inputs from ArcGIS
UserDataPath = arcpy.GetParameterAsText(0)
ModelDataFolderName = arcpy.GetParameterAsText(1)
CoordinateSystem = arcpy.GetParameterAsText(2)

DataStructurePath = os.path.join(UserDataPath, ModelDataFolderName)

# get all shapefiles
allshp = []
for root, dirnames, filenames in os.walk(DataStructurePath):
    for filename in fnmatch.filter(filenames, '*.shp'):
        allshp.append(os.path.join(root, filename))


# reproject coordinate system (if coordinate system does not match)
thisShp = allshp[0]

spatial_ref = arcpy.Describe(thisShp).spatialReference
spatial_refString = spatial_ref.exportToString()

if (spatial_refString[0:40] == CoordinateSystem[0:40]) != True:
    thisShpProj = os.path.splitext(thisShp)[0] + "_proj.shp"
    arcpy.Project_management(thisShp, thisShpProj, CoordinateSystem)
    arcpy.Delete_management(thisShp)
    arcpy.Rename_management(thisShpProj, thisShp)
    
    for thisShp in allshp[1:]:
        spatial_ref = arcpy.Describe(thisShp).spatialReference
        spatial_refString = spatial_ref.exportToString()
        if (spatial_refString[0:40] == CoordinateSystem[0:40]) != True:
            thisShpProj = os.path.splitext(thisShp)[0] + "_proj.shp"
            arcpy.Project_management(thisShp, thisShpProj, CoordinateSystem)
            arcpy.Delete_management(thisShp)
            arcpy.Rename_management(thisShpProj, thisShp)
            

# send parameter to ArcGIS
arcpy.SetParameterAsText(3, UserDataPath)