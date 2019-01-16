# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: addSpatialAttractivenessDataToSimulation.py
# Searches for data about spatial attractiveness and adds it to the model
# --------------------------------------------------------------------

import arcpy
import sys
import os
import subprocess

provDat = arcpy.GetParameterAsText(0)
ModelDataFolderName = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]


# define model data directory
modDataDirPath = provDat + "/" + ModelDataFolderName


# get rScript path
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
rScript = os.path.join(rScriptPath, "addSpatialAttractivenessDataToSimulation.r")



# set variables
arcpy.SetProgressor("default", "Executing R Script...")
args = ["R", "--slave", "--vanilla", "--args", provDat, ModelDataFolderName, rScriptPath]

# open and execute R-Script
scriptSource = open(rScript, 'r')
rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
outString, errString = rCommand.communicate()
scriptSource.close()

# push errors to ArcGIS
if (errString != "") and ("...completed execution of R-script" not in outString):
    arcpy.AddMessage(errString)


 
# send parameter to ArcGIS
arcpy.SetParameterAsText(2, provDat)

