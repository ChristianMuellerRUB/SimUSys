# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: combineFiles.py
# Combines multiple files as specified in a script table
# --------------------------------------------------------------------

import arcpy
import os
import sys
import fnmatch
import csv
import subprocess


provDat = arcpy.GetParameterAsText(0)
executeThisScript = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]

if executeThisScript == "true":
    
    # get specifying table
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    userTab = []
    with open(os.path.join(rScriptPath, "combineFiles.csv"), 'r') as csvfile:
        csvObj = csv.reader(csvfile, delimiter=';')
        for row in csvObj:
            userTab.append(row)
            
    # iterate over each combination
    for l in range(1, len(userTab)):
        
        # get file information
        inputs = userTab[l][0]
        inputs = inputs.split(";")
        output = userTab[l][1]
        
        # look for full data paths
        def find(pattern, path):
            result = []
            for root, dirs, files in os.walk(path):
                for name in files:
                    if fnmatch.fnmatch(name, pattern):
                        result.append(os.path.join(root, name))
            return result
        
        full_inputs = []
        for f in range(0, len(inputs)):
            found = find(inputs[f], provDat)
            if (found != []):
                full_inputs.append(found[0])
        
        if full_inputs != []:

            full_output = os.path.dirname(full_inputs[0]) + "\\" + output

            # delete previous output if it exists
            if os.path.isfile(full_output):
                arcpy.Delete_management(full_output)

                # get file path for R-script
                thisScriptPath = os.path.dirname(pyScript)
                rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
                rScript = os.path.join(rScriptPath, "mergeAllInputs.r")

                # prepare communication
                arcpy.SetProgressor("default", "Executing R Script...")
                args = ["R", "--slave", "--vanilla", "--args", str(full_inputs), str(full_output), rScriptPath]

                # run R-script
                scriptSource = open(rScript, 'r')
                rCommand = subprocess.Popen(args, stdin=scriptSource, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                            shell=True)

                # get console prints, warnings and errors
                outString, errString = rCommand.communicate()
                scriptSource.close()

                # send warnings and errors to ArcGIS
                if errString and "...completed execution of R-script" not in outString:
                    arcpy.AddMessage(errString)

# send parameter to ArcGIS
arcpy.SetParameterAsText(2, provDat)