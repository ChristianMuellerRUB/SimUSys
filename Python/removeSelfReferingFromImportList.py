# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: removeSelfReferingFromImportList.py
# Removes self refering entries from data import list
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys

provDat = arcpy.GetParameterAsText(0)
ModelDataFolderName = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]

# execute R-Script
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
rScript = os.path.join(rScriptPath, "removeSelfReferingFromImportList.r")
arcpy.SetProgressor("default", "Executing R Script...")
args = ["R", "--slave", "--vanilla", "--args", provDat, ModelDataFolderName, rScriptPath] 
scriptSource = open(rScript, 'r')
rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
outString, errString = rCommand.communicate()
scriptSource.close()
if errString and "...completed execution of R-script" not in outString:
    arcpy.AddMessage(errString)

# send parameter to ArcGIS
arcpy.SetParameterAsText(2, provDat)