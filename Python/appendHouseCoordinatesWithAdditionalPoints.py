# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: appendHouseCoordinatesWithAdditionalPoints.py
# Appends additional point features to address coordiante data
# --------------------------------------------------------------------


import arcpy
import os
import sys
import subprocess
from dbfpy import dbf



# inputs from ArcGIS
addressShp = arcpy.GetParameterAsText(0)
sourceShp = arcpy.GetParameterAsText(1)
useOSMAddressData = arcpy.GetParameterAsText(2)
pyScript = sys.argv[0]

# define intermediate data path
interm = os.path.dirname(sourceShp) + "/" + "intermediate.shp"


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

        
# remove NA values from attribute table
thisScriptPath = os.path.dirname(pyScript)
rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
rScript = os.path.join(rScriptPath, "removeNAFromAttributeTable.r")
executeRScript(rScript, [sourceShp, rScriptPath])


# change no house number to zero
rScript = os.path.join(rScriptPath, "changeValueInAttributeTable.r")
executeRScript(rScript, [sourceShp, "Hausnummer", "empty", "0", rScriptPath])


# change no zip code to zero
executeRScript(rScript, [sourceShp, "PLZ", "empty", "0", rScriptPath])


thisScriptPath = os.path.dirname(pyScript)

if useOSMAddressData == "true":

    try:
        
        # define select statement function
        def buildSelectStatement(selectTable, fieldName, fitValue):
            fields = arcpy.ListFields(selectTable)
            for thisField in fields:
                if thisField.name == fieldName:
                    useField = thisField
                    fieldType = useField.type
            if fieldType == "String":
                selectStatement = '"' + fieldName + '" = ' + "'" + str(fitValue) + "'"
            else:
                selectStatement = '"' + fieldName + '" = ' + str(fitValue)
            return selectStatement
        
        
        # define field mappings
        def createFieldMappings(targetFields, fromTable, sourceFields):
            fieldmappings = arcpy.FieldMappings()
            for i in range(0, len(targetFields)):
                tofieldName = targetFields[i]
                fromfieldName = sourceFields[i]
                fieldmap = arcpy.FieldMap()
                fieldmap.addInputField(fromTable, fromfieldName)
                newField = fieldmap.outputField
                newField.name = tofieldName
                fieldmap.outputField = newField
                newField = fieldmap.outputField
                newField.length = 92
                fieldmap.outputField = newField
                fieldmappings.addFieldMap(fieldmap)
            return fieldmappings
                        
            
            
            
        # get missing addresses
        targetDBF = os.path.dirname(addressShp) + "/" + os.path.basename(addressShp).split(".")[0] + ".dbf"
        targetAddresses = []
        db = dbf.Dbf(targetDBF)
        for r in range(0, len(db)):
            targetAddresses.append(db[r]["addressID"])
        db.close()
        
        sourceDBF = os.path.dirname(sourceShp) + "/" + os.path.basename(sourceShp).split(".")[0] + ".dbf"
        sourceAddresses = []
        db = dbf.Dbf(sourceDBF)
        
        for r in range(0, len(db)):
            sourceAddresses.append(db[r]["addressID"])
        db.close()


        missingAdds = []
        for a in range(0, len(sourceAddresses)):
            if (sourceAddresses[a] in targetAddresses) == False:
                missingAdds.append(sourceAddresses[a])
        
        
        # get field names
        f = arcpy.ListFields(addressShp)
        fExists = False
        for r in range(0, len(f)):
            if f[r].name == "geoSource":
                fExists = True
                
        # add georeference source field
        if fExists == False:
            arcpy.AddField_management(addressShp, "geoSource", "TEXT")
            calcState = os.path.basename(addressShp).split(".")[0]
            arcpy.CalculateField_management(addressShp, "geoSource", '"' + calcState + '"')
                
        
        for s in range(0, len(missingAdds)):
            
            try:
                thisAdd = missingAdds[s]
                if isinstance(thisAdd, basestring) == False:
                    thisAdd = thisAdd[0]
                
                selectStatement = buildSelectStatement(sourceShp, "addressID", thisAdd)
                if arcpy.Exists(interm):
                    arcpy.Delete_management(interm)
                arcpy.Select_analysis(sourceShp, interm, selectStatement)
                
            
                # define field names
                targetFields = ["Strasse", "Hausnummer", "Zusatz", "Stadt", "PLZ", "addressID", "geoSource"]
                sourceFields = ["Strasse", "Hausnummer", "Zusatz", "Stadt", "PLZ", "addressID", "geoSource"]
                
                # build field mappings
                useFieldmappings = createFieldMappings(targetFields, interm, sourceFields)
                
                # append point coordinates
                arcpy.Append_management(interm, addressShp, "NO_TEST", useFieldmappings)
                        
        
                if arcpy.Exists(interm):
                    arcpy.Delete_management(interm)                
            
            except:
                print ("Unable to add " + str(thisAdd))
            
    except:
        arcpy.AddMessage("Unable to append additional points to house address data.")            
    
    
# delete intermediate data
if arcpy.Exists(interm):
    arcpy.Delete_management(interm)

# send parameter to ArcGIS
arcpy.SetParameterAsText(3, addressShp)
