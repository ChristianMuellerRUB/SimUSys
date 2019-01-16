# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: addFieldsToAttributeTable.py
# Adds fields of one file to the attribute table of a shapefile
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
toShapefile = arcpy.GetParameterAsText(0)
addFile = arcpy.GetParameterAsText(1)
toJoinField = arcpy.GetParameterAsText(2)
fromJoinField = arcpy.GetParameterAsText(3)
addFieldNames = arcpy.GetParameterAsText(4)
fieldsToCalculateMeanForMultipleMatches = arcpy.GetParameterAsText(5)

# get file path of this python module
pyScript = sys.argv[0]


try:
    
    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "addFieldsToAttributeTableByFile.r")
        
    # prepare communication
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", toShapefile, addFile, toJoinField, fromJoinField, addFieldNames, fieldsToCalculateMeanForMultipleMatches, rScriptPath] 
        
    # run R-script
    scriptSource = open(rScript, 'rb')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
        
    # get console prints, warnings and errors
    resString, errString = rCommand.communicate()
    scriptSource.close()
        
    # send warnings and errors to ArcGIS
    if errString and "...completed execution of R script" not in resString:
        arcpy.AddMessage(errString)

except:
    arcpy.AddMessage("Unable to import address data.")


arcpy.SetParameterAsText(6, toShapefile)
