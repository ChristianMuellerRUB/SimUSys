# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: reprojectIfNecessary.py
# Reprojects a given shapefile if the coordinate system does not match the desired coordinate system
# --------------------------------------------------------------------

import arcpy
import os


# inputs from ArcGIS
inShape = arcpy.GetParameterAsText(0)
desCoordSys = arcpy.GetParameterAsText(1)


outShape = inShape

spatial_ref = arcpy.Describe(inShape).spatialReference
spatial_refString = spatial_ref.exportToString()

if (spatial_refString[0:40] == desCoordSys[0:40]) != True:
    outShape = os.path.splitext(inShape)[0] + "_proj.shp"
    arcpy.Project_management(inShape, outShape, desCoordSys)            

# send parameter to ArcGIS
arcpy.SetParameterAsText(2, outShape)
