# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: aggregatePlanningEntitiesToAnalysisGrid.py
# --------------------------------------------------------------------


import arcpy
import os
import subprocess
import sys
import csv
import fnmatch


modelFolder = arcpy.GetParameterAsText(0)
meanFields = arcpy.GetParameterAsText(1)
sumFields = arcpy.GetParameterAsText(2)
noDataValue = arcpy.GetParameterAsText(3)
analGrid = arcpy.GetParameterAsText(4)
outShpName = arcpy.GetParameterAsText(5)
studyAreaInDataModel = arcpy.GetParameterAsText(6)

# get file path of this python module
pyScript = sys.argv[0]

# prepare field names
meanFieldsList = meanFields.split(";")
sumFieldsList = sumFields.split(";")
meanFieldsListShort = []
for thisShorter in range(0, len(meanFieldsList)):
    if len(meanFieldsList[thisShorter]) > 8:
        meanFieldsListShort.append(meanFieldsList[thisShorter][0:8])
    else:
        meanFieldsListShort.append(meanFieldsList[thisShorter])
sumFieldsListShort = []
for thisShorter in range(0, len(sumFieldsList)):
    if len(sumFieldsList[thisShorter]) > 8:
        sumFieldsListShort.append(sumFieldsList[thisShorter][0:8])
    else:
        sumFieldsListShort.append(sumFieldsList[thisShorter])


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
if (os.path.isfile(os.path.join(modelFolder, "highestResAttributes.csv")) == False):
    rScript = os.path.join(rScriptPath, "getPlanningEntitiesWithHighestResolution.r")
    executeRScript(rScript, [modelFolder, meanFields, sumFields, noDataValue, rScriptPath])



# open table with information on which shapefile holds information with highest resolution
userTab = []
with open(os.path.join(modelFolder, "highestResAttributes.csv"), 'r') as csvfile:
    csvObj = csv.reader(csvfile, delimiter=';')
    for row in csvObj:
        userTab.append(row)


# concatenate all fields
allFields = meanFields + ";" + sumFields
if allFields[len(allFields)-1] == ";":
    allFields = allFields[0:len(allFields)-2]

# define variables
attGrid = modelFolder + "/AnalysenErgebnisse/additionalAttributes_intermediate2.shp"
attGridInt2 = modelFolder + "/AnalysenErgebnisse/additionalAttributes_intermediate3.shp"
attGridInt3 = modelFolder + "/AnalysenErgebnisse/additionalAttributes_intermediate4.shp"



