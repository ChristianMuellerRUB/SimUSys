# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: wipeFilesForAddressImport.py
# Looks for files to be generated during address import and deletes them if necessary
# --------------------------------------------------------------------


import arcpy
import os
import sys
import fnmatch


# inputs from ArcGIS
userDataPath = arcpy.GetParameterAsText(0)
overwriteExisting = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]


if overwriteExisting == "true":


    # get all files to be deleted
    shp = []
    for root, dirnames, filenames in os.walk(userDataPath):
        for filename in fnmatch.filter(filenames, '*Hauskoordinaten.shp'):
            shp.append(os.path.join(root, filename))
        for filename in fnmatch.filter(filenames, '*Hausumringe.shp'):
            shp.append(os.path.join(root, filename))
        for filename in fnmatch.filter(filenames, '*georeferencedFromAddresses.shp'):
            shp.append(os.path.join(root, filename))
    
    # delete files
    for i in range(0, len(shp)):
        if arcpy.Exists(shp[i]):
            arcpy.Delete_management(shp[i])
    
    
arcpy.SetParameterAsText(2, userDataPath)