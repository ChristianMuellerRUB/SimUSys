# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: repairSpecialCharactersInAttributeTable.py
# replaces special characters in attribute tables
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
shapefilePath = arcpy.GetParameterAsText(0)


# get file path of this python module
pyScript = sys.argv[0]

outShp = "0"


try:

    outShp = shapefilePath
    
    # make list from input 
    shapefilePath = shapefilePath.split(";")
    
    
    # loop over each shapefile
    for i in range(0,len(shapefilePath)):
        
        shp = shapefilePath[i]
        arcpy.AddMessage("Processing " + shp + " (" + str(i+1) + "/" + str(len(shapefilePath)) + ")...")
        
    
        # get file path for R-script
        thisScriptPath = os.path.dirname(pyScript)
        rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
        rScript = os.path.join(rScriptPath, "repairSpecialCharactersInAttributeTable.r")
        
        # prepare communication
        arcpy.SetProgressor("default", "Executing R Script...")
        args = ["R", "--slave", "--vanilla", "--args", shp, rScriptPath] 
        
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
    arcpy.AddMessage("Unable to find house address data.")
    outShp = "0"


arcpy.SetParameterAsText(1, outShp)