# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: aggregatePopulationDataByField.py
# Aggregates demographic population data by fields
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
inFile = arcpy.GetParameterAsText(0)
birthDateFieldName = arcpy.GetParameterAsText(1)
genderFieldName = arcpy.GetParameterAsText(2)
migrationFieldNames = arcpy.GetParameterAsText(3)
aggregateFieldName = arcpy.GetParameterAsText(4)
aloneFieldName = arcpy.GetParameterAsText(5)
outSuffix = arcpy.GetParameterAsText(6)


# get file path of this python module
pyScript = sys.argv[0]

outFilePath = inFile

try:
    
    # define output file path
    outFilePath = os.path.dirname(inFile) + "/" + os.path.basename(inFile).split(".")[0] + "_" + outSuffix + ".csv"
    outFilePath2 = os.path.dirname(inFile) + "/" + os.path.basename(inFile).split(".")[0] + "_" + outSuffix + ".xlsx"
    outFilePath3 = os.path.dirname(inFile) + "/" + os.path.basename(inFile).split(".")[0] + "_" + outSuffix + ".xlsx/" + outSuffix + "$"
    
    
    
    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "aggregatePopulationDataByField.r")
        
    # prepare communication
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", inFile, birthDateFieldName, genderFieldName, migrationFieldNames, outFilePath, aggregateFieldName, aloneFieldName, rScriptPath, outSuffix] 
        
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



arcpy.SetParameterAsText(7, outFilePath)
arcpy.SetParameterAsText(8, outFilePath2)
arcpy.SetParameterAsText(9, outFilePath3)