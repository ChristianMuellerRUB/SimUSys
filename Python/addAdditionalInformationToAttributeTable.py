# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: addAdditionalInformationToAttributeTable.py
# Adds additional information, such as coordinates and data model specifications, to the attribute table
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys


dataPath = arcpy.GetParameterAsText(0)
modelNamePath = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]


# define model data directory
modDataDirPath = dataPath + "/" + modelNamePath


# get rScript path
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
rScript = os.path.join(rScriptPath, "addAdditionalInformationToAttributeTable.r")


# set variables
arcpy.SetProgressor("default", "Executing R Script...")
args = ["R", "--slave", "--vanilla", "--args", dataPath, modelNamePath, rScriptPath, modDataDirPath, rScriptPath] 

# open and execute R-Script
scriptSource = open(rScript, 'r')
rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
outString, errString = rCommand.communicate()
scriptSource.close()

# push errors to ArcGIS
if (errString != "") and ("...completed execution of R-script" not in outString):
    arcpy.AddMessage(errString)

    
 
# send parameter to ArcGIS
arcpy.SetParameterAsText(2, dataPath)

