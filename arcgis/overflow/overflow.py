"""Compute flooded terrain areas.
Copyright (C) 2013 Stefan Harnischmacher, Thomas Nauss
 
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""
 
__author__ = "Stefan Harnischmacher, Thomas Nauss"
__version__ = "2013-12-29"
__license__ = "GNU GPL, see http://www.gnu.org/licenses/"


# Import libraries
import arcpy
import os


# Check out the extension licenses
arcpy.CheckOutExtension("Spatial")


# Clip input raster data sets to common extend
def compute_clip(input_file, output_file, clip_template):
    """Clip dataset
    
    Args:
        input_file: file to be cliped
        output_file: filename of the cliped data set
        clip_template: file from which the clipping extend is taken
    """
    print "Clipping dataset..."
    arcpy.Clip_management(input_file, "#", output_file, \
                          clip_template, "0", "ClippingGeometry")

    
def compute_extract_by_mask(input_file, output_file, mask_file):
    print "Extracting by mask..."
    extract_by_mask = arcpy.sa.ExtractByMask(input_file, mask_file)
    extract_by_mask.save(output_file)


def compute_flowdirection(input_file, output_file):
    print "Computing flow direction..."
    flow_direction = arcpy.sa.FlowDirection(input_file, "NORMAL")
    flow_direction.save(output_file)


def compute_basin(input_file, output_file):
    print "Computing basin..."
    basin = arcpy.sa.Basin(input_file)
    basin.save(output_file)


def compute_sinks(input_file, output_file):
    print "Computing sinks..."
    sinks = arcpy.sa.Sink(input_file)
    sinks.save(output_file)


def compute_flow_accumulation(input_file, output_file):
    print "Computing flow accumulation..."
    flow_accumulation = arcpy.sa.FlowAccumulation(input_file, "", \
                                                  "float")
    flow_accumulation.save(output_file)


def compute_min_pixel(input_file, output_file):
    print "Computing minimum pixel location..."
    raster_dataset = arcpy.Raster(input_file)
    min_value = round(raster_dataset.minimum, 1) + 0.05
    print min_value 
    min_pixel = arcpy.sa.ExtractByAttributes(raster_dataset, \
                    "Value <= " + str(min_value))
    min_pixel.save(output_file)
    return min_value

def convert_raster_to_point(input_file, output_file):
    print "Converting raster to points..."
    arcpy.RasterToPoint_conversion(input_file, output_file)  

def convert_raster_to_polygon(input_file, output_file):
    print "Converting raster to polygons..."
    arcpy.RasterToPolygon_conversion(input_file, output_file, \
                                         "NO_SIMPLIFY", "VALUE")  

def compute_difference(input_file_1, input_file_2, output_file):
    print "Computing difference between two files/values..."
    difference = arcpy.sa.Minus(input_file_1, input_file_2)
    difference.save(output_file)

def set_no_data(input_file, condition, output_file, false_file=False):
    print "Setting no data values..."
    if false_file == False:
        false_file = input_file
    no_data = arcpy.sa.SetNull(input_file, false_file, condition)
    no_data.save(output_file)

def reclassify_raster(input_file, map_list, output_file):
    print "Reclassifying raster..."
    map_list = arcpy.sa.RemapValue(map_list)
    reclassify = arcpy.sa.Reclassify(input_file, "VALUE", \
                                          map_list, "NODATA")
    reclassify.save(output_file)

def select_by_location(input_file_1, input_file_2, overlap, output_file=False):
    print "Selecting by location..."
    arcpy.MakeFeatureLayer_management(input_file_1, "tmp") 
    arcpy.SelectLayerByLocation_management("tmp", overlap, input_file_2)
    matchcount = int(arcpy.GetCount_management("tmp").getOutput(0)) 
    if output_file:
        if matchcount == 0:
            print('no features matched spatial and attribute criteria')
        else:
            arcpy.CopyFeatures_management("tmp", output_file)
            print('{0} cities that matched criterias written to {1}'. \
                  format(matchcount, output_file))
    else:
        if matchcount == 0:
            return False
        else:
            return True


def main():
    """Main routine
    
    The script assumes that all initial data sets are stored in the
    personal geodatabase. If this is not the case, the workspace 
    environment has to be set appropriately prior to reading the data
    sets.
    """

    print
    print 'Module: schalke'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print  
    
    # Define environment variables
    pgdb_filepath = "C:/Users/Dogbert/Desktop/schalke/arcgis/schalke.mdb/"
    arcpy.env.workspace = pgdb_filepath
    arcpy.env.overwriteOutput = True

    # Define i/o variables
    dgm_filepath = pgdb_filepath + "dgm1_schal"
    dom_filepath = pgdb_filepath + "dom1_schal"
    ezgb_pumpen_filepath = pgdb_filepath + "ezgb_pumpen_clip"
    flow_direction_filepath = pgdb_filepath + "dgm_flowdirection"
    basin_filepath = pgdb_filepath + "dgm_basin"
    sinks_filepath = pgdb_filepath + "dgm_sinks"
    flow_accumulation_filepath = pgdb_filepath + "dgm_flowaccumulation"
    min_area_filepath = pgdb_filepath + "dgm_min_area"
    dgm_filepath_ezgb = dgm_filepath + "_ezgb"
    min_filepath = pgdb_filepath + "dgm_min"
    min_points_filepath = min_filepath + "_points"
    difference_filepath = pgdb_filepath + "dgm_flood"
    difference_nd_filepath = difference_filepath + "_nd"
    difference_nd_one_filepath = difference_nd_filepath + "_one"
    difference_poly_filepath = pgdb_filepath + "dgm_flood_poly"
    difference_main_poly_filepath = pgdb_filepath + "dgm_flood_poly_main"
    emscher = pgdb_filepath + "emscher"
    
    # Compute water levels
    # compute_clip(dgm_filepath, dgm_filepath + "_clip", dom_filepath)
    dgm_filepath = dgm_filepath + "_clip"
    # compute_flowdirection(dgm_filepath, flow_direction_filepath)
    # compute_basin(flow_direction_filepath, basin_filepath)
    # compute_sinks(flow_direction_filepath, sinks_filepath)
    # compute_flow_accumulation(flow_direction_filepath, flow_accumulation_filepath)
    
    
    # Extract dgm areas for individual catchments
    shapeName = arcpy.Describe(ezgb_pumpen_filepath).shapeFieldName
    inrows = arcpy.SearchCursor(ezgb_pumpen_filepath)
    catchment = 0
    for row in inrows:
        catchment = catchment + 1
        print "Computing catchment ", catchment
        catchment_string = "_" + str(catchment).zfill(2)
        feature = row.shape
        act_dgm_filepath_ezgb = dgm_filepath_ezgb + catchment_string
        compute_extract_by_mask(dgm_filepath, act_dgm_filepath_ezgb, feature)
    
        level = compute_min_pixel(act_dgm_filepath_ezgb, min_filepath)
        convert_raster_to_point(min_filepath, min_points_filepath)
    
        reached_channel = False
    
        while reached_channel == False:
            level = level + 10
            print "Computing flood plane for water level: ", level
        
            compute_difference(level, dgm_filepath, difference_filepath)
        
            set_no_data(difference_filepath, "Value < 0", difference_nd_filepath)
        
            reclassify_raster(difference_nd_filepath, [[0,9999999,1]], difference_nd_one_filepath)
        
            convert_raster_to_polygon(difference_nd_one_filepath, difference_poly_filepath)
        
            overlap = "contains"
            select_by_location(difference_poly_filepath, min_points_filepath, overlap, difference_main_poly_filepath)

            act_difference_nd_filepath = difference_nd_filepath + catchment_string + "_" + str(int(level))
            print act_difference_nd_filepath
            compute_extract_by_mask(difference_nd_filepath, act_difference_nd_filepath, difference_main_poly_filepath)

            overlap = "intersect"
            reached_channel = select_by_location(emscher, difference_main_poly_filepath, overlap)
        
        print "Channel has been reached? ", reached_channel
    print "...finished"

if __name__ == '__main__':
  main()


"""
    datasets = arcpy.ListDatasets("*", "Raster")
    for dataset in datasets:
        print dataset
"""
