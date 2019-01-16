# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: findHouseCoordinatesAndPopulationData.py
# Finds datasets describing house coordinates, addresses and demographic population data
# --------------------------------------------------------------------


import arcpy
import os
import sys
import xlrd
import fnmatch
from arcpy import env


# inputs from ArcGIS
userDataPath = arcpy.GetParameterAsText(0)
coordSystem = arcpy.GetParameterAsText(1)
studyAreaPath = arcpy.GetParameterAsText(2)
overwriteExisting = arcpy.GetParameterAsText(3)
pyScript = sys.argv[0]

coordinatesPath = "0"
addressPath = "0"
geometriesPath = "0"
populationDataPath = "0"
xFieldName = "0"
yFieldName = "0"
streetFieldName = "0"
houseNumberFieldName = "0"
houseNumberAdditionFieldName = "0"
cityFieldName = "0"
ZIPCodeFieldName = "0"
popStreetFieldName = "0"
popHouseNumberFieldName = "0"
popHouseAddNumberFieldName = "0"
popCityFieldName = "0"
popZIPFieldName = "0"
birthYearFieldName = "0"
genderFieldName = "0"
migrationFieldNames = "0"
maritalStatusFieldName = "0"

try:

    # get file path for R-script
    thisScriptPath = os.path.dirname(pyScript)
    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
    
    # read standard data path table
    xl_workbook = xlrd.open_workbook(os.path.join(rScriptPath, "HouseCoordinatesAdressesPopulationData.xlsx"))
    sheet_names = xl_workbook.sheet_names()
    xl_sheet = xl_workbook.sheet_by_name(sheet_names[0])
    userTab = []
    for col_idx in range(0, xl_sheet.ncols):    
        thisCol = []
        for row_idx in range(0, xl_sheet.nrows):  
            cell_obj = xl_sheet.cell(row_idx, col_idx)
            thisCol.append(str(cell_obj)[7:(len(str(cell_obj)) - 1)])
        userTab.append(thisCol)
    
    
    # look for datasets
    def findDatasets(searchPath, lookFor):
        allDatasets = []
        for root, dirnames, filenames in os.walk(searchPath):
            for filename in fnmatch.filter(filenames, lookFor):
                allDatasets.append(os.path.join(root, filename))
        if isinstance(allDatasets, basestring):
            allDatasets = allDatasets[0]
        if len(allDatasets) > 0:
            allDatasets = allDatasets[0]
        if len(allDatasets) > 0:
            allDatasets = allDatasets.replace("\\", "/")
        return allDatasets
    
    coordinatesPath = findDatasets(userDataPath, userTab[0][1])
    addressPath = findDatasets(userDataPath, userTab[3][1])
    geometriesPath = findDatasets(userDataPath, userTab[9][1])
    populationDataPath = findDatasets(userDataPath, userTab[10][1]) 
    
    
    # get field names from indices
    def getFieldNameFromIndex(inFieldIndex):
        outFieldName = inFieldIndex
        outFieldName = outFieldName[0:(len(outFieldName) - 1)]
        outFieldName = "Field" + outFieldName
        return outFieldName
    xFieldName = getFieldNameFromIndex(userTab[1][1])
    yFieldName = getFieldNameFromIndex(userTab[2][1])
    streetFieldName = getFieldNameFromIndex(userTab[4][1])
    houseNumberFieldName = getFieldNameFromIndex(userTab[5][1])
    houseNumberAdditionFieldName = getFieldNameFromIndex(userTab[6][1])
    cityFieldName = getFieldNameFromIndex(userTab[7][1])
    ZIPCodeFieldName = getFieldNameFromIndex(userTab[8][1])
    
    
    
    if addressPath != []:
        
        # create error if target shapefile already exists
        if arcpy.Exists(os.path.dirname(addressPath) + "/Hauskoordinaten.shp") and (overwriteExisting == "false"):
            print (overwriteExisting + 2)
        
        # add address data as xy event layer
        gdbBasename = os.path.dirname(addressPath)
        gdbPath = gdbBasename + "/intermediate_fGDB.gdb"
        if arcpy.Exists(gdbPath):
            arcpy.Delete_management(gdbPath)
        arcpy.CreateFileGDB_management(gdbBasename, "intermediate_fGDB.gdb")
        xyEventLayerPath = "Hauskoordinaten_xyLayer"
        if arcpy.Exists(xyEventLayerPath):
            arcpy.Delete_management(xyEventLayerPath)
        env.workspace = gdbPath
        arcpy.MakeXYEventLayer_management(addressPath, xFieldName, yFieldName, xyEventLayerPath, coordSystem)
        arcpy.FeatureClassToFeatureClass_conversion(xyEventLayerPath, gdbPath, xyEventLayerPath)
        
        # clip event layer and extract shapefile
        addressPath = os.path.dirname(addressPath) + "/Hauskoordinaten.shp"
        if arcpy.Exists(addressPath):
            if overwriteExisting == "true":
                arcpy.Delete_management(addressPath)
            else:
                addressPath = "0"
                populationDataPath = "0"
                geometriesPath = "0"
        arcpy.Clip_analysis(gdbPath + "/" + xyEventLayerPath, studyAreaPath, addressPath)
        
        # delete intermediate filegeodatabase
        if arcpy.Exists(gdbPath):
            arcpy.Delete_management(gdbPath)
         
      
    
    if populationDataPath != []:
     
        # open population data table
        xl_workbook = xlrd.open_workbook(populationDataPath)
        sheet_names = xl_workbook.sheet_names()
        xl_sheet = xl_workbook.sheet_by_name(sheet_names[0])
        popTab = []
        for col_idx in range(0, xl_sheet.ncols):    
            thisCol = []
            for row_idx in range(0, xl_sheet.nrows):  
                cell_obj = xl_sheet.cell(row_idx, col_idx)
                thisCol.append(str(cell_obj)[7:(len(str(cell_obj)) - 1)])
            popTab.append(thisCol)
                 
        # check population data field names
        migrationFieldNames = []
        for i in range(0,len(popTab)):
            if popTab[i][0] in userTab[14]:
                popStreetFieldName = popTab[i][0]
            if popTab[i][0] in userTab[15]:
                popHouseNumberFieldName = popTab[i][0]
            if popTab[i][0] in userTab[16]:
                popHouseAddNumberFieldName = popTab[i][0]
            if popTab[i][0] in userTab[17]:
                popCityFieldName = popTab[i][0]
            if popTab[i][0] in userTab[18]:
                popZIPFieldName = popTab[i][0]
            if popTab[i][0] in userTab[11]:
                birthYearFieldName = popTab[i][0]
            if popTab[i][0] in userTab[12]:
                genderFieldName = popTab[i][0]
            if popTab[i][0] in userTab[13]:
                migrationFieldNames.append(popTab[i][0])
            if popTab[i][0] in userTab[19]:
                maritalStatusFieldName = popTab[i][0]
        
