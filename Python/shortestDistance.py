# Name: shortestDistance.py
# Calculates the shortest (network) distance between points based on travel cost analysis
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
fromPointsPath  = arcpy.GetParameterAsText(0)
toPointsPath  = arcpy.GetParameterAsText(1)
networkLinesPath  = arcpy.GetParameterAsText(2)
travelCostField  = arcpy.GetParameterAsText(3)
barriersPath  = arcpy.GetParameterAsText(4)
outFilePath = arcpy.GetParameterAsText(5)
outFieldPrefix  = arcpy.GetParameterAsText(6)
pyScript = sys.argv[0]


# execute R-Script
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
rScript = os.path.join(rScriptPath, "shortestDistance.r")
arcpy.SetProgressor("default", "Executing R Script...")
args = ["R", "--slave", "--vanilla", "--args", fromPointsPath, toPointsPath, networkLinesPath, travelCostField, barriersPath, outFilePath, outFieldPrefix, rScriptPath] 
scriptSource = open(rScript, 'r')
rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
outString, errString = rCommand.communicate()
scriptSource.close()
if errString and "...completed execution of R-script" not in outString:
    arcpy.AddMessage(errString)
        
# send parameter to ArcGIS
arcpy.SetParameterAsText(7, outFilePath)