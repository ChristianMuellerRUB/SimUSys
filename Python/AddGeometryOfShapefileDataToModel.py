# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: addGeometryOfShapefileDataToModel.py
# Adds specified geometry of shapefile data to the model
# --------------------------------------------------------------------

import arcpy
import os
import subprocess
import sys
import csv

provDat = arcpy.GetParameterAsText(0)
ModelDataFolderName = arcpy.GetParameterAsText(1)
overwriteExisting = arcpy.GetParameterAsText(2)
studyArea = arcpy.GetParameterAsText(3)
pyScript = sys.argv[0]


# set output extent
descSA = arcpy.Describe(studyArea)
arcpy.env.extent = descSA.extent


# create intermediate data path names 
interm1 = os.path.join(provDat, ModelDataFolderName, "intermediateData.shp")
interm2 = os.path.join(provDat, ModelDataFolderName, "intermediateData2.shp")
interm3 = os.path.join(provDat, ModelDataFolderName, "intermediateData3.shp")
interm4 = os.path.join(provDat, ModelDataFolderName, "intermediateData4.shp")
    

# define model data directory
modDataDirPath = provDat + "/" + ModelDataFolderName


# Get table path
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")

# open data source library table
userTab = []
with open(os.path.join(modDataDirPath, "use_spatialImport.csv"), 'r') as csvfile:
    csvObj = csv.reader(csvfile, delimiter=';')
    for row in csvObj:
        userTab.append(row)
        
# read table for information on which polygon-to-point and polyline-to-point conversions should be executed from vertices to points rather than from midpoints to points 
verTab = []
with open(os.path.join(rScriptPath, "verticesToPoints.csv"), 'r') as csvfile:
    verTab = csvfile.read()
        

# read or create process file
processFile = os.path.join(modDataDirPath, "proccessedInputData.csv")
if (os.path.isfile(processFile) == False):
    open(processFile, 'a').close()
    with open(processFile, 'wb') as csvfile:
        csvfile.writelines("\n")
with open(processFile, 'r') as csvfile:
    processed = csvfile.readlines()    
if ((processed[0] == "\n") or (overwriteExisting == "true")):
    processed = []
    
# read or create error report file
errorReportFile = os.path.join(modDataDirPath, "someThingWrong.csv")
if (os.path.isfile(errorReportFile) == False):
    open(errorReportFile, 'a').close()
    with open(errorReportFile, 'wb') as csvfile:
        csvfile.writelines("\n")
with open(errorReportFile, 'r') as csvfile:
    someThingWrong = csvfile.readlines()
if len(someThingWrong) != 0:
    if ((someThingWrong[0] == "\n") or (overwriteExisting == "true")):
        someThingWrong = []


lastFile = []

