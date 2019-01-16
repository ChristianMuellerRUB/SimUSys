# Name: createGrid.py
# Creates a grid shapefile of rectangular cells (similar to rasters)
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
outputFolder = arcpy.GetParameterAsText(0)
outputName = arcpy.GetParameterAsText(1)
studyAreaPath = arcpy.GetParameterAsText(2)
cellSize = arcpy.GetParameterAsText(3)
CoordinateSystem = arcpy.GetParameterAsText(4)
overwriteExisting = arcpy.GetParameterAsText(5)
pyScript = sys.argv[0]


# get spatial reference of the study area shapefile
spatial_ref = arcpy.Describe(studyAreaPath).spatialReference
spatial_refString = spatial_ref.exportToString()
    
# check if the coordinate system of the study area shapefile is the same as the specified coordinate system and reproject if necessary
if (spatial_refString[0:40] == CoordinateSystem[0:40]) != True:
    studyAreaPath_proj = os.path.splitext(studyAreaPath)[0] + "_proj.shp"
    if os.path.isfile(studyAreaPath_proj):
        arcpy.Delete_management(studyAreaPath_proj)
    arcpy.Project_management(studyAreaPath, studyAreaPath_proj, CoordinateSystem)
    studyAreaPath = studyAreaPath_proj
    

# delete output if it should be overwritten
outputPath = outputFolder + "\\" + outputName
outputPath_points = outputPath.split(".")[0] + "_punkte.shp"
if ((os.path.isfile(outputPath)) and (overwriteExisting == "true")):
    arcpy.Delete_management(outputPath)
if ((os.path.isfile(outputPath_points)) and (overwriteExisting == "true")):
    arcpy.Delete_management(outputPath_points)


# execute the rest of the script only if the output is not already present 
if ((os.path.isfile(outputPath) == False) or (os.path.isfile(outputPath_points) == False)):

    # execute R-Script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "createGrid.r")
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", outputPath, studyAreaPath, cellSize, rScriptPath] 
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    outString, errString = rCommand.communicate()
    scriptSource.close()
    if errString and "...completed execution of R-script" not in outString:
        arcpy.AddMessage(errString)
        
        
    # define coordinate system and delete first feature
    allshp = [outputPath, outputPath_points]
    for shp in allshp:
        arcpy.DefineProjection_management(shp, CoordinateSystem)
        
    # delete rgdal feature fields
    def deleteFields(shapefile, name):
        IDFieldExists = False
        allFields = arcpy.ListFields(shapefile)
        for i in range(0, len(allFields)):
            if allFields[i].name == name:
                IDFieldExists = True
        if IDFieldExists:
            arcpy.DeleteField_management(shapefile, name)
    deleteFields(outputPath, "SP_ID")
    deleteFields(outputPath_points, "SP_ID")
    deleteFields(outputPath, "coords_x1")
    deleteFields(outputPath_points, "coords_x1")
    deleteFields(outputPath, "coords_x2")
    deleteFields(outputPath_points, "coords_x2")
            
# send parameter to ArcGIS
arcpy.SetParameterAsText(6, outputPath)
arcpy.SetParameterAsText(7, outputPath_points)