# lookForStudyAreaShapefile.py

import arcpy
import os
import subprocess
import sys
import csv

# get input from ArcGIS
dataPath = arcpy.GetParameterAsText(0)
pyScript = sys.argv[0]

try:

    # look for study area shapefile
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "lookForStudyAreaShapefile.r")
    arcpy.SetProgressor("default", "Executing R Script...")
    args = ["R", "--slave", "--vanilla", "--args", dataPath, rScriptPath] 
    scriptSource = open(rScript, 'r')
    rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
    outString, errString = rCommand.communicate()
    scriptSource.close()
    if errString and "...completed execution of R-script" not in outString:
        arcpy.AddMessage(errString)
    
    # read study area path
    userTab = []
    with open(os.path.join(dataPath, "studyAreaPath.csv"), 'r') as csvfile:
        csvObj = csv.reader(csvfile, delimiter=';')
        for row in csvObj:
            userTab.append(row)
            
    foundShp =  userTab[0][0]

except:
    foundShp = "0"
    arcpy.AddMessage("Unable to find study area shapefile.")
 
# send parameter to ArcGIS
arcpy.SetParameterAsText(1, foundShp)