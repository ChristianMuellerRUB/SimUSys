# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: deleteIdenticalMultiple.py
# Deletes identical features as given in a list 
# --------------------------------------------------------------------


import arcpy
import os
import sys
import fnmatch


# inputs from ArcGIS
provDat = arcpy.GetParameterAsText(0)
ModelDataFolderName = arcpy.GetParameterAsText(1)
searchTolerance = arcpy.GetParameterAsText(2)
pyScript = sys.argv[0]


# find shapefiles
shps = []
for root, dirs, files in os.walk(provDat + "/" + ModelDataFolderName + "/" + "Netzwerke"):
    for file in files:
        if fnmatch.fnmatch(file, '*.shp'):
            shps.append(os.path.join(root, file))
for root, dirs, files in os.walk(provDat + "/" + ModelDataFolderName + "/" + "POI"):
    for file in files:
        if fnmatch.fnmatch(file, '*.shp'):
            shps.append(os.path.join(root, file))
for root, dirs, files in os.walk(provDat + "/" + ModelDataFolderName + "/" + "PlanungsEinheiten"):
    for file in files:
        if fnmatch.fnmatch(file, '*.shp'):
            shps.append(os.path.join(root, file))
for root, dirs, files in os.walk(provDat + "/" + ModelDataFolderName + "/" + "UmweltVersorgung"):
    for file in files:
        if fnmatch.fnmatch(file, '*.shp'):
            shps.append(os.path.join(root, file))
for root, dirs, files in os.walk(provDat + "/" + ModelDataFolderName + "/" + "AnalysenErgebnisse/1200_AnalysenErgebnisse"):
    for file in files:
        if fnmatch.fnmatch(file, '*.shp'):
            shps.append(os.path.join(root, file))



# delete identical
for i in range(0, len(shps)-1):

    arcpy.AddMessage("Processing file " + str(i+1) + "/" + str(len(shps)) + "...")

    desc = arcpy.Describe(shps[i])
    fromGeometry = str(desc.shapeType)

    if fromGeometry == 'Point':
        searchTolerance_use = searchTolerance
    else:
        searchTolerance_use = "0.01"

    if os.path.basename(shps[i]) != "8000_012_Person.shp":
        if (str(arcpy.GetCount_management(shps[i])) != '0'):
            arcpy.DeleteIdentical_management(shps[i], fields = "Shape", xy_tolerance = searchTolerance + ' Meters')

arcpy.SetParameterAsText(3, provDat)
