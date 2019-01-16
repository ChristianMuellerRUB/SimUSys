# Name: fieldOr.py
# Adds a new field to the attribute table which contains ones for features that are either in input field one or input field two true. Otherwise it will contain zero values. 
# Project: SimUSys, Christian Mueller, christian1.mueller@hs-bochum.de, 27.10.2016
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
inShp = arcpy.GetParameterAsText(0)
inField1 = arcpy.GetParameterAsText(1)
inField2 = arcpy.GetParameterAsText(2)
outField = arcpy.GetParameterAsText(3)
pyScript = sys.argv[0]

# inShp = "C:/HochschuleBochum/Daten/Bochum/OSMData/Geostat_roads_workingData.shp"
# inField1 = "bridge_int"
# inField2 = "tunnel_int"
# outField = "brOTu"
# pyScript = "C:/HochschuleBochum/CodesScripts/Python/fieldOr.py"

allreadyPresent = False
allFields = arcpy.ListFields(inShp)
for i in range(0,len(allFields)):
    if allFields[i].name == outField:
        allreadyPresent = True


if (allreadyPresent == False):

    # execute R-Script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "fieldOr.r")
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", inShp, inField1, inField2, outField, rScriptPath] 
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    outString, errString = rCommand.communicate()
    scriptSource.close()
    if errString and "...completed execution of R-script" not in outString:
        arcpy.AddMessage(errString)

# send parameter to ArcGIS
arcpy.SetParameterAsText(4, outField)
