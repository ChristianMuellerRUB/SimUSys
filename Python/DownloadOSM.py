# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: downloadOSM.py
# Automatically downloads Open Street Map data
# --------------------------------------------------------------------

import arcpy
import os
import sys
import subprocess

provDat = arcpy.GetParameterAsText(0)
studyArea = arcpy.GetParameterAsText(1)
desCoordSys = arcpy.GetParameterAsText(2)
overwriteExisting = arcpy.GetParameterAsText(3)
pyScript = sys.argv[0]

studyAreaOrig = studyArea

# create output directory
toFolder = provDat + "/OSMData"
if overwriteExisting == "true":
    
    # get extent
    desc = arcpy.Describe(studyArea)
    geom = desc.spatialReference
    geom_str = geom.exportToString()
    # osm_st_geom = "PROJCS['WGS_1984_Web_Mercator_Auxiliary_Sphere',GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]],PROJECTION['Mercator_Auxiliary_Sphere'],PARAMETER['False_Easting',0.0],PARAMETER['False_Northing',0.0],PARAMETER['Central_Meridian',0.0],PARAMETER['Standard_Parallel_1',0.0],PARAMETER['Auxiliary_Sphere_Type',0.0],UNIT['Meter',1.0]]"
    osm_st_geom = "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]"

    studyArea_proj = os.path.splitext(studyArea)[0] + "_proj.shp"
    if (geom_str[0:40] == osm_st_geom[0:40]) == False:
            
            if (os.path.isfile(studyArea_proj)):
                arcpy.Delete_management(studyArea_proj) 
                        
            arcpy.Project_management(studyArea, studyArea_proj, osm_st_geom)
            studyArea = studyArea_proj
            desc = arcpy.Describe(studyArea)
           
    
    extent = desc.extent
    
    osmFilePath = toFolder + "\\OSMDownload.osm"

    ### version 2a: osm-xml-file to shp-file
    arcpy.AddMessage("Downloading an converting OSM data to shapefile...")
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "osmToshp.r")
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", osmFilePath, toFolder, ["points;lines;multipolygons"], rScriptPath, "onlyFitFields", desCoordSys, studyAreaOrig, overwriteExisting]  
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    outString, errString = rCommand.communicate()
    scriptSource.close()
    if (errString != "") and ("...completed execution of R-script" not in outString):
        arcpy.AddMessage(errString)
        
              
# send parameter to ArcGIS
arcpy.SetParameterAsText(4, provDat)

