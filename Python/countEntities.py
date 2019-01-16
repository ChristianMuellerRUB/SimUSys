# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: countEntities.py
# Counts entities of a specified attibute
# --------------------------------------------------------------------

import arcpy
import os
import sys
import subprocess

provDat = arcpy.GetParameterAsText(0)
executeThisScript = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]

if executeThisScript == "true":
    
    # execute R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "countEntities.r")
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", provDat, rScriptPath] 
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    outString, errString = rCommand.communicate()
    scriptSource.close()
    if errString and "...completed execution of R-script" not in outString:
        arcpy.AddMessage(errString)
        
# send parameter to ArcGIS
arcpy.SetParameterAsText(2, provDat)