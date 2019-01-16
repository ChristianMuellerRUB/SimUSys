# combineFolderAndString

import arcpy


folder = arcpy.GetParameterAsText(0)
string = arcpy.GetParameterAsText(1)

out = folder + "/" + string

arcpy.SetParameterAsText(2, out)