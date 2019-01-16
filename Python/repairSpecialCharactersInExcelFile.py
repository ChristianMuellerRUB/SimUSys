# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: repairSpecialCharactersInExcelFile.py
# replaces special characters in excel files
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
excelFilePath = arcpy.GetParameterAsText(0)

# get file path of this python module
pyScript = sys.argv[0]


outShp = excelFilePath

outCSVPath = "0"

try:

    # make list from input 
    excelFilePath = excelFilePath.split(";")
    
    
    # loop over each shapefile
    for i in range(0,len(excelFilePath)):
        
        shp = excelFilePath[i]
        outCSVPath = os.path.dirname(shp) + "/" + os.path.basename(shp).split(".")[0] + "_noSpecChar.csv"
        arcpy.AddMessage("Processing " + shp + " (" + str(i+1) + "/" + str(len(excelFilePath)) + ")...")
        
    
        # get file path for R-script
        thisScriptPath = os.path.dirname(pyScript)
        rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
        rScript = os.path.join(rScriptPath, "repairSpecialCharactersInExcelFile.r")
        
        # prepare communication
        arcpy.SetProgressor("default", "Executing R Script...")
        args = ["R", "--slave", "--vanilla", "--args", shp, outCSVPath, rScriptPath] 
        
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



arcpy.SetParameterAsText(1, outCSVPath)