# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: buildAddressID.py
# Builds an address ID from address fields
# --------------------------------------------------------------------


import arcpy
import os
import sys
import subprocess



# inputs from ArcGIS
inShp = arcpy.GetParameterAsText(0)
streetFieldName = arcpy.GetParameterAsText(1)
houseNumberFieldName = arcpy.GetParameterAsText(2)
houseNumberAdditionFieldName = arcpy.GetParameterAsText(3)
cityFieldName = arcpy.GetParameterAsText(4)
ZIPCodeFieldName = arcpy.GetParameterAsText(5)
pyScript = sys.argv[0]


if (len(streetFieldName) > 0) and (len(houseNumberFieldName) > 0) and (len(houseNumberAdditionFieldName) > 0) and (len(cityFieldName) > 0) and (len(ZIPCodeFieldName) > 0): 

    
    # get file path for R-script which appends all distance data to the analysis grid point shapefile
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "buildAddressID.r")
    
    # prepare communication
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", inShp, streetFieldName, houseNumberFieldName, houseNumberAdditionFieldName, cityFieldName, ZIPCodeFieldName, rScriptPath] 
    
    # run R-script
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    
    # get console prints, warnings and errors
    resString, errString = rCommand.communicate()
    scriptSource.close()
    
    # send warnings and errors to ArcGIS
    if errString and "...completed execution of R script" not in resString:
        arcpy.AddMessage(errString)
    
    
    
    # send parameter to ArcGIS
    arcpy.SetParameterAsText(6, inShp)
    
else:
    arcpy.AddMessage("Missing field name information for addresses.")