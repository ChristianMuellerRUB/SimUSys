# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: ExtractGeodatabases.py
# Extracts all geodatabases in the user data directory to shapefiles
# --------------------------------------------------------------------

import arcpy
import sys

# user input
provDat = arcpy.GetParameterAsText(0)
overwrite = arcpy.GetParameterAsText(1)
pyScript = sys.argv[0]


# get all geodatabases 
allgdb = []
for root, dirnames, filenames in os.walk(provDat):
    for filename in fnmatch.filter(dirnames, '*.gdb'):
        allgdb.append(os.path.join(root, filename))
         
 
# iterate over each geodatabase
for gdb in range(0,len(allgdb)):
     
    thisgdb = allgdb[gdb]
    outFolder = os.path.dirname(thisgdb) + "\\" + os.path.splitext(os.path.basename(thisgdb))[0]
     
    # create output folder
    if (not os.path.exists(outFolder) or (overwrite == "true")):
         
        if os.path.exists(outFolder):
            shutil.rmtree(outFolder)
     
         
        arcpy.AddMessage("Converting geodatabase " + thisgdb + " to shapefiles.")
         
        os.makedirs(outFolder)
     
        # get all features in geodatabase
        arcpy.env.workspace = thisgdb
        feats = []
        for feat in arcpy.ListDatasets('','feature') + ['']:
            for featcl in arcpy.ListFeatureClasses('','',feat):
                feats.append(os.path.join(feat, featcl))
     
         
        # if the data source is OSM it get complicated...
        if os.path.basename(thisgdb) == "OSMData.gdb":
             
             
            # only extract osm-points, -lines and -polygons
            temp = []
            for q in range(0, len(feats)):
                if feats[q][(len(feats[q]) - 6):len(feats[q])] in ["osm_pt", "osm_ln", "sm_ply"]:
                    temp.append(feats[q])
            feats = temp
                     
                 
             
            # list all field names
            allFields = arcpy.ListFields(feats[0])
            allExistingFieldNames = []
            for a in range(0, len(allFields)):
                allExistingFieldNames.append(allFields[a].name)
             
            # read in OSM attribute field table
            thisScriptPath = os.path.dirname(pyScript)
            rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
            OsmTab = []
            with open(os.path.join(rScriptPath, "OSMAttributeFields.csv"), 'r') as csvfile:
                csvObj = csv.reader(csvfile, delimiter=';')
                for row in csvObj:
                    OsmTab.append(row)
                          
            # loop over each field
            keepFields = []
            for t in range(0, len(OsmTab)):
                 
                # if field should not be kept (as specified in csv) and is present in attribute table
                if OsmTab[t][1] == "keep":
                     
                    # check if this field really exists in gdb
                    if OsmTab[t][0] in allExistingFieldNames:
                        keepFields.append(OsmTab[t][0])
                 
             
            # shorten field names for storage in shapefiles
            keepFieldsShort = []
            for a in range(0, len(keepFields)):
                keepFieldsShort.append(keepFields[a][0:10])
                 
                 
            # create fieldmappig object
            fieldmappings = arcpy.FieldMappings()
                     
            # loop over each field and create field mapping
            arcpy.AddMessage("Creating field mapping...")
            for m in range(0, len(keepFields)):
                 
                # define the first field which should be transfered (fromField) to the new field (inField)
                tofieldName = keepFieldsShort[m]
                fromfieldName = keepFields[m]
                                
                # create field map (input fields/toFields)
                fieldmap = arcpy.FieldMap()
                     
                # add a source data field (fromField)
                fieldmap.addInputField(feats[0], fromfieldName)
                     
                # add output field name (name of the field map/toField name)
                newField = fieldmap.outputField
                newField.name = tofieldName
                fieldmap.outputField = newField
                     
                # add field map to field mappings object
                fieldmappings.addFieldMap(fieldmap)
             
            # looping over each geodatabase feature
            for f in feats:
                 
                arcpy.AddMessage("Converting " + f + " to shapefile...")
                 
                  
                    # write all field names to file
                    all_fields = []
                    all_types = []
                    fields = arcpy.ListFields(f)
                    for field in fields:
                        all_fields.append(field.name)
                        all_types.append(field.type)
                    thisScriptPath = os.path.dirname(pyScript)
                    rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
                    with open(os.path.join(rScriptPath, "OSMAttributeFields.csv"), 'wb') as csvfile:
                        csvfile.writelines("\n".join(all_fields))
           
         
                # create new shapefile
                outShp = os.path.basename(f) + ".shp"
                outShpPath = outFolder + "\\" + outShp
                if os.path.basename(f) == "OSMData_osm_pt":
                    geom = "POINT"
                if os.path.basename(f) == "OSMData_osm_ln":
                    geom = "POLYLINE"
                if os.path.basename(f) == "OSMData_osm_ply":
                    geom = "POLYGON"
                coordFrom = arcpy.Describe(f).spatialReference
                      
                arcpy.CreateFeatureclass_management(outFolder, outShp, geom, "", "", "", coordFrom)
                  
                # add fields to emmpty shapefile
                arcpy.AddField_management (outShpPath, keepFieldsShort[a], thisType, "", "", 50)
                
                tags = ["highway", "building", "natural", "waterway", "amenity", "landuse", "place", "railway", "boundary", "power", "leisure", "man_made", "shop", "tourism", "route", "historic", "aeroway", "aerialway", "barrier", "military", "geological"]
                 
                # loop over each tag
                for tag in tags:
                     
                    outShp = os.path.basename(f) + "_" + tag + ".shp"
                     
                    # extract features for which the respective tag is not empty
                    arcpy.Select_analysis(f, "intermediate", tag + " <> ''")
                     
                 
                    # copy feature class in geodatabase to shapefile
                    arcpy.FeatureClassToFeatureClass_conversion("intermediate", outFolder, outShp, "", fieldmappings)
                     
                    # clean up intermediate data
                    arcpy.Delete_management("intermediate") 
                 
                
        # otherwise, just convert geodatabase into shapefiles
        else:
            try:
                arcpy.FeatureClassToShapefile_conversion(feats, outFolder)
            except:
                arcpy.AddMessage("Could not convert geodatabase " + thisgdb + " to shapefiles.")
 
# send parameter to ArcGIS
arcpy.SetParameterAsText(2, provDat)
