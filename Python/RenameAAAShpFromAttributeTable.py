# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: renameAAAShpFromAttributeTable.py
# Renames AAA-shapefiles according to information in the attribute table in order to achieve standard naming
# --------------------------------------------------------------------

import arcpy
import os
import sys
import shutil
import fnmatch
import csv

provDat = arcpy.GetParameterAsText(0)
overwriteExisting = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]


# Get table path
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
renF = []
with open(os.path.join(rScriptPath, "renameAAAData.csv"), 'r') as csvfile:
    csvObj = csv.reader(csvfile, delimiter=';')
    for row in csvObj:
        renF.append(row)


# get AAA-data folders
aaaFolders = []
if os.path.isdir(provDat + "\\ALKIS"):
    aaaFolders.append(provDat + "\\ALKIS")
if os.path.isdir(provDat + "\\ATKIS"):
    aaaFolders.append(provDat + "\\ATKIS")

for aaaFolder in aaaFolders:
    
    # get all files in directory and check if names abide by the standard naming
    allShp = []
    isStandardNaming = False
    for root, dirnames, filenames in os.walk(aaaFolder):
        for filename in fnmatch.filter(filenames, "*.shp"):
            allShp.append(os.path.join(root, filename))
            if (fnmatch.fnmatch(os.path.join(root, filename), "*\\AX_*")):
                isStandardNaming = True
        
    if isStandardNaming == False:
    
        # create a safety copy to work on
        newFolder = aaaFolder + "_rename"
        
        if ((os.path.isdir(newFolder) == False) or (overwriteExisting == "true")):
            
            if os.path.isdir(newFolder):
                shutil.rmtree(newFolder)
            
            # create new folder    
            os.makedirs(newFolder)
            
            
            # iterate over each shapefile
            for s in range(0,len(allShp)):
                thisShp = allShp[s]
                
                arcpy.AddMessage("Renaming AAA-file " + thisShp + " (" + str(s) + "/" + str(len(allShp)) + ")")
                
                # get field names
                fields = arcpy.ListFields(thisShp)
                
                # get field name which fit
                for thisField in fields:
                    for thisName in renF:
                        if thisField.name == thisName[0]:
                            useField = thisField
                            useName = thisName[0]
                            fieldType = useField.type
                
                
                            # get unique field values            
                            values = [row[0] for row in arcpy.da.SearchCursor(thisShp,(useName))]
                            uniqueValues = list(set(values))
                            
                            # extract features and write to new shapefile
                            for uf in range(0, len(uniqueValues)):
                                thisFeat = uniqueValues[uf]
                                
                                # set destination file and intermediate file paths
                                toPath = newFolder + "\\" + thisFeat + ".shp"
                                interm = newFolder + "\\intermediate.shp"
                                
                                if fieldType == "String":
                                    selectStatement = '"' + useName + '" = ' + "'" + str(thisFeat) + "'"
                                else:
                                    selectStatement = '"' + useName + '" = ' + str(thisFeat)
                                    
                                if os.path.isfile(toPath):
                                    if (os.path.isfile(interm)):
                                        arcpy.Delete_management(interm)
                                    arcpy.Select_analysis(thisShp, interm, selectStatement)
                                    arcpy.Append_management(interm, toPath, "NO_TEST")
                                else:
                                    arcpy.Select_analysis(thisShp, toPath, selectStatement)
                                    

                                # delete intermediate files
                                if (os.path.isfile(interm)):
                                    arcpy.Delete_management(interm)
            
 
# send parameter to ArcGIS
arcpy.SetParameterAsText(2, provDat)

