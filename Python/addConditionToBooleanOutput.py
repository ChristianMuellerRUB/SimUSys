# --------------------------------------------------------------------
# Name: addConditionToBoleanOutput.py
# overwrites a boolean output according to another condition
# --------------------------------------------------------------------

import arcpy

orig_condition = arcpy.GetParameterAsText(0)
master_condition = arcpy.GetParameterAsText(1)

if master_condition == "false":
    orig_condition = "false"

arcpy.SetParameterAsText(2, orig_condition)