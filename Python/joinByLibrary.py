# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: joinByLibrary.py
# Joins non-spatial data to spatial data as defined in a csv library
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys


dataPath = arcpy.GetParameterAsText(0)
overwriteExisting = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]

if overwriteExisting == "true":

    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "joinByLibrary.r")

    # prepare communication
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", rScriptPath, dataPath, overwriteExisting]

    # run R-script
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)

    # get console prints, warnings and errors
    outString, errString = rCommand.communicate()
    scriptSource.close()


    # send warnings and errors to ArcGIS
    if errString and "...completed execution of R-script" not in outString:
        arcpy.AddMessage(errString)


# send parameter to ArcGIS
arcpy.SetParameterAsText(2, dataPath)