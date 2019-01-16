# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: findHouseCoordinatesAndAddressFile.py
# Finds datasets describing house coordinates and addresses
# --------------------------------------------------------------------


import arcpy
import os
import fnmatch


# inputs from ArcGIS
userDataPath = arcpy.GetParameterAsText(0)
lookForAddressFile = arcpy.GetParameterAsText(1)
lookForCoordinatesFile = arcpy.GetParameterAsText(2)

addressPath = ""
coordinatesPath = ""

try:

    # look for datasets
    def findDatasets(searchPath, lookFor):
        allDatasets = []
        for root, dirnames, filenames in os.walk(searchPath):
            for filename in fnmatch.filter(filenames, lookFor):
                allDatasets.append(os.path.join(root, filename))
        # if isinstance(allDatasets, basestring):
        #     allDatasets = allDatasets[0]
        if len(allDatasets) > 0:
            allDatasets = allDatasets[0]
        if len(allDatasets) > 0:
            allDatasets = allDatasets.replace("\\", "/")
        return allDatasets


    addressPath = findDatasets(userDataPath, lookForAddressFile)
    coordinatesPath = findDatasets(userDataPath, lookForCoordinatesFile)

except:
    print ("could not find files")

arcpy.SetParameterAsText(3, addressPath)
arcpy.SetParameterAsText(4, coordinatesPath)
arcpy.SetParameterAsText(5, userDataPath)