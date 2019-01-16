# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: CreateDataStructure.py
# This Script searches provided data for information in order to feed the simulation model
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys
import fnmatch
import shutil

# inputs from ArcGIS
inputFolderPath = arcpy.GetParameterAsText(0)
studyArea = arcpy.GetParameterAsText(1)
outputFolderName = arcpy.GetParameterAsText(2)
overwriteExisting = arcpy.GetParameterAsText(3)

# get file path of this python module
pyScript = sys.argv[0]

# # set output extent
# descSA = arcpy.Describe(studyArea)
# arcpy.env.extent = descSA.extent

outputFolderPath = inputFolderPath + "/" + outputFolderName

if ((os.path.exists(outputFolderPath) == False)) or (overwriteExisting == "true"):
    
    if os.path.exists(outputFolderPath):
        shutil.rmtree(outputFolderPath)

    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "CreateDataStructure.r")
    
    # prepare communication
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", inputFolderPath, rScriptPath, studyArea, outputFolderName] 
    
    # run R-script
    scriptSource = open(rScript, 'rb')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    
    # get console prints, warnings and errors
    resString, errString = rCommand.communicate()
    scriptSource.close()
    
    # send warnings and errors to ArcGIS
    if str(errString) and "...completed execution of R script" not in str(resString):
        arcpy.AddMessage(errString)
    
    
    # get all shapefiles
    allshp = []
    for root, dirnames, filenames in os.walk(os.path.join(inputFolderPath, outputFolderName)):
        for filename in fnmatch.filter(filenames, '*.shp'):
            allshp.append(os.path.join(root, filename))
    
    
    # define coordinate system and delete first feature
    spatial_ref = arcpy.Describe(studyArea).spatialReference
    
    for shp in allshp:
        arcpy.DefineProjection_management(shp, spatial_ref)
        if fnmatch.fnmatch(shp, "*AnalyseErgebnisse*") == False:
            arcpy.DeleteFeatures_management(shp)
    
arcpy.SetParameterAsText(4, outputFolderName)