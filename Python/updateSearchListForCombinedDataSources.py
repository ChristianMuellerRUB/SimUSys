# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: updateSearchListForCombinedDataSources.py
# Updates the data source list if combined data sources are detected
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys


dataPath = arcpy.GetParameterAsText(0)
ModelDataFolderName = arcpy.GetParameterAsText(1)
executeThisScript = arcpy.GetParameterAsText(2)
pyScript = sys.argv[0]

if executeThisScript == "true":

    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "updateSearchListForCombinedDataSources.r")
     
    # prepare communication
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", dataPath, ModelDataFolderName]
     
    # run R-script
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
     
    # get console prints, warnings and errors
    outString, errString = rCommand.communicate()
    scriptSource.close()
    
     
    # send warnings and errors to ArcGIS
    if errString and "...completed execution of R-script" not in outString:
        arcpy.AddMessage(errString)

# send parameter to ArcGIS
arcpy.SetParameterAsText(3, dataPath)