# aggregate each planning entity with highest available resolution and informational content
for thisPlanEnt in range(1, len(userTab)):

    arcpy.AddMessage("Aggregating data from " + userTab[thisPlanEnt][0] + " to analysis grid...(" + str(thisPlanEnt) + "/" + str(len(userTab)-1) + ")")

    fromShp = userTab[thisPlanEnt][0]
    fields = userTab[thisPlanEnt][1]
    fromGeometry = userTab[thisPlanEnt][2]
    outShp = os.path.dirname(analGrid) + "\\" + os.path.basename(fromShp).split(".")[0] + "_intermediate" + str(thisPlanEnt) + ".shp"

    # make list from input
    fieldsOrig = fields
    fields = fields.split(";")

    # find and copy analysis grid
    if arcpy.Exists(attGrid):
        arcpy.Delete_management(attGrid)
    arcpy.Copy_management(analGrid, attGrid)
    if arcpy.Exists(outShp):
        arcpy.Delete_management(outShp)
    arcpy.Copy_management(analGrid, outShp)


    if fromGeometry != "Point":


        # copy origin data
        fromShp_int = os.path.dirname(fromShp) + "/" + os.path.basename(fromShp).split(".")[0] + "_intermediate.shp"
        if arcpy.Exists(fromShp_int):
            arcpy.Delete_management(fromShp_int)
        arcpy.Copy_management(fromShp, fromShp_int)
        fromShp = fromShp_int



        # add field for area sizes to analysis grid and from shapefile if it does not exist already
        if fromGeometry == "Polygon":
            areaField = "AreaSize"
        if fromGeometry == "Line":
            areaField = "LineLength"
        gridFields = arcpy.ListFields(attGrid)
        fromFields = arcpy.ListFields(fromShp)
        namesGrid = []
        namesFrom = []
        for i in range(0, len(gridFields)):
            namesGrid.append(gridFields[i].name)
        for i in range(0, len(fromFields)):
            namesFrom.append(fromFields[i].name)

        if (areaField not in namesGrid):
            arcpy.AddField_management(attGrid, areaField, "Double")
            arcpy.CalculateField_management(attGrid, areaField, "!shape.area@squaremeters!", "PYTHON")
        if (areaField not in namesFrom):
            arcpy.AddField_management(fromShp, areaField + "Fr", "Double")
            if fromGeometry == "Polygon":
                arcpy.CalculateField_management(fromShp, areaField + "Fr", "!shape.area@squaremeters!", "PYTHON")
            if fromGeometry == "Line":
                arcpy.CalculateField_management(fromShp, areaField + "Fr", "!shape.length@meters!", "PYTHON")



        # execute R-Script for calculating from shapefile densities
        allFields_use = userTab[thisPlanEnt][1]
        allFields_use_list = allFields_use.split(";")
        meanFields_use_temp = meanFields.split(";")
        meanFields_use = list(set(meanFields_use_temp).intersection(allFields_use_list))
        sumFields_use_temp = sumFields.split(";")
        sumFields_use = list(set(sumFields_use_temp).intersection(allFields_use_list))

        rScript = os.path.join(rScriptPath, "calculateDensitiesInPolygon.r")
        executeRScript(rScript, [fromShp, allFields_use, areaField + "Fr", "d", rScriptPath, str(meanFields_use), str(sumFields_use), noDataValue])



        # combine source and analysis grid Data
        combInt = os.path.dirname(analGrid) + "\\combined_intermediate.shp"
        if arcpy.Exists(combInt):
            arcpy.Delete_management(combInt)
        if fromGeometry == "Polygon":
            arcpy.Union_analysis([fromShp, attGrid], combInt, "ALL", "", "NO_GAPS")
        if fromGeometry == "Line":
            arcpy.Intersect_analysis([fromShp, attGrid], combInt, "All", "", "LINE")


        # add area size field for intersecting areas
        combFields = arcpy.ListFields(combInt)
        addToCombInt = True
        for thiscombField in combFields:
            if thiscombField.name == "intArea":
                addToCombInt = False
        if addToCombInt:
            arcpy.AddField_management(combInt, "intArea", "Double")
        if fromGeometry == "Polygon":
            arcpy.CalculateField_management(combInt, "intArea", "!shape.area@squaremeters!", "PYTHON")
        if fromGeometry == "Line":
            arcpy.CalculateField_management(combInt, "intArea", "!shape.length@meters!", "PYTHON")

        # calculate total area of original features per grid cell
        rScript = os.path.join(rScriptPath, "calculateFeaturesAreaPerGridCell.r")
        executeRScript(rScript, [combInt, allFields_use, str(meanFields_use), str(sumFields_use), noDataValue, rScriptPath])



        # get all density fields
        combFields = arcpy.ListFields(combInt)
        denFields = []
        newFields = []
        allOrigFields = []
        for i in range(0, len(combFields)):
            thisName = combFields[i].name
            allOrigFields.append(thisName)
            if thisName[0:2] == "d_":
                denFields.append(thisName)
                newFields.append("n_" + thisName[2:])
        denOne = ";".join(denFields)


        # calculate new absolute numbers
        for i in range(0, len(denFields)):
            if (newFields[i] in allOrigFields) == False:
                arcpy.AddField_management(combInt, newFields[i], "Double")
            if fromGeometry == "Polygon":
                if newFields[i][2:len(newFields[i])] in meanFieldsListShort:
                    rScript = os.path.join(rScriptPath, "calculateMeansOfFeaturesPerGridCell.r")
                    executeRScript(rScript, [combInt, str(denFields[i]), "totFeatA", str(newFields[i]), "intArea", areaField, noDataValue, rScriptPath])
                if newFields[i][2:len(newFields[i])] in sumFieldsListShort:
                    rScript = os.path.join(rScriptPath, "calculateSumsOfFeaturesPerGridCell.r")
                    executeRScript(rScript, [combInt, areaField + "Fr", areaField, "intArea", denFields[i], newFields[i], noDataValue, rScriptPath])
                    # expres = "!" + denFields[i] + "! * !intArea!"
                    # arcpy.CalculateField_management(combInt, newFields[i], expres, "PYTHON")
            if fromGeometry == "Line":
                if newFields[i][2:len(newFields[i])] in meanFieldsListShort:
                    rScript = os.path.join(rScriptPath, "calculateMeansOfFeaturesPerGridCell_line.r")
                    executeRScript(rScript, [combInt, str(denFields[i]), "totFeatA", str(newFields[i]), "intArea", areaField, noDataValue, rScriptPath])
                if newFields[i][2:len(newFields[i])] in sumFieldsListShort:
                    rScript = os.path.join(rScriptPath, "calculateSumsOfFeaturesPerGridCell_line.r")
                    executeRScript(rScript, [combInt, areaField + "Fr", areaField, "intArea", denFields[i], newFields[i], noDataValue, rScriptPath])



        # dissolve to analysis grid
        if arcpy.Exists(attGridInt2):
            arcpy.Delete_management(attGridInt2)
        if arcpy.Exists(attGridInt2):
            attGridInt2 = attGridInt2.split(".")[0] + "9.shp"
        arcpy.Copy_management(attGrid, attGridInt2)
        rScript = os.path.join(rScriptPath, "dissolveWithNoDataValue.r")
        attributeStats = " SUM;".join(newFields) + " SUM"
        executeRScript(rScript, [combInt, attGridInt2, "grid_ID", attributeStats, noDataValue, rScriptPath])


        # rename attribute fields
        rScript = os.path.join(rScriptPath, "renameAttributeField.r")
        renameFields = []
        for i in range(0, len(newFields)):
            for j in range(0, len(fields)):
                if (newFields[i][2:10] in fields[j][0:8]):
                    renameFields.append(newFields[i])
        renameFields.sort()
        fields.sort()
        for i in range(0,len(renameFields)):
            executeRScript(rScript, [attGridInt2, renameFields[i], fields[i], rScriptPath])


        # extract fields from shapefile
        rScript = os.path.join(rScriptPath, "extractFieldsFromShapefile.r")
        keepFields = ["grid_ID"]
        keepFields.extend(fields)
        keepFieldsRInput = (";").join(keepFields)
        executeRScript(rScript, [attGridInt2, keepFieldsRInput, noDataValue, rScriptPath])


        # copy to analysis grid geometry
        rScript = os.path.join(rScriptPath, "joinMultipleAttributeTablesToOneShapefile.r")
        fromShps = [attGridInt2]
        executeRScript(rScript, [outShp, "grid_ID", str(fromShps), "grid_ID", rScriptPath, noDataValue])



        # delete intermediate data
        if os.path.isfile(attGrid):
            arcpy.Delete_management(attGrid)
        if os.path.isfile(combInt):
            arcpy.Delete_management(combInt)
        if os.path.isfile(attGridInt2):
            arcpy.Delete_management(attGridInt2)
        if os.path.isfile(fromShp):
            arcpy.Delete_management(fromShp)
        attGridInt2_dbf = os.path.dirname(attGridInt2) + "/" + os.path.basename(attGridInt2).split(".")[0] + ".dbf"
        if os.path.isfile(attGridInt2_dbf):
            arcpy.Delete_management(attGridInt2_dbf)



    if fromGeometry == "Point":

        rScript = os.path.join(rScriptPath, "aggregatePointsToPolygon.r")
        executeRScript(rScript, [fromShp, analGrid, meanFields, sumFields, outShp, rScriptPath, fieldsOrig, noDataValue])
        coordSys = arcpy.Describe(analGrid).spatialReference
        arcpy.DefineProjection_management(outShp, coordSys)

        # delete intermediate data
        if os.path.isfile(attGrid):
            arcpy.Delete_management(attGrid)
        if os.path.isfile(combInt):
            arcpy.Delete_management(combInt)
        if os.path.isfile(attGridInt2):
            arcpy.Delete_management(attGridInt2)
        attGridInt2_dbf = os.path.dirname(attGridInt2) + "/" + os.path.basename(attGridInt2).split(".")[0] + ".dbf"
        if os.path.isfile(attGridInt2_dbf):
            arcpy.Delete_management(attGridInt2_dbf)





### combine all shapefiles
outShpFinal = modelFolder + "/AnalysenErgebnisse/" + outShpName

# find all intermediate data
allshp = []
for root, dirnames, filenames in os.walk(os.path.dirname(analGrid)):
    for filename in fnmatch.filter(filenames, "*_intermediate*.shp"):
        allshp.append(os.path.join(root, filename))

# copy analyis grid
if os.path.isfile(outShpFinal):
    arcpy.Delete_management(outShpFinal)
arcpy.CopyFeatures_management(analGrid, outShpFinal)

# add data
toJoin = "grid_ID"
fromJoin = "grid_ID"
rScript = os.path.join(rScriptPath, "joinMultipleAttributeTablesToOneShapefile.r")
executeRScript(rScript, [outShpFinal, toJoin, str(allshp), fromJoin, rScriptPath])



# delete all intermediate files
for i in range(0, len(allshp)):
    thisShp = allshp[i]
    if arcpy.Exists(thisShp):
        arcpy.Delete_management(thisShp)


arcpy.SetParameterAsText(7, outShpFinal)