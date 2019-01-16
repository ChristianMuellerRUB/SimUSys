# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: clipShapefileSelfoverwrite.py
# Performs a clip operation overwritting the input shapefile
# --------------------------------------------------------------------

import arcpy
import os
import sys

inShp = arcpy.GetParameterAsText(0)
clipShp = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]

# clip to intermediate file
interm = os.path.dirname(inShp) + "\intermediate.shp"

try:
    arcpy.Clip_analysis(inShp, clipShp, interm)

    # delete original dataset
    arcpy.Delete_management(inShp)

    # rename clipped dataset
    arcpy.Rename_management(interm, inShp)

except:
    arcpy.AddMessage("No features to clip.")

# send parameter to ArcGIS
arcpy.SetParameterAsText(2, inShp)

