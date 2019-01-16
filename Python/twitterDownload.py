# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: twitterDownload.py
# gets sentiment data from twitter
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys


# inputs from ArcGIS
studyAreaFile = arcpy.GetParameterAsText(0)
outLoc = arcpy.GetParameterAsText(1)
lan = arcpy.GetParameterAsText(2)
executeThisScript = arcpy.GetParameterAsText(3)
pyScript = sys.argv[0]

arcpy.AddMessage(executeThisScript)

if executeThisScript == "true":

    # define function for executing R-Scripts
    def executeRScript(rScript, arguments):
        arcpy.SetProgressor("default", "Executing R Script...")
        args = ["R", "--slave", "--vanilla", "--args"]
        for thisArgument in range(0, len(arguments)):
            args.append(arguments[thisArgument])
        scriptSource = open(rScript, 'r')
        rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
        outString, errString = rCommand.communicate()
        scriptSource.close()
        if errString and "...completed execution of R-script" not in outString:
            arcpy.AddMessage(errString)

    # get planning entities with highest resolution per field
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "twitterDownload.r")

    # execute R-Script
    executeRScript(rScript, [rScriptPath, studyAreaFile, outLoc, lan])

arcpy.SetParameterAsText(4, outLoc)