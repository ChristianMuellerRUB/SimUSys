# -*- coding: utf-8 -*-
# --------------------------------------------------------------------
# Name: georeferenceAddressData.py
# --------------------------------------------------------------------

import arcpy
import os
import sys
import csv
import subprocess
from dbfpy import dbf


 # install geocoder
import urllib
outs = urllib.urlopen("https://bootstrap.pypa.io/ez_setup.py").read()
outPath = "C:/Python27/ArcGIS10.3/Scripts/ez_setup.py"
outFile = open(outPath, 'w')
outFile.write(outs)
outFile.close()
os.system("python " + outPath + " install")
outs = urllib.urlopen("https://bootstrap.pypa.io/get-pip.py").read()
outPath = "C:/Python27/ArcGIS10.3/Scripts/get-pip.py"
outFile = open(outPath, 'w')
outFile.write(outs)
outFile.close()
os.system("python " + outPath + " install")
os.system("pip install geocoder")
outs = urllib.urlopen("https://github.com/DenisCarriere/geocoder/archive/master.zip").read()
outPath = "C:/Python27/ArcGIS10.3/Scripts/geocoder.zip"
outFile = open(outPath, 'w')
outFile.write(outs)
outFile.close()
os.system("python " + outPath + " install")

import geocoder


# inputs from ArcGIS
inTable = arcpy.GetParameterAsText(0)
compareTargetShapefile = arcpy.GetParameterAsText(1)
geocodeMethod = arcpy.GetParameterAsText(2)
coordinateSystem = arcpy.GetParameterAsText(3)
useOSMAddressData =arcpy.GetParameterAsText(4)
pyScript = sys.argv[0]

outShp = inTable

