# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: shortestDistance_SimUSys.py
# Calculates the shortest (network\\travel cost) distance between points based on travel cost analysis
# christian1.mueller@hs-bochum.de
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys


# provDat = "C:\\HochschuleBochum\\Daten\\Bochum"
# ModelDataFolderName = "SimUSys_modelData"
# costRasCellSize = "10"
# gridCellSize = "500"
# pyScript = "C:\\HochschuleBochum\\CodesScripts\\Python\\SearchData.py"

# provDat = "C:\\HochschuleBochum\\Daten\\Herdecke"
# ModelDataFolderName = "SimUSys_modelData"
# costRasCellSize = "10"
# gridCellSize = "500"
# pyScript = "C:\\HochschuleBochum\\CodesScripts\\Python\\SearchData.py"

provDat = arcpy.GetParameterAsText(0)
ModelDataFolderName = arcpy.GetParameterAsText(1)
costRasCellSize = arcpy.GetParameterAsText(2)
gridCellSize = arcpy.GetParameterAsText(3)
pyScript = sys.argv[0]


# define model data directory
modDataDirPath = provDat + "\\" + ModelDataFolderName

# get network paths
# netPaths = [modDataDirPath + "\\Netzwerke\\9000_Netzwerke\\9000_005_FussWanderwege.shp",
#             modDataDirPath + "\\Netzwerke\\9000_Netzwerke\\9000_004_Fahrradwegenetz.shp",
#             modDataDirPath + "\\Netzwerke\\9000_Netzwerke\\9000_006_LiniennetzOePNV.shp",
#             modDataDirPath + "\\Netzwerke\\9000_Netzwerke\\9000_007_Strassennetz.shp"]
# costRasPaths = [modDataDirPath + "\\AnalysenErgebnisse\\Erreichbarkeit_zuFuss_Kostenraster.tif",
#                 modDataDirPath + "\\AnalysenErgebnisse\\Erreichbarkeit_mitFahrrad_Kostenraster.tif",
#                 modDataDirPath + "\\AnalysenErgebnisse\\Erreichbarkeit_mitOePNV_Kostenraster.tif",
#                 modDataDirPath + "\\AnalysenErgebnisse\\Erreichbarkeit_mitPKW_Kostenraster.tif"]

netPaths = [modDataDirPath + "\\Netzwerke\\9000_Netzwerke\\9000_005_FussWanderwege.shp",
            modDataDirPath + "\\Netzwerke\\9000_Netzwerke\\9000_004_Fahrradwegenetz.shp",
            modDataDirPath + "\\Netzwerke\\9000_Netzwerke\\9000_007_Strassennetz.shp"]
costRasPaths = [modDataDirPath + "\\AnalysenErgebnisse\\Erreichbarkeit_zuFuss_Kostenraster.tif",
                modDataDirPath + "\\AnalysenErgebnisse\\Erreichbarkeit_mitFahrrad_Kostenraster.tif",
                modDataDirPath + "\\AnalysenErgebnisse\\Erreichbarkeit_mitPKW_Kostenraster.tif"]


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
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")


for i in range(0,len(netPaths)):
    if (os.path.isfile(costRasPaths[i]) == False):
        flds = arcpy.ListFields(netPaths[i])
        arcpy.FeatureToRaster_conversion(netPaths[i], flds[0].name, costRasPaths[i], costRasCellSize)
        rScript = os.path.join(rScriptPath, "recodeCostRaster.r")
        executeRScript(rScript, [costRasPaths[i], rScriptPath, costRasCellSize])

# execute R-Script
rScript = os.path.join(rScriptPath, "shortestDistance_SimUSys.r")
executeRScript(rScript, [provDat, ModelDataFolderName, gridCellSize, costRasCellSize, rScriptPath])

    
# send parameter to ArcGIS
arcpy.SetParameterAsText(4, provDat)