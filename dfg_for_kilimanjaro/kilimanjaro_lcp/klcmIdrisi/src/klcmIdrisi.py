"""Prepare datasets for Kilimanjaro landcover classification using Idrisi
Copyright (C) 2013 Thomas Nauss

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

Please send any comments, suggestions, criticism, or (for our sake) bug
reports to nausst@googlemail.com
"""

__author__ = "Thomas Nauss <nausst@googlemail.com>"
__version__ = "2013-04-21"
__license__ = "GNU GPL, see http://www.gnu.org/licenses/"

import gc
import fnmatch
import optparse
import os
import shutil
import win32com.client


def locate(pattern, patternpath, root=os.curdir):
    '''Locate files matching filename pattern recursively
    
    This routine is based on the one from Simon Brunning at
    http://code.activestate.com/recipes/499305/ and extended by the patternpath.
     
    Args:
        pattern: Pattern of the filename
        patternpath: Pattern of the filepath
        root: Root directory for the recursive search
    
    Returns:
        dataset: List of datasets matching the criterias
    '''
    for path, dirs, files in os.walk(os.path.abspath(root)):
        for filename in fnmatch.filter(files, pattern):
            # Modified by Thomas Nauss
            if fnmatch.fnmatch(path, patternpath):
                yield os.path.join(path, filename)


def command_line_parsing():
    '''Set handling of command line arguments
    
    Returns:
        ...: various command line arguments
    '''
    parser = optparse.OptionParser("usage: %prog [options]")
    parser.add_option("-i", nargs=1, dest="input_osm_path",
      help="Path to the input folder of the osm data.", metavar="string")
    parser.add_option("-o", nargs=1, dest="output_plot_path",
      help="Path to the final plot-based output folder.", metavar="string")
    parser.add_option("-a", nargs=1, dest="input_aster_path",
      help="Path to the input folder of the ASTER data.", metavar="string")
    parser.add_option("-d", nargs=1, dest="input_dem_path",
      help="Path to the input folder of the DEM data.",metavar="string")
    (options, args) = parser.parse_args()

    if options.input_osm_path != None: 
        input_path = options.input_osm_path
    else:
        input_osm_path = os.getcwd()+os.sep
    if options.output_plot_path != None: 
        output_plot_path = options.output_plot_path
    else:
        output_plot_path = os.getcwd()+os.sep
    if options.input_aster_path != None: 
        input_aster_path = options.input_aster_path
    else:
        input_aster_path = os.getcwd()+os.sep
    if options.input_dem_path != None:
        input_dem_path = options.input_dem_path
    else:
        input_dem_path = os.getcwd()+os.sep

    return input_path, output_plot_path, input_aster_path, input_dem_path
    
def sort_datasets(satellite_datasets, output_plot_path):
    '''Sort osm datasets into subfolders and return a list of the directories.
    
    Args:
        satellite_datasets: OSM satellite data/region to be processed
        output_plot_path: Top-level output path of the datasets
    '''
    for dataset in satellite_datasets:
        print " "
        print "Sorting dataset ", dataset
        act_output_path = output_plot_path + os.sep + \
                          os.path.splitext(os.path.basename(dataset))[0][0:4]
        if not os.path.exists(act_output_path):
            os.mkdir(act_output_path)
        print act_output_path
        shutil.move(dataset, act_output_path) 

    
def get_target_plots(output_plot_path):
    '''Get target datasets locations (i.e. osm filepaths) to be processed.
    
    Args:
        output_plot_path: Top-level output path of the datasets
        
    Returns:
        List of target plot ids of the osm dataset
    '''
    return map(lambda x: x.upper(), os.walk(output_plot_path).next()[1])

    
