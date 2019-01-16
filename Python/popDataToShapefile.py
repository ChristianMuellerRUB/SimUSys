# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: popDataToShapefile.py
# Creates a point feature for every citizen based on location given in an extra shapefile 
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
popTable = arcpy.GetParameterAsText(0)
IDFieldpop = arcpy.GetParameterAsText(1)
locShp = arcpy.GetParameterAsText(2)
IDFieldloc = arcpy.GetParameterAsText(3)
outSuffix = arcpy.GetParameterAsText(4)


# get file path of this python module
pyScript = sys.argv[0]


try:
    
    # define output file path
    outFilePath = os.path.dirname(popTable) + "/" + outSuffix + ".shp"
    
    
    
    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "popDataToShapefile.r")
        
    # prepare communication
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", popTable, IDFieldpop, locShp, IDFieldloc, outSuffix, outFilePath, rScriptPath] 
        
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



arcpy.SetParameterAsText(5, outFilePath)
