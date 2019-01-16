# Name: landUseToSealing.py
# Deducts degree of sealing by landuse

import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
modelFolder = arcpy.GetParameterAsText(0) 
executeThisScript = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]


if executeThisScript == "true":

    # execute R-Script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "landUseToSealing.r")
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", modelFolder, rScriptPath] 
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    resString, errString = rCommand.communicate()
    scriptSource.close()
    if errString and "...completed execution of R script" not in resString:
        arcpy.AddMessage(errString)
    
# send parameter to ArcGIS
arcpy.SetParameterAsText(2, modelFolder)