def get_aster_datasets(input_aster_path):
    '''Get filepath of ASTER datasets.
    
    Args:
        input_aster_path: Top-level path of the ASTER datasets
        
    Returns:
        ast_dict: Dictionary of ASTER dataset filepaths
    '''
    ast_dict = {}
    ast_dict['AST_B030201'] = input_aster_path + os.sep + \
        "bands_composites" + os.sep + "AST_B030201.rst"
    ast_dict['AST_NDVI'] = input_aster_path + os.sep + \
        "bands_indices" + os.sep + "AST_NDVI.rst"
    ast_dict['AST_MNF1_SOL'] = input_aster_path + os.sep + \
        "bands_mnf_sol" + os.sep + "AST_MNF1_SOL.rst"
    ast_dict['AST_MNF2_SOL'] = input_aster_path + os.sep + \
        "bands_mnf_sol" + os.sep + "AST_MNF2_SOL.rst"
    ast_dict['AST_MNF3_SOL'] = input_aster_path + os.sep + \
        "bands_mnf_sol" + os.sep + "AST_MNF3_SOL.rst"
    ast_dict['AST_MNF1_SOL_ABF7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF1_SOL_ABF7.rst"
    ast_dict['AST_MNF1_SOL_I_VFI7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF1_SOL_I_VFI7.rst"
    ast_dict['AST_MNF1_SOL_MAX3'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF1_SOL_MAX3.rst"
    ast_dict['AST_MNF1_SOL_SLOPE'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF1_SOL_SLOPE.rst"
    ast_dict['AST_MNF1_SOL_SLOPE_MED7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF1_SOL_SLOPE_MED7.rst"
    ast_dict['AST_MNF2_SOL_ABF7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF2_SOL_ABF7.rst"
    ast_dict['AST_MNF2_SOL_I_VFI7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF2_SOL_I_VFI7.rst"
    ast_dict['AST_MNF2_SOL_MAX3'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF2_SOL_MAX3.rst"
    ast_dict['AST_MNF2_SOL_SLOPE'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF2_SOL_SLOPE.rst"
    ast_dict['AST_MNF2_SOL_SLOPE_MED7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF2_SOL_SLOPE_MED7.rst"
    ast_dict['AST_MNF3_SOL_ABF7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF3_SOL_ABF7.rst"
    ast_dict['AST_MNF3_SOL_I_VFI7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF3_SOL_I_VFI7.rst"
    ast_dict['AST_MNF3_SOL_MAX3'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF3_SOL_MAX3.rst"
    ast_dict['AST_MNF3_SOL_SLOPE'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF3_SOL_SLOPE.rst"
    ast_dict['AST_MNF3_SOL_SLOPE_MED7'] = input_aster_path + os.sep + \
        "bands_mnf_sol_filtered" + os.sep + "AST_MNF3_SOL_SLOPE_MED7.rst"
    ast_dict['AST_IMNF_123_TER1'] = input_aster_path + os.sep + \
        "bands_mnf_ter" + os.sep + "AST_IMNF_123_TER1.rst"
    ast_dict['AST_CLOUDMASK'] = input_aster_path + os.sep + \
        "cloudmask" + os.sep + "AST_CLOUDMASK.rst"   
    return ast_dict


def get_dem_datasets(input_dem_path):
    '''Get filepath of dem datasets.
    
    Args:
        input_dem_path: Top-level path of the dem datasets
        
    Returns:
        dem_dict: Dictionary of dem dataset filepaths
    '''
    dem_dict = {}
    dem_dict['DEM_UTM37S'] = input_dem_path + os.sep + "DEM_UTM37S.rst"
    dem_dict['DEM_UTM37S_SLOPE'] = input_dem_path + os.sep + \
        "DEM_UTM37S_SLOPE.rst"
    return dem_dict

    
def main():
    '''Project tiff files in a directory to a target projection and file type. 
    
    The projection is done by using an os call to gdalwarp. For this, the output
    format is GeoTiff. Afterwards, the projected files are transfered in the
    target projection. This is done because of an error which occured for Idrisi
    RST files as target projection in gdalwarp and can be changed if the error
    no longer occures in a future release.
    
    python klcmIdrisi.py -i E:\kilimanjaro_landcover\satellite_data\osm_mrg_utm37s -o E:\kilimanjaro_landcover\plots -a E:\kilimanjaro_landcover\satellite_data\ast14dmo_00302282011075438_20111206102625_30591 -d E:\kilimanjaro_landcover\satellite_data\dem
    '''
    print
    print 'Module: klcmIdrisi'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print   
    
    #Get command line arguments
    input_path, output_plot_path, input_aster_path, input_dem_path = \
        command_line_parsing()
    
    IDRISI32 = win32com.client.Dispatch('IDRISI32.IdrisiAPIServer')

    #Get osm datasets (which define which plots are processed)
    satellite_datasets=locate("*.*", "*", input_path)

    #Sort osm datasets to individual plot folders (e.g. cof1, cof2, ...)
    sort_datasets(satellite_datasets, output_plot_path)
    
    #Get list of osm dataset folders to be processed
    target_plots = get_target_plots(output_plot_path)
    
    #Get ASTER source datasets
    ast_dict = get_aster_datasets(input_aster_path)
    
    #Get DEM source datasets
    dem_dict = get_dem_datasets(input_dem_path)
    
    #Process data for each osm plot region
    for target_plot in target_plots:
        print 
        print "Processing target plot: " + target_plot

        output_path = output_plot_path + os.sep + \
                target_plot + os.sep
        
        for entry in ast_dict:
            input_filepath = ast_dict[entry]
            output_filepath = output_path + target_plot + "_" + \
                os.path.basename(input_filepath)
            osm_dataset = output_path + target_plot + \
                "_osm_mrg_epsg-32737_1.rst"
            
            #Extract windows from ASTER data
            idrisi_cmd = input_filepath + "*" + output_filepath + "*3*" + \
                osm_dataset
            IDRISI32.RunModule('WINDOW', idrisi_cmd, 1, '', '', '', '', 1)
            
        for entry in dem_dict:
            input_filepath = dem_dict[entry]
            output_filepath = output_path + target_plot + "_" + \
                              os.path.basename(input_filepath)
            osm_dataset = output_path + target_plot + \
                          "_osm_mrg_epsg-32737_1.rst"
            idrisi_cmd = input_filepath + "*" + output_filepath + "*3*" + \
                         osm_dataset
            IDRISI32.RunModule('WINDOW', idrisi_cmd, 1, '', '', '', '', 1)

        #Standardize datasets
        ast_cloudmask = output_path + target_plot + "_" + \
            os.path.basename(ast_dict["AST_CLOUDMASK"])
        for entry in ast_dict:
            if "CLOUDMASK" not in entry and "B030201" not in entry:
                input_filepath = output_path + target_plot + "_" + \
                    os.path.basename(ast_dict[entry])
                output_filepath = os.path.dirname(input_filepath) + os.sep + \
                    os.path.splitext(os.path.basename(input_filepath))[0] + \
                    "_SCM.rst"
                idrisi_cmd = input_filepath + "*" + output_filepath + "*" + \
                    ast_cloudmask
                IDRISI32.RunModule('STANDARD', idrisi_cmd, 1, '', '', '', '', 1)
        
        for entry in dem_dict:
            input_filepath = output_path + target_plot + "_" + \
                os.path.basename(dem_dict[entry])
            output_filepath = os.path.dirname(input_filepath) + os.sep + \
                os.path.splitext(os.path.basename(input_filepath))[0] + \
                "_S.rst"
            idrisi_cmd = input_filepath + "*" + output_filepath
            IDRISI32.RunModule('STANDARD', idrisi_cmd, 1, '', '', '', '', 1)

        #Compute osm RGB composites
        input_filepath_red = output_path + target_plot + \
            "_osm_mrg_epsg-32737_1.rst"
        input_filepath_green = output_path + target_plot + \
            "_osm_mrg_epsg-32737_2.rst"
        input_filepath_blue = output_path + target_plot + \
            "_osm_mrg_epsg-32737_3.rst"
        output_filepath = os.path.dirname(input_filepath_red) + os.sep + \
            target_plot + "_osm_mrg_epsg-32737_123.rst"
        idrisi_cmd = input_filepath_blue + "*" + input_filepath_green + "*" + \
            input_filepath_red + "*" + output_filepath + "*1*1*2*2"
        IDRISI32.RunModule('COMPOSITE', idrisi_cmd, 1, '', '', '', '', 1)
        
        #Make raster group files
        rgf_mnf_sol_filepath = output_path + target_plot + \
            "_AST_MNF_SOL_SCM.rgf"
        rgf_file = open(rgf_mnf_sol_filepath, "w")
        rgf_file.write("3\n")
        rgf_file.write(output_path + target_plot + "_" + \
            os.path.splitext(os.path.basename(\
            ast_dict['AST_MNF1_SOL']))[0] + "_SCM\n")
        rgf_file.write(output_path + target_plot + "_" + \
            os.path.splitext(os.path.basename(\
            ast_dict['AST_MNF2_SOL']))[0] + "_SCM\n")
        rgf_file.write(output_path + target_plot + "_" + \
            os.path.splitext(os.path.basename(\
            ast_dict['AST_MNF3_SOL']))[0] + "_SCM\n")
        rgf_file.close()
        
        rgf_ast_dem_filepath = output_path + target_plot + \
            "_AST_DEM_SCM_CLASSIFICATION.rgf"
        file_counter = 0
        file_content = []
        for entry in ast_dict:
            if "CLOUDMASK" not in entry and "B030201" not in entry and \
            "AST_MNF1_SOL" is not entry and "AST_MNF2_SOL" is not entry and \
            "AST_MNF3_SOL" is not entry:
                file_counter = file_counter + 1
                file_content.append(output_path + target_plot + "_" + \
                    os.path.splitext(os.path.basename(\
                    ast_dict[entry]))[0] + "_SCM\n")
        for entry in dem_dict:
            file_counter = file_counter + 1
            file_content.append(output_path + target_plot + "_" + \
            os.path.splitext(os.path.basename(\
            dem_dict[entry]))[0] + "_S\n")
        rgf_file = open(rgf_ast_dem_filepath, "w")
        rgf_file.write(str(file_counter) + "\n")
        for line in sorted(file_content):
            rgf_file.write(line)
        rgf_file.close()

        #Clean up a little bit
        misc_output_path = output_path + "misc" + os.sep
        if not os.path.exists(misc_output_path):
            os.mkdir(misc_output_path)
        files=locate("*.*", "*", output_path)
        for file in files:
            if "_SCM" not in file and "_S." not in file and \
            "osm_mrg_epsg-32737_123" not in file and "321" not in file:
                try:
                    shutil.move(file, misc_output_path) 
                except:
                    continue
        
        #Compute segmentation based on AST_MNF_SOL_SCM dataset
        weight_filepath = output_path + target_plot + \
            "_SEGMENTATION_WEIGHTS.txt"
        weight_file = open(weight_filepath, "w")
        weight_file.write("3 \n")
        weight_file.write("0.20 \n")
        weight_file.write("0.70 \n")
        weight_file.write("0.10 \n")
        weight_file.close()
        idrisi_cmd = rgf_mnf_sol_filepath + "*" + \
            output_path + target_plot + "_AST_MNF_SOL_SCM_207010_7030" + \
            "*" + "3" + "*" + \
            "140, 130, 120, 110, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10" + \
            "*" + weight_filepath + "*" + "0.70" + "*" + "0.30"
        IDRISI32.RunModule('SEGMENTATION', idrisi_cmd, 1, '', '', '', '', 1)
        
        #Create idrisi environment
        idrisi_env = open(output_path + target_plot + ".env", "w")
        idrisi_env.write(output_path + "\n")
        idrisi_env.write(output_path + "misc\n")
        idrisi_env.close()
        gc.collect()
    
    print
    print "...finished."
    
if __name__ == '__main__':
    main()
