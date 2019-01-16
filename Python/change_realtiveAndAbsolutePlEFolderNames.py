# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: change_realtiveAndAbsolutePlEFolderNames.py
# Changes the names of absolute and relative planning entity folders
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys

# modFolder = 'C:/HochschuleBochum/Daten/Herten/SimUSys_modelData'
# pyScript = "C:\\HochschuleBochum\\CodesScripts\\Python\\addAdditionalInformationToAttributeTable.py"


modFolder = arcpy.GetParameterAsText(0)
pyScript = sys.argv[0]

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

# get R-script path
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")

# execute R-script
rScript = os.path.join(rScriptPath, "change_realtiveAndAbsolutePlEFolderNames.r")
executeRScript(rScript, [modFolder])


# send parameter to ArcGIS
arcpy.SetParameterAsText(1, modFolder)