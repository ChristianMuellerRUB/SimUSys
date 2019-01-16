# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: spatialJoinPointsToPolygon.py
# Spatially joins informations in the attribute table of points to the attribute table of polygons
# --------------------------------------------------------------------


import arcpy
import sys
import os


# inputs from ArcGIS
targetPolygons = arcpy.GetParameterAsText(0)
sourcePoints = arcpy.GetParameterAsText(1)


try:

    # define output file path
    outPolygonFile = os.path.dirname(targetPolygons) + "/" + "Hausumringe.shp"
    
    
    # get file path of this python module
    pyScript = sys.argv[0]
    
    
    # spatial join
    arcpy.SpatialJoin_analysis(targetPolygons, sourcePoints, outPolygonFile, "JOIN_ONE_TO_ONE", "KEEP_ALL", "", "CONTAINS")

except:
    arcpy.AddMessage("Unable to import address data.")



arcpy.SetParameterAsText(2, outPolygonFile)