# append shapefiles to data structure 
for shp in range(1,len(userTab)-1):
    
    # get shapefile paths for this iteration
    thisFrom = userTab[shp][14]
    thisTo = userTab[shp][15]


    if ((((thisFrom + "_to_" + thisTo + "\n") in processed) == False) or (overwriteExisting == "true")):
    
    
        arcpy.AddMessage("Processing file import from " + thisFrom + " to " + thisTo + " (" + str(shp) + "/" + str(len(userTab)-2) + ")")
        
        
        
        try:
            
            # check if there are features in the origin shapefile
            if int(arcpy.GetCount_management(thisFrom).getOutput(0)) > 0:
            
                # reproject data if necessary
                coordFrom = arcpy.Describe(thisFrom).spatialReference
                coordFrom_str = coordFrom.exportToString()
                
                coordTo = arcpy.Describe(thisTo).spatialReference
                coordTo_str = coordTo.exportToString()
            
                if (coordFrom_str[0:40] == coordTo_str[0:40]) == False:
                    
                    if (os.path.isfile(interm4) and (thisFrom == lastFile)):
                        thisFrom = interm4
                    elif (os.path.isfile(interm4) and (thisFrom != lastFile)):
                        arcpy.Delete_management(interm4)     
                        arcpy.Project_management(thisFrom, interm4, coordTo)
                        thisFrom = interm4
                    elif (os.path.isfile(interm4)) == False:
                        arcpy.Project_management(thisFrom, interm4, coordTo)
                        thisFrom = interm4
                
                
                # get origin shapefile description:
                desc = arcpy.Describe(thisFrom)
                fromGeometry = str(desc.shapeType)
                if (fromGeometry == "Polyline"):
                    fromGeometry = "Line"
                    
                # get geometry for this shapefile to be appended to
                geometry = userTab[shp][6]
                    
                # convert if geometry does not match
                if fromGeometry != geometry:
                    
                    # conversion might be redundant if previous iteration was on same fromFile and intermediate converted data is present
                    if (os.path.isfile(interm1)) and (userTab[shp - 1][14] == userTab[shp][14]):
                        desc = arcpy.Describe(interm1)
                        fromGeometry_interm = str(desc.shapeType)
                        
                        if fromGeometry_interm == geometry:
                            thisFrom = interm1
                            
                        else:
                            if (os.path.isfile(interm1)):
                                arcpy.Delete_management(interm1) 
                            
                            if geometry == "Point":
                                
                                # check if feature midpoints or vertices should be converted to points
                                if userTab[shp][0] in verTab:
                                    arcpy.FeatureVerticesToPoints_management(thisFrom, interm1, "ALL")
                                else:
                                    arcpy.FeatureToPoint_management(thisFrom, interm1)
                            if geometry == "Line":
                                arcpy.FeatureToLine_management(thisFrom, interm1)
                            if geometry == "Polygon":
                                arcpy.FeatureToPolygon_management(thisFrom, interm1)
                            thisFrom = interm1
                    
                    else:
                        if (os.path.isfile(interm1)):
                            arcpy.Delete_management(interm1)
                        if (os.path.isfile(interm2)):
                            arcpy.Delete_management(interm2)
                        if (os.path.isfile(interm3)):
                            arcpy.Delete_management(interm3)
                        
                        if geometry == "Point":
                            
                            # check if feature midpoints or vertices should be converted to points
                            if userTab[shp][0] in verTab:
                                arcpy.FeatureVerticesToPoints_management(thisFrom, interm1, "ALL")
                            else:
                                arcpy.FeatureToPoint_management(thisFrom, interm1)
                        
                        if geometry == "Line":
                            arcpy.FeatureToLine_management(thisFrom, interm1)
                        
                        if geometry == "Polygon":
                            arcpy.FeatureToPoint_management(thisFrom, interm3)
                            if fromGeometry == "Point":
                                arcpy.Buffer_analysis(thisFrom, interm2, 1)
                            else:
                                arcpy.FeatureToPolygon_management(thisFrom, interm2, label_features = interm3)
                    
                            # delete artifact features
                            arcpy.Select_analysis(interm2, interm1, '"' + userTab[shp][13] +  '" <> \'0\'')
                    
                        
                        thisFrom = interm1
                
                
                
                # different handling according to the question whether or not features form the input dataset need to be selected
                if userTab[shp][10] != "" and userTab[shp][11] != "":
                    if os.path.isfile(interm2):
                        arcpy.Delete_management(interm2)
                    
                    fieldName = userTab[shp][10]
                    fitValue = userTab[shp][11]
                    
                    fields = arcpy.ListFields(thisFrom)
                    for thisField in fields:
                        if thisField.name == fieldName:
                            useField = thisField
                            fieldType = useField.type
                        else:
                            print("field not found")
                    
                    if fieldType == "String":
                        selectStatement = '"' + fieldName + '" = ' + "'" + str(fitValue) + "'"
                    else:
                        selectStatement = '"' + fieldName + '" = ' + str(fitValue)
                    arcpy.Select_analysis(thisFrom, interm2, selectStatement)
                    thisFrom = interm2
                        
                    
                    
                     
                    
                    
                ### create data mapping (handler for field matching)
                    
                # define the first field which should be transfered (fromField) to the new field (inField)
                tofieldName = "OldID"
                fromfieldName = userTab[shp][13]
                    
                # create fieldmappig object
                fieldmappings = arcpy.FieldMappings()
                    
                # create field map (input fields/toFields)
                fieldmap = arcpy.FieldMap()
                    
                # add a source data field (fromField)
                fieldmap.addInputField(thisFrom, fromfieldName)
                    
                # add output field name (name of the field map/toField name)
                newField = fieldmap.outputField
                newField.name = tofieldName
                fieldmap.outputField = newField
                    
                # redefine the maximum character length of the output field (toField/fieldmap)
                newField = fieldmap.outputField
                newField.length = 92
                fieldmap.outputField = newField
                    
                # add field map to field mappings object
                fieldmappings.addFieldMap(fieldmap)
                    
                # append the geometries
                arcpy.Append_management(thisFrom, thisTo, "NO_TEST", fieldmappings)
                    
                
                
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
                    
                # add attribute table entries to target shapefile
                rScript = os.path.join(rScriptPath, "addValuesToAttributeTable.r")
                executeRScript(rScript, [modDataDirPath, thisFrom, str(shp), rScriptPath])
                
                # rename attributes
                rScript = os.path.join(rScriptPath, "renameTargetAttributesAfterImport.r")
                executeRScript(rScript, [modDataDirPath, thisFrom, str(shp), rScriptPath])
                
                
                # save file path for use of intermediate data in the next iteration
                lastFile = thisFrom
            
                
        except:
            someThingWrong.append(userTab[shp][14] + "_to_" + userTab[shp][15])
            
        processed.append(userTab[shp][14] + "_to_" + userTab[shp][15])
        
 
 
# write progress to file
processed_out = []
for thisLine in range(0,len(processed)):
    if processed[thisLine] != "\n":
        processed_out.append(processed[thisLine])
with open(os.path.join(modDataDirPath, "proccessedInputData.csv"), 'wb') as csvfile:
    csvfile.writelines("\n".join(processed_out))
    
someThingWrong_out = []
for thisLine in range(0,len(someThingWrong)):
    if someThingWrong[thisLine] != "\n":
        someThingWrong_out.append(someThingWrong[thisLine])
with open(os.path.join(modDataDirPath, "someThingWrong.csv"), 'wb') as csvfile:
    csvfile.writelines("\n".join(someThingWrong_out))        
        
 

# delete intermediate data   
if os.path.isfile(interm1):
    arcpy.Delete_management(interm1)
if os.path.isfile(interm2):
    arcpy.Delete_management(interm2)
if os.path.isfile(interm3):
    arcpy.Delete_management(interm3)
if os.path.isfile(interm4):
    arcpy.Delete_management(interm4)
    
 
# send parameter to ArcGIS
arcpy.SetParameterAsText(4, provDat)