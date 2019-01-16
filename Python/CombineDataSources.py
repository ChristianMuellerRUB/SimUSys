# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: combineDataSources.py
# Combines multiple fitting data source shapefiles into one common shapefile with "_combined" extension
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

if executeThisScript == "true":
    
    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    rScript = os.path.join(rScriptPath, "searchData.r")
     
    
    # open data source library table
    userTab = []
    with open(os.path.join(rScriptPath, "DataSourceBib.csv"), 'r') as csvfile:
        csvObj = csv.reader(csvfile, delimiter=';')
        for row in csvObj:
            userTab.append(row)
            
    # read table for information on which polygon-to-point and polyline-to-point conversions should be executed from vertices to points rather than from midpoints to points 
    verTab = []
    with open(os.path.join(rScriptPath, "verticesToPoints.csv"), 'r') as csvfile:
        verTab = csvfile.read()

    # get all shapefiles
    allSHP = []
    allSHP_base = []
    for root, dirnames, filenames in os.walk(provDat):
        for filename in fnmatch.filter(filenames, "*.shp"):
            allSHP.append(os.path.join(root, filename))
            allSHP_base.append(filename)
    
    # for each data entry row, search for shapefiles
    for row in range(1,len(userTab)):
        
        thisName = userTab[row][9]
        
        # arcpy.AddMessage("Combining data sources which fit the name " + thisName + " (" + str(row) + "/" + str(len(userTab)) + ")...")
    
        # get all shapefiles that fit that name
        allshp = []
        for f in range(0,len(allSHP_base)):
            if allSHP_base[f] == thisName:
                allshp.append(allSHP[f])
                
        # merge sources if more than one fitting shapefile was found
        if (len(allshp) > 1):
            
            # get target geometry
            toGeom = userTab[row][6]
            
            # sources geometries
            fromGeometries = []
            for sourceFile in allshp: 
                desc = arcpy.Describe(sourceFile)
                geom = str(desc.shapeType)
                if (geom == "Polyline"):
                    geom = "Line"
                fromGeometries.append(geom)
    
            # get index for fitting geometry
            if toGeom in fromGeometries:
                pos = fromGeometries.index(toGeom)
            else:
                pos = 0
            allbutpos = [i for i in range(0,len(allshp)) if i != pos]
                
            ### append features
            toShp = allshp[pos]
            
            # generate new name
            toShpcomb = os.path.splitext(toShp)[0] + "_combined.shp"
            
            # copy target shapefile
            if (os.path.isfile(toShpcomb) == False):
                
                arcpy.CopyFeatures_management(toShp, toShpcomb)
                toShp = toShpcomb
                
                # get target coordinate system
                coordTo = arcpy.Describe(toShp).spatialReference
                coordTo_str = coordTo.exportToString()
                
                
                for f in allbutpos:
                    fromShp = allshp[f]
                    
                    
                    # reproject data if necessary
                    coordFrom = arcpy.Describe(fromShp).spatialReference
                    coordFrom_str = coordFrom.exportToString()
                    
                    fromShpProj = os.path.splitext(fromShp)[0] + "_proj.shp"
                    
                    if (coordFrom_str[0:40] == coordTo_str[0:40]) == False:
                        
                        if (os.path.isfile(fromShpProj)):
                            arcpy.Delete_management(fromShpProj)
                        arcpy.Project_management(fromShp, fromShpProj, coordTo)
                        fromShp = fromShpProj
        
                        
                    # change geometry if necessary
                    interm = os.path.splitext(fromShp)[0] + "_interm.shp"
                    if fromGeometries[f] != fromGeometries[pos]:
                        
                        if (os.path.isfile(interm)):
                            arcpy.Delete_management(interm)
                        
                        if fromGeometries[pos] == "Point":
                            
                            # check if feature midpoints or vertices should be converted to points    
                            if userTab[row][0] in verTab:
                                arcpy.FeatureVerticesToPoints_management(fromShp, interm, "ALL")
                            else:
                                arcpy.FeatureToPoint_management(fromShp, interm)
                        
                        if fromGeometries[pos] == "Line":
                            arcpy.FeatureToLine_management(fromShp, interm)
                        
                        if fromGeometries[pos] == "Polygon":
                            arcpy.FeatureToPolygon_management(fromShp, interm)
                        
                        fromShp = interm


                    # append features
                    rScript = os.path.join(rScriptPath, "appendShapefile.r")
                    executeRScript(rScript, [fromShp, toShp, rScriptPath])

                    if (os.path.isfile(fromShpProj)):
                        arcpy.Delete_management(fromShpProj)
                    if (os.path.isfile(interm)):
                        arcpy.Delete_management(interm)
            
            
# send parameter to ArcGIS
arcpy.SetParameterAsText(2, provDat)