if useOSMAddressData == "true":

    try:

        outShp = os.path.dirname(inTable) + "/georeferencedFromAddresses.shp"

        if os.path.isfile(outShp):
            # inTable = outShp
            # outShp = os.path.dirname(outShp) + "/georeferencedFromAddresses2.shp"
            arcpy.Delete_management(outShp)

        arcpy.AddMessage(inTable)

        if (inTable != "0"):

            # read table
            userTab = []
            with open(inTable, 'r') as csvfile:
                csvObj = csv.reader(csvfile, delimiter = ';', dialect = csv.excel)
                for row in csvObj:
                    userTab.append(row)




            for c in range(0, len(userTab[0])):
                if userTab[0][c] == "addressID":
                    addressIDPos = c



            # read shapefile attribute table
            targetDBF = os.path.dirname(compareTargetShapefile) + "/" + os.path.basename(compareTargetShapefile).split(".")[0] + ".dbf"
            targetAddresses = []
            db = dbf.Dbf(targetDBF)
            for r in range(0, len(db)):
                targetAddresses.append(db[r]["ADDRESSID"])
            db.close()
            
            
            
            # find missing addresses
            misAdds = [userTab[0]]
            contList = []
            misAddPos = []
            for a in range(1, len(userTab)):
                if (userTab[a][addressIDPos] in targetAddresses) == False:
                    if (userTab[a][addressIDPos] in contList) == False:
                        misAdds.append(userTab[a])
                        contList.append(userTab[a][addressIDPos])
                        misAddPos.append(a)
            userTab = misAdds
            
            
            
            
            # get position of address information
            for i in range(0, len(userTab[0])):
                if userTab[0][i] == "Strasse":
                    streetPos = i
                if userTab[0][i] == "beforeStreetNameReplacement":
                    streetPos = i
                if userTab[0][i] == "Hausnummer":
                    housePos = i
                if userTab[0][i] == "Zusatz":
                    houseAddPos = i
                if userTab[0][i] == "Stadt":
                    cityPos = i
                if userTab[0][i] == "PLZ":
                    ZIPPos = i
            
            
            # get address information
            street = []
            house = []
            houseAdd = []
            city = []
            ZIP = []
            for i in range(1, len(userTab)):
                street.append(userTab[i][streetPos])
                house.append(userTab[i][housePos])
                houseAdd.append(userTab[i][houseAddPos])
                city.append(userTab[i][cityPos])
                ZIP.append(userTab[i][ZIPPos])


            xCoords = []
            yCoords = []
            for i in range(0, len(street)-1):
            # for i in range(52, 55):
            
                try:
                    arcpy.AddMessage("Getting coordinates from external source...(" + str(i + 1) + "/" + str(len(street)) + ")")
                    if geocodeMethod == "google":
                        g = geocoder.google(street[i] + " " + house[i] + ", " + city[i])
                    if geocodeMethod == "osm":
                        g = geocoder.osm(street[i] + " " + house[i] + ", " + city[i])
                    if geocodeMethod == "geoOttawa":
                        g = geocoder.ottawa(street[i] + " " + house[i] + ", " + city[i])
                    if geocodeMethod == "yahoo":
                        g = geocoder.yahoo(street[i] + " " + house[i] + ", " + city[i])

                    xCoords.append(g.x)
                    yCoords.append(g.y)

                    
                except:
                    arcpy.AddMessage(street[i] + " " + house[i] + ", " + city[i] + " not found")



            # add coordinates to .csv-file
            with open(os.path.dirname(inTable) + '/temp_misAddPos.csv', 'wb') as csvfile:
                spamwriter = csv.writer(csvfile, delimiter = ';',
                                        quotechar = '|', quoting = csv.QUOTE_MINIMAL)
                spamwriter.writerow(misAddPos)
            with open(os.path.dirname(inTable) + '/temp_xCoords.csv', 'wb') as csvfile:
                spamwriter = csv.writer(csvfile, delimiter = ';',
                                        quotechar = '|', quoting = csv.QUOTE_MINIMAL)
                spamwriter.writerow(xCoords)
            with open(os.path.dirname(inTable) + '/temp_yCoords.csv', 'wb') as csvfile:
                spamwriter = csv.writer(csvfile, delimiter = ';',
                                        quotechar = '|', quoting = csv.QUOTE_MINIMAL)
                spamwriter.writerow(yCoords)

            thisScriptPath = os.path.dirname(pyScript)
            rScriptPath = os.path.join(os.path.abspath(os.path.join(thisScriptPath, os.pardir)), "R")
            rScript = os.path.join(rScriptPath, "addCoordinatesToAddressFile.r")
            arcpy.SetProgressor("default", "Executing R Script...")
            args = ["R", "--slave", "--vanilla", "--args", inTable, 'inFile', 'inFile', 'inFile', geocodeMethod]
            scriptSource = open(rScript, 'rb')
            rCommand = subprocess.Popen(args, stdin = scriptSource, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell = True)
            resString, errString = rCommand.communicate()
            scriptSource.close()
            if errString and "...completed execution of R script" not in resString:
                arcpy.AddMessage(errString)

            
            # add address data as xy event layer
            xyEventLayerPath = "HauskoordinatenDemo_xyLayer"
            if arcpy.Exists(xyEventLayerPath):
                arcpy.Delete_management(xyEventLayerPath)
            useTable = os.path.dirname(inTable) + "/addressDataPlusCoordinates.csv"
            coordSystem = "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]]"
            arcpy.AddMessage("Georeferencing addresses...")
            arcpy.MakeXYEventLayer_management(useTable, "xCoords", "yCoords", xyEventLayerPath, coordSystem)
            
                
            # reproject data
            addressPath = os.path.dirname(useTable) + "/georeferencedFromAddresses.shp"
            if arcpy.Exists(addressPath):
                arcpy.Delete_management(addressPath)
            arcpy.AddMessage("Reprojecting data...")
            arcpy.Project_management(xyEventLayerPath, addressPath, coordinateSystem)
                
        else:
            arcpy.AddMessage("Missing field name information for addresses.")
            
            
    except:
        arcpy.AddMessage("Unable to georeference addresses.")


# delete temporary data
if os.path.isfile(os.path.dirname(inTable) + '/temp_misAddPos.csv'):
    arcpy.Delete_management(os.path.dirname(inTable) + '/temp_misAddPos.csv')
if os.path.isfile(os.path.dirname(inTable) + '/temp_xCoords.csv'):
    arcpy.Delete_management(os.path.dirname(inTable) + '/temp_xCoords.csv')
if os.path.isfile(os.path.dirname(inTable) + '/temp_yCoords.csv'):
    arcpy.Delete_management(os.path.dirname(inTable) + '/temp_yCoords.csv')

# send parameter to ArcGIS
arcpy.SetParameterAsText(5, outShp)
