# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: downloadExternalGeodata.py
# Automatically downloads geodata from sources specified in a table
# --------------------------------------------------------------------

import arcpy
import os
import sys
import subprocess


# input from ArcGIS
provDat = arcpy.GetParameterAsText(0)
studyArea = arcpy.GetParameterAsText(1)
overwriteExisting = arcpy.GetParameterAsText(2)
pyScript = sys.argv[0]


studyAreaOrig = studyArea

if overwriteExisting == "true":
    
    arcpy.AddMessage("Downloading data from external sources...")
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "downloadExternalGeodata.r")
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", rScriptPath, provDat, studyArea]  
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    outString, errString = rCommand.communicate()
    scriptSource.close()
    if (errString != "") and ("...completed execution of R-script" not in outString):
        arcpy.AddMessage(errString)
        
# send parameter to ArcGIS
arcpy.SetParameterAsText(3, provDat)

