"""Compute hydrology
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
__version__ = "2013-12-20"
__license__ = "GNU GPL, see http://www.gnu.org/licenses/"


# Import libraries
import arcpy
import os


# Check out the extension licenses
arcpy.CheckOutExtension("Spatial")


def make_filepathes(dgm_filepath):
    """Make filenames based on DGM filepath.
    It is assumed that the DOM has the same filename as the DGM except for the
    first "g" (e.g. dgm1 and dom1).
    
    Args:
        dgm_filepath: Full name and path of the dgm input file.
    
    Returns dictionary containing all filepathes.
    """
    fpd = {}
    pgdb_filepath = os.path.dirname(dgm_filepath) + "/"
    fpd["dgm"] = dgm_filepath
    fpd["dom"] = pgdb_filepath + \
        os.path.basename(dgm_filepath).replace("g", "o", 1)
    fpd["pumped_catchments"] = pgdb_filepath + "pumped_catchments_clip"
    fpd["river"] = pgdb_filepath + "river"
    fpd["dgm_ezgb"] = fpd["dgm"] + "_ezgb"
    fpd["min"] = pgdb_filepath + "dgm_min"
    fpd["min_points"] = fpd["min"] + "_points"
    fpd["diff_dgm"] = pgdb_filepath + "dgm_flood"
    fpd["diff_dgm_nd"] = fpd["diff_dgm"] + "_nd"
    fpd["diff_dgm_nd_one"] = fpd["diff_dgm_nd"] + "_one"
    fpd["diff_dgm_poly"] = pgdb_filepath + "dgm_flood_poly"
    fpd["diff_dgm_poly_main"] = pgdb_filepath + "dgm_flood_poly_main"
    fpd["diff_dom"] = pgdb_filepath + "dom_flood"
    fpd["diff_dom_nd"] = fpd["diff_dom"] + "_nd"
    fpd["flow_direction"] = pgdb_filepath + "dgm_flowdirection"
    fpd["basin"] = pgdb_filepath + "dgm_basin"
    fpd["sinks"] = pgdb_filepath + "dgm_sinks"
    fpd["flow_accumulation"] = pgdb_filepath + "dgm_flowaccumulation"
    fpd["min_area"] = pgdb_filepath + "dgm_min_area"
    return fpd


def compute_clip(input_file, output_file, clip_template):
    """Clip dataset and save result to data set.
    
    Args:
        input_file: file to be cliped
        output_file: filename of the cliped data set
        clip_template: file from which the clipping extend is taken
    """
    print "Clipping dataset..."
    arcpy.Clip_management(input_file, "#", output_file, \
                          clip_template, "0", "ClippingGeometry")

    
def compute_extract_by_mask(input_file, output_file, mask_file):
    """Extract feature by mask  and save result to data set.
    
    Args:
        input_file: file to be extracted
        output_file: filename of the extracted data set
        mask_file: mask used for extraction
    """
    print "Extracting by mask..."
    extract_by_mask = arcpy.sa.ExtractByMask(input_file, mask_file)
    extract_by_mask.save(output_file)


def compute_flowdirection(input_file, output_file):
    """Compute flow direction and save result to data set.
    
    Args:
        input_file: input dgm file
        output_file: output file
    """
    print "Computing flow direction..."
    flow_direction = arcpy.sa.FlowDirection(input_file, "NORMAL")
    flow_direction.save(output_file)


def compute_basin(input_file, output_file):
    """Compute basin and save result to data set.
    
    Args:
        input_file: input flow direction file
        output_file: output file
    """
    print "Computing basin..."
    basin = arcpy.sa.Basin(input_file)
    basin.save(output_file)


def compute_sinks(input_file, output_file):
    """Compute sinks and save result to data set.
    
    Args:
        input_file: input flow direction file
        output_file: output file
    """
    print "Computing sinks..."
    sinks = arcpy.sa.Sink(input_file)
    sinks.save(output_file)


def compute_flow_accumulation(input_file, output_file):
    """Compute flow accumulation and save result to data set.
    
    Args:
        input_file: input flow direction file
        output_file: output file
    """
    print "Computing flow accumulation..."
    flow_accumulation = arcpy.sa.FlowAccumulation(input_file, "", \
                                                  "float")
    flow_accumulation.save(output_file)


def compute_min_pixel(input_file, output_file):
    """Create raster containing the pixel with the minimum value
    
    Args:
        input_file: input file from which the minimum pixel will be extracted
        output_file: output file
    """
    print "Computing minimum pixel location..."
    raster_dataset = arcpy.Raster(input_file)
    min_value = round(raster_dataset.minimum, 1) + 0.05
    min_pixel = arcpy.sa.ExtractByAttributes(raster_dataset, \
                    "Value <= " + str(min_value))
    min_pixel.save(output_file)
    return min_value


def convert_raster_to_point(input_file, output_file):
    """Convert raster to point vector
    
    Args:
        input_file: input raster file
        output_file: output point vector file
    """
    print "Converting raster to points..."
    arcpy.RasterToPoint_conversion(input_file, output_file)  


def convert_raster_to_polygon(input_file, output_file):
    """Convert raster to polygon vector
    
    Args:
        input_file: input raster file
        output_file: output polygon vector file
    """
    print "Converting raster to polygons..."
    arcpy.RasterToPolygon_conversion(input_file, output_file, \
                                         "NO_SIMPLIFY", "VALUE")  

def compute_difference(input_file_1, input_file_2, output_file):
    """Compute diffrence between two data sets (one could be a scalar)
    
    Args:
        input_file_1: input raster file 1/scalar
        input_file_2: input raster file 2/scalar
        output_file: output raster file
    """
    print "Computing difference between two files/values..."
    print input_file_1
    print input_file_2
    print output_file
    difference = arcpy.sa.Minus(input_file_1, input_file_2)
    difference.save(output_file)


def set_no_data(input_file, condition, output_file, false_file=False):
    """Set values to no data based on a condition
    
    Args:
        input_file: input raster file
        condition: condition which determines no data values
        output_file: output raster file
        false_file: optional file defining the no data pixels
    """
    print "Setting no data values..."
    if false_file == False:
        false_file = input_file
    no_data = arcpy.sa.SetNull(input_file, false_file, condition)
    no_data.save(output_file)


def reclassify_raster(input_file, map_list, output_file):
    """Reclassify raster data set
    
    Args:
        input_file: input raster file
        map_list: list containing the reclassification logic
                  [[old_min, old_max, new_value], [...]]
        output_file: output raster file
    """
    print "Reclassifying raster..."
    map_list = arcpy.sa.RemapValue(map_list)
    reclassify = arcpy.sa.Reclassify(input_file, "VALUE", \
                                          map_list, "NODATA")
    reclassify.save(output_file)


def select_by_location(input_file, mask_file, overlap, output_file=False):
    """Select data subset by location
    
    Args:
        input_file: input file from which the information should be selected
        mask_file: file containig the features used for the selection
        overlap: overlap condition (e.g. contains, intersects)
        output_file: optional output file
                     (if not provided, the function will return true/false
                     which indicates if a selection has been made)
    """
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
    Compute flooded areas for all individual catchments and different water
    level heights.
    
    The script assumes that all initial data sets are stored in the
    personal geodatabase. If this is not the case, the content of function
    make_filepathes has to be addapted.
    """

    print
    print 'Module: overflow'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print  
    
    # Define environment variables and DGM filepath
    pgdb_filepath = "D:/active/schalke/arcgis/schalke.mdb/"
    arcpy.env.workspace = pgdb_filepath
    arcpy.env.overwriteOutput = True
    
    dgm_filepath = pgdb_filepath + "dgm1_schal"
    fpd = make_filepathes(dgm_filepath)
    fpd["dgm"] = fpd["dgm"] + "_clip"
    flood_increment = 1
    
    # Extract dgm areas for individual catchments and compute flooded area
    # for increasing water levels until the drainage channel is reached.
    shapeName = arcpy.Describe(fpd["pumped_catchments"]).shapeFieldName
    inrows = arcpy.SearchCursor(fpd["pumped_catchments"])
    catchment = 0
    for row in inrows:
        catchment = catchment + 1
        print "Computing catchment ", catchment
        catchment_string = "_" + str(catchment).zfill(2)
        feature = row.shape
        act_dgm_filepath_ezgb = fpd["dgm_ezgb"] + catchment_string
        compute_extract_by_mask(fpd["dgm"], act_dgm_filepath_ezgb, feature)
    
        level = compute_min_pixel(act_dgm_filepath_ezgb, fpd["min"])
        convert_raster_to_point(fpd["min"], fpd["min_points"])
    
        reached_channel = False
    
        while reached_channel == False:
            level = level + flood_increment
            level_string = "_" + str(int(level)).zfill(2)
            print "Computing flood plane for water level: ", level
        
            compute_difference(level, fpd["dgm"], fpd["diff_dgm"])
            compute_difference(level, fpd["dom"], fpd["diff_dom"])

            set_no_data(fpd["diff_dgm"], "Value < 0", fpd["diff_dgm_nd"])
            set_no_data(fpd["diff_dom"], "Value < 0", fpd["diff_dom_nd"])
        
            reclassify_raster(fpd["diff_dgm_nd"], [[0,9999999,1]], \
                fpd["diff_dgm_nd_one"])
        
            convert_raster_to_polygon(fpd["diff_dgm_nd_one"], \
                fpd["diff_dgm_poly"])
        
            overlap = "contains"
            select_by_location(fpd["diff_dgm_poly"], fpd["min_points"], \
                overlap, fpd["diff_dgm_poly_main"])

            act_diff_dgm_nd_filepath = fpd["diff_dgm_nd"] + catchment_string + \
                level_string
            compute_extract_by_mask(fpd["diff_dgm_nd"], \
                act_diff_dgm_nd_filepath, fpd["diff_dgm_poly_main"])
            act_diff_dom_nd_filepath = fpd["diff_dom_nd"] + catchment_string + \
                level_string
            compute_extract_by_mask(fpd["diff_dom_nd"], \
                act_diff_dom_nd_filepath, fpd["diff_dgm_poly_main"])

            overlap = "intersect"
            reached_channel = select_by_location(fpd["river"], \
                fpd["diff_dgm_poly_main"], overlap)
        
            print "Channel has been reached? ", reached_channel
        os.sys.exit()
    print "...finished"

if __name__ == '__main__':
  main()
  
  