except:
    arcpy.AddMessage("Unable to find house address data.")            



# send parameter to ArcGIS
arcpy.SetParameterAsText(4, coordinatesPath)
arcpy.SetParameterAsText(5, addressPath)
arcpy.SetParameterAsText(6, geometriesPath)
arcpy.SetParameterAsText(7, populationDataPath)
arcpy.SetParameterAsText(8, xFieldName)
arcpy.SetParameterAsText(9, yFieldName)
arcpy.SetParameterAsText(10, streetFieldName)
arcpy.SetParameterAsText(11, houseNumberFieldName)
arcpy.SetParameterAsText(12, houseNumberAdditionFieldName)
arcpy.SetParameterAsText(13, cityFieldName)
arcpy.SetParameterAsText(14, ZIPCodeFieldName)
arcpy.SetParameterAsText(15, popStreetFieldName)
arcpy.SetParameterAsText(16, popHouseNumberFieldName)
arcpy.SetParameterAsText(17, popHouseAddNumberFieldName)
arcpy.SetParameterAsText(18, popCityFieldName)
arcpy.SetParameterAsText(19, popZIPFieldName)
arcpy.SetParameterAsText(20, birthYearFieldName)
arcpy.SetParameterAsText(21, genderFieldName)
arcpy.SetParameterAsText(22, migrationFieldNames)
arcpy.SetParameterAsText(23, maritalStatusFieldName)