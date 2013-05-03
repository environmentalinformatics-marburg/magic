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
    parser.add_option("-g", nargs=1, dest="idrisi_working_directory",
      help="Path to the IDRISI working directory.",metavar="string")
    (options, args) = parser.parse_args()

    if options.input_osm_path != None: 
        input_path = options.input_osm_path + os.sep
    else:
        input_osm_path = os.getcwd()+os.sep
    if options.output_plot_path != None: 
        output_plot_path = options.output_plot_path + os.sep
    else:
        output_plot_path = os.getcwd()+os.sep
    if options.input_aster_path != None: 
        input_aster_path = options.input_aster_path + os.sep
    else:
        input_aster_path = os.getcwd()+os.sep
    if options.input_dem_path != None:
        input_dem_path = options.input_dem_path + os.sep
    else:
        input_dem_path = os.getcwd()+os.sep
    if options.idrisi_working_directory != None:
        idrisi_working_directory = options.idrisi_working_directory + os.sep
    else:
        idrisi_working_directory = os.getcwd()+os.sep

    return input_path, output_plot_path, input_aster_path, input_dem_path, \
        idrisi_working_directory
    
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
        ast_input_dict: Dictionary of ASTER input dataset filepaths
        ast_output_dict: Dictionary of ASTER output dataset filepaths
    '''
    if "ast14dmo_00302242013080106_20130307023703_15004" in input_aster_path:
        ast_code = "AST_20130224_"
    ast_input_dict = {}
    ast_input_dict['AST_B01'] = ast_code + "B01.rst"
    ast_input_dict['AST_B02'] = ast_code + "B02.rst"
    ast_input_dict['AST_B03'] = ast_code + "B03.rst"
    ast_input_dict['AST_B13'] = ast_code + "B13.rst"
    ast_input_dict['AST_B14'] = ast_code + "B14.rst"
    
    ast_output_dict = {}
    ast_output_dict['AST_SOL_RGF'] = ast_code + "SOL.rgf"
    ast_output_dict['AST_MNF_SOL_RGF'] = ast_code + "MNF_SOL.rgf"
    ast_output_dict['AST_MNF_SOL_S_RGF'] = ast_code + "MNF_SOL_S.rgf"
    ast_output_dict['AST_S_CLASSIFICATION_RGF'] = ast_code + \
        "AST_S_CLASSIFICATION_RGF.rgf"
    ast_output_dict['AST_ALL_S_CLASSIFICATION_RGF'] = ast_code + \
        "AST_ALL_S_CLASSIFICATION_RGF.rgf"
    ast_output_dict['AST_ALL_DEM_S_CLASSIFICATION_RGF'] = ast_code + \
        "AST_ALL_DEM_S_CLASSIFICATION_RGF.rgf"
    ast_output_dict['AST_DEM_S_CLASSIFICATION_RGF'] = ast_code + \
        "AST_DEM_S_CLASSIFICATION_RGF.rgf"
    ast_output_dict['AST_TEMP'] = ast_code + "TEMP.rst"
    ast_output_dict['AST_OVERLAY_2'] = ast_code + "OVERLAY_2.rst"
    ast_output_dict['AST_OVERLAY_100'] = ast_code + "OVERLAY_100.rst"
    ast_output_dict['AST_B030201'] = ast_code + "B030201.rst"
    ast_output_dict['AST_NDVI'] = ast_code + "NDVI.rst"
    ast_output_dict['AST_MNF1_SOL'] = ast_code + "MNF1_SOL.rst"
    ast_output_dict['AST_MNF2_SOL'] = ast_code + "MNF2_SOL.rst"
    ast_output_dict['AST_MNF3_SOL'] = ast_code + "MNF3_SOL.rst"
    ast_output_dict['AST_MNF1_SOL_I'] = ast_code + "MNF1_SOL_I.rst"
    ast_output_dict['AST_MNF2_SOL_I'] = ast_code + "MNF2_SOL_I.rst"
    ast_output_dict['AST_MNF3_SOL_I'] = ast_code + "MNF3_SOL_I.rst"
    ast_output_dict['AST_MNF1_SOL_ABF7'] = ast_code + "MNF1_SOL_ABF7.rst"
    ast_output_dict['AST_MNF2_SOL_ABF7'] = ast_code + "MNF2_SOL_ABF7.rst"
    ast_output_dict['AST_MNF3_SOL_ABF7'] = ast_code + "MNF3_SOL_ABF7.rst"
    ast_output_dict['AST_MNF1_SOL_MAX3'] = ast_code + "MNF1_SOL_MAX3.rst"
    ast_output_dict['AST_MNF2_SOL_MAX3'] = ast_code + "MNF2_SOL_MAX3.rst"
    ast_output_dict['AST_MNF3_SOL_MAX3'] = ast_code + "MNF3_SOL_MAX3.rst"
    ast_output_dict['AST_MNF1_SOL_MED7'] = ast_code +  "MNF1_SOL_MED7.rst"
    ast_output_dict['AST_MNF2_SOL_MED7'] = ast_code +  "MNF2_SOL_MED7.rst"
    ast_output_dict['AST_MNF3_SOL_MED7'] = ast_code +  "MNF3_SOL_MED7.rst"
    ast_output_dict['AST_MNF1_SOL_SLOPE'] = ast_code + "MNF1_SOL_SLOPE.rst"
    ast_output_dict['AST_MNF2_SOL_SLOPE'] = ast_code + "MNF2_SOL_SLOPE.rst"
    ast_output_dict['AST_MNF3_SOL_SLOPE'] = ast_code + "MNF3_SOL_SLOPE.rst"
    ast_output_dict['AST_MNF1_SOL_SLOPE_MED7'] = ast_code + \
        "MNF1_SOL_SLOPE_MED7.rst"
    ast_output_dict['AST_MNF2_SOL_SLOPE_MED7'] = ast_code + \
        "MNF2_SOL_SLOPE_MED7.rst"
    ast_output_dict['AST_MNF3_SOL_SLOPE_MED7'] = ast_code + \
        "MNF3_SOL_SLOPE_MED7.rst"
    ast_output_dict['AST_MNF1_SOL_I_VFI7'] = ast_code + \
        "MNF1_SOL_I_VFI7.rst"
    ast_output_dict['AST_MNF2_SOL_I_VFI7'] = ast_code + \
        "MNF2_SOL_I_VFI7.rst"
    ast_output_dict['AST_MNF3_SOL_I_VFI7'] = ast_code + \
        "MNF3_SOL_I_VFI7.rst"
    ast_output_dict['AST_B1314_SW'] = ast_code + \
        "B1314_SW.rst"
    #ast_output_dict['AST_CLOUDMASK'] = input_aster_path + os.sep + \
    #    "cloudmask" + os.sep + "AST_CLOUDMASK.rst"   
    #ast_output_dict['AST_IMNF_123_TER1_R'] = ast_code + \
    #    "IMNF_123_TER1_R.rst"
    return ast_input_dict, ast_output_dict, ast_code


def get_dem_datasets():
    '''Get filepath of dem datasets.
    
    Returns:
        dem_dict: Dictionary of dem dataset filepaths
    '''
    dem_dict = {}
    dem_dict['DEM_epsg-32737'] = "DEM_epsg-32737.rst"
    dem_dict['DEM_epsg-32737_SLOPE'] = "DEM_epsg-32737_SLOPE.rst"
    return dem_dict

def read_metadata(filepath):
        """Reads metadata from an Idrisi file and return a dictionary.
        
        Args:
            title: Title of the file
            datatype: Datatype of the file
            filetype: Filetype
            ncols: Number of self.ncols
            nrows: Number of self.nrows
            ref_system: Reference system
            ref_units: Reference units
            unit_distance: Unit distance
            min_x: Minimum X coordinate
            max_x: Maximum X coordinate
            min_y: Minimum Y coordinate
            max_y: Maximum Y coordinate
            min_disp_val: Minimum display value
            max_disp_val: Maximum display value

        Thanks to Jan Cermak (http://www.iac.ethz.ch/people/cermakj)
        who counted all the lines.
        """
        metadata = {}
        metadata['name'] = filepath
        file = open(filepath)
        for line in file:
            if line.find('file title') != -1:
                metadata['title'] = line[13:].strip()
            elif line.find('data type') != -1:
                metadata['datatype'] = line[13:].strip()
                """
                self.datatype = line[13:].strip()
                if self.datatype == 'real':
                    metadata['datatype'] = 4
                elif self.datatype == 'integer':
                    metadata['datatype'] = 2
                elif self.datatype == 'byte':
                    metadata['datatype'] = 1
                """
            elif line.find('file type') != -1:
                metadata['filetype'] = line[13:].strip()
            elif line.find('columns') != -1:
                metadata['cols'] = int(line[13:].strip())
            elif line.find('rows') != -1:
                metadata['rows'] = int(line[13:].strip())
            elif line.find('ref. system') != -1:
                metadata['ref_system'] = line[13:].strip()
            elif line.find('ref. units') != -1:
                metadata['ref_units'] = line[13:].strip()
            elif line.find('unit dist.') != -1:
                metadata['unit_distance'] = float(line[13:].strip())
            elif line.find('min. X') != -1:
                metadata['min_x'] = float(line[13:].strip())
            elif line.find('max. X') != -1:
                metadata['max_x'] = float(line[13:].strip())
            elif line.find('min. Y') != -1:
                metadata['min_y'] = float(line[13:].strip())
            elif line.find('max. Y') != -1:
                metadata['max_y'] = float(line[13:].strip())
            elif line.find('min. value') != -1:
                metadata['min_disp_val'] = float(line[13:].strip())
            elif line.find('max. value') != -1:
                metadata['max_disp_val'] = float(line[13:].strip())
            elif line.find('legend cats') != -1:
                metadata['legend cats'] = line[13:].strip()
            elif line.find('code') != -1:
                if 'codes' in metadata:
                    metadata['codes'].append(line[0:].strip())
                else:
                    metadata['codes'] = [line[0:].strip()]
        file.close()
        return metadata    
def main():
    '''Project tiff files in a directory to a target projection and file type. 
    
    The projection is done by using an os call to gdalwarp. For this, the output
    format is GeoTiff. Afterwards, the projected files are transfered in the
    target projection. This is done because of an error which occured for Idrisi
    RST files as target projection in gdalwarp and can be changed if the error
    no longer occures in a future release.
    
    python klcmIdrisi_reloaded.py -i E:\kilimanjaro_landcover\satellite_data\osm_mrg_utm37s -o E:\kilimanjaro_landcover\plots -a E:\kilimanjaro_landcover\satellite_data\ast14dmo_00302242013080106_20130307023703_15004\bands -d E:\kilimanjaro_landcover\satellite_data\dem -g E:\kilimanjaro_landcover\idrisi
    '''
    print
    print 'Module: klcmIdrisi'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print   
    
    #Get command line arguments
    input_path, output_plot_path, input_aster_path, input_dem_path, \
        idrisi_working_directory = command_line_parsing()
    
    IDRISI32 = win32com.client.Dispatch('IDRISI32.IdrisiAPIServer')

    #Get osm datasets (which define which plots are processed)
    satellite_datasets=locate("*.*", "*", input_path)

    #Sort osm datasets to individual plot folders (e.g. cof1, cof2, ...)
    sort_datasets(satellite_datasets, output_plot_path)
    
    #Get list of osm dataset folders to be processed
    target_plots = get_target_plots(output_plot_path)
    
    #Get ASTER source datasets
    ast_input_dict, ast_output_dict, ast_code = \
        get_aster_datasets(input_aster_path)
    
    #Get DEM source datasets
    dem_dict = get_dem_datasets()
    
    #Process data for each osm plot region
    for target_plot in target_plots:
        print 
        print "Processing target plot: " + target_plot

        #Set path
        output_path = output_plot_path + target_plot + os.sep
        osm_dataset = output_path + target_plot + \
                "_osm_mrg_epsg-32737_1.rst"
        output_filepath_prefix = output_path + target_plot + "_"
        input_dem_path = input_dem_path + os.sep
        metadata = None
        
        #Extract windows from ASTER data and compute integer version
        print "Extracting windows from satellite channels..."
        for entry in sorted(ast_input_dict, key=ast_input_dict.get):
            if "_B1" not in entry:
                input_filepath = input_aster_path + ast_input_dict[entry]
                output_filepath = output_filepath_prefix + ast_input_dict[entry]
                idrisi_cmd = input_filepath + "*" + output_filepath + "*3*" + \
                    osm_dataset
                ###IDRISI32.RunModule('WINDOW',idrisi_cmd,1,'','','','',1)
                if os.path.isfile(\
                    os.path.splitext(output_filepath)[0] + ".rdc"):
                    metadata = read_metadata(\
                    os.path.splitext(output_filepath)[0] + ".rdc")
            else:
                input_filepath = input_aster_path + ast_input_dict[entry]
                output_filepath = output_filepath_prefix + ast_input_dict[entry]
                if metadata != None:
                    idrisi_cmd = "1*" + input_filepath + "*utm-37s*" + \
                        output_filepath + "*utm-37s*" + \
                        str(metadata['min_x']) + "*" + \
                        str(metadata['max_x']) + "*" + \
                        str(metadata['min_y']) + "*" + \
                        str(metadata['max_y']) + "*" + \
                        str(metadata['cols']) + "*" + \
                        str(metadata['rows']) + "*0*2"
                    ###IDRISI32.RunModule('PROJECT',idrisi_cmd,1,'','','','',1)

        #Extract windows from DEM data
        print "Extracting windows from dem..."
        for entry in dem_dict:
            input_filepath = input_dem_path + dem_dict[entry]
            output_filepath = output_filepath_prefix + dem_dict[entry]
            idrisi_cmd = input_filepath + "*" + output_filepath + "*3*" + \
                         osm_dataset
            ###IDRISI32.RunModule('WINDOW',idrisi_cmd,1,'','','','',1)

        #Compute RGB composites
        print "Computing composites..."
        input_filepath_03 = output_filepath_prefix + \
            "osm_mrg_epsg-32737_1.rst"
        input_filepath_02 = output_filepath_prefix + \
            "osm_mrg_epsg-32737_2.rst"
        input_filepath_01 = output_filepath_prefix + \
            "osm_mrg_epsg-32737_3.rst"
        output_filepath = output_filepath_prefix + \
            "osm_mrg_epsg-32737_123.rst"
        idrisi_cmd = input_filepath_01 + "*" + input_filepath_02 + "*" + \
            input_filepath_03 + "*" + output_filepath + "*1*1*2*2"
        ###IDRISI32.RunModule('COMPOSITE',idrisi_cmd,1,'','','','',1)

        input_filepath_03 = output_filepath_prefix + \
            ast_input_dict["AST_B03"]
        input_filepath_02 = output_filepath_prefix + \
            ast_input_dict["AST_B02"]
        input_filepath_01 = output_filepath_prefix + \
            ast_input_dict["AST_B01"]
        output_filepath = output_filepath_prefix + \
            ast_output_dict['AST_B030201']
        idrisi_cmd = input_filepath_01 + "*" + input_filepath_02 + "*" + \
            input_filepath_03 + "*" + output_filepath + "*1*1*2*2"
        ###IDRISI32.RunModule('COMPOSITE',idrisi_cmd,1,'','','','',1)
        
        #Create raster group file of bands 01 to 03
        rgf_sol_filepath = output_filepath_prefix + \
            ast_output_dict['AST_SOL_RGF']
        rgf_file = open(rgf_sol_filepath, "w")
        rgf_file.write("3\n")
        rgf_file.write(input_filepath_01 + "\n")
        rgf_file.write(input_filepath_02 + "\n")
        rgf_file.write(input_filepath_03 + "\n")
        rgf_file.close()
        
        #Compute NDVI
        print "Computing NDVI..."
        output_filepath = output_filepath_prefix +  ast_output_dict['AST_NDVI']
        idrisi_cmd = "2*" + output_filepath + "*" + input_filepath_02 + \
            "*" + input_filepath_03
        ###IDRISI32.RunModule('VEGINDEX',idrisi_cmd,1,'','','','',1)
        
        #Compute MNF
        print "Computing MNF..."
        output_filepath = output_filepath_prefix + "temp_"
        idrisi_cmd = "1*1*3*" + output_filepath + "*" + rgf_sol_filepath + \
            "*none*2"
        ###IDRISI32.RunModule('MNF',idrisi_cmd,1,'','','','',1)
        try:
            os.remove(output_filepath + ".rgf")
        except:
            pass
        rgf_mnf_sol_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF_SOL_RGF']
        rgf_file = open(rgf_mnf_sol_filepath, "w")
        rgf_file.write("3\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF1_SOL'])[0] + "\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF2_SOL'])[0] + "\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF3_SOL'])[0] + "\n")
        rgf_file.close()
        try:
            os.rename(output_filepath + "cmp1.rst", output_filepath_prefix + \
                ast_output_dict['AST_MNF1_SOL'])
        except:
            pass
        try:
            os.rename(output_filepath + "cmp1.rdc", output_filepath_prefix + \
                os.path.splitext(ast_output_dict['AST_MNF1_SOL'])[0] + ".rdc")
        except:
            pass
        try:
            os.rename(output_filepath + "cmp2.rst", output_filepath_prefix + \
                ast_output_dict['AST_MNF2_SOL'])
        except:
            pass
        try:
            os.rename(output_filepath + "cmp2.rdc", output_filepath_prefix + \
                os.path.splitext(ast_output_dict['AST_MNF2_SOL'])[0] + ".rdc")
        except:
            pass
        try:
            os.rename(output_filepath + "cmp3.rst", output_filepath_prefix + \
                ast_output_dict['AST_MNF3_SOL'])
        except:
            pass
        try:
            os.rename(output_filepath + "cmp3.rdc", output_filepath_prefix + \
                os.path.splitext(ast_output_dict['AST_MNF3_SOL'])[0] + ".rdc")
        except:
            pass

        #Convert MNF to integer
        print "Converting MNF..."
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL']
        overlay_filepath = output_filepath_prefix + \
            ast_output_dict['AST_OVERLAY_100']
        idrisi_cmd = overlay_filepath + "*1*1*100*1*" + input_filepath + "*n"
        ###IDRISI32.RunModule('INITIAL',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL']
        output_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL_I']
        idrisi_cmd = "3*" + input_filepath + "*" + overlay_filepath + "*" + \
                output_filepath
        ###IDRISI32.RunModule('OVERLAY',idrisi_cmd,1,'','','','',1)
        idrisi_cmd = "1*" + output_filepath + "*" + output_filepath + "*1*2*2"
        ###IDRISI32.RunModule('CONVERT',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL']
        output_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL_I']
        idrisi_cmd = "3*" + input_filepath + "*" + overlay_filepath + "*" + \
                output_filepath
        ###IDRISI32.RunModule('OVERLAY',idrisi_cmd,1,'','','','',1)
        idrisi_cmd = "1*" + output_filepath + "*" + output_filepath + "*1*2*2"
        ###IDRISI32.RunModule('CONVERT',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL']
        output_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL_I']
        idrisi_cmd = "3*" + input_filepath + "*" + overlay_filepath + "*" + \
                output_filepath
        ###IDRISI32.RunModule('OVERLAY',idrisi_cmd,1,'','','','',1)
        idrisi_cmd = "1*" + output_filepath + "*" + output_filepath + "*1*2*2"
        ###IDRISI32.RunModule('CONVERT',idrisi_cmd,1,'','','','',1)
            
        #Compute ABF7
        print "Computing ABF7..."
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF1_SOL_ABF7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*9*7*0*1.5*0"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF2_SOL_ABF7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*9*7*0*1.5*0"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF3_SOL_ABF7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*9*7*0*1.5*0"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)

        #Compute MAX3
        print "Computing MAX3..."
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF1_SOL_MAX3']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*13"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF2_SOL_MAX3']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*13"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF3_SOL_MAX3']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*13"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        
        #Compute MED7
        print "Computing MED7..."
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF1_SOL_MED7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*2*7"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF2_SOL_MED7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*2*7"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF3_SOL_MED7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*2*7"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        
        #Compute SLOPE
        print "Computing SLOPE..."
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF1_SOL_SLOPE']
        idrisi_cmd = "1*" + input_filepath + "*" + output_filepath + "*#*p*1"
        ###IDRISI32.RunModule('SLOPE',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF2_SOL_SLOPE']
        idrisi_cmd = "1*" + input_filepath + "*" + output_filepath + "*#*p*1"
        ###IDRISI32.RunModule('SLOPE',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF3_SOL_SLOPE']
        idrisi_cmd = "1*" + input_filepath + "*" + output_filepath + "*#*p*1"
        ###IDRISI32.RunModule('SLOPE',idrisi_cmd,1,'','','','',1)

        #Compute MED7 on SLOPE
        print "Computing MED7 on SLOPE..."
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL_SLOPE']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF1_SOL_SLOPE_MED7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*2*7"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL_SLOPE']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF2_SOL_SLOPE_MED7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*2*7"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL_SLOPE']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF3_SOL_SLOPE_MED7']
        idrisi_cmd = input_filepath + "*" + output_filepath + "*2*7"
        ###IDRISI32.RunModule('FILTER',idrisi_cmd,1,'','','','',1)

        #Compute VFI7
        print "Computing VFI7..."
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF1_SOL_I']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF1_SOL_I_VFI7']
        idrisi_cmd = "4*" + input_filepath + "*" + output_filepath + "*#*7"
        ###IDRISI32.RunModule('TEXTURE',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF2_SOL_I']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF2_SOL_I_VFI7']
        idrisi_cmd = "4*" + input_filepath + "*" + output_filepath + "*#*7"
        ###IDRISI32.RunModule('TEXTURE',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF3_SOL_I']
        output_filepath = output_filepath_prefix +  \
            ast_output_dict['AST_MNF3_SOL_I_VFI7']
        idrisi_cmd = "4*" + input_filepath + "*" + output_filepath + "*#*7"
        ###IDRISI32.RunModule('TEXTURE',idrisi_cmd,1,'','','','',1)
        
        #Compute split window mean
        print "Computing split window mean..."
        input_filepath = output_filepath_prefix + \
            ast_input_dict['AST_B13']
        overlay_filepath = output_filepath_prefix + \
            ast_input_dict['AST_B14']
        output_filepath = output_filepath_prefix + \
            ast_output_dict['AST_TEMP']
        idrisi_cmd = "1*" + input_filepath + "*" + overlay_filepath + "*" + \
                output_filepath
        ###IDRISI32.RunModule('OVERLAY',idrisi_cmd,1,'','','','',1)
        overlay_filepath = output_filepath_prefix + \
            ast_output_dict['AST_OVERLAY_2']
        idrisi_cmd = overlay_filepath + "*1*1*2*1*" + input_filepath + "*n"
        ###IDRISI32.RunModule('INITIAL',idrisi_cmd,1,'','','','',1)
        input_filepath = output_filepath_prefix + \
            ast_output_dict['AST_TEMP']
        output_filepath = output_filepath_prefix + \
            ast_output_dict['AST_B1314_SW']
        idrisi_cmd = "3*" + input_filepath + "*" + overlay_filepath + "*" + \
                output_filepath
        ###IDRISI32.RunModule('OVERLAY',idrisi_cmd,1,'','','','',1)

        #Standardize datasets
        print "Standardizing data sets..."
        ###AST_cloudmask = output_path + target_plot + "_" + \
        ###    os.path.basename(ast_output_dict["AST_CLOUDMASK"])
        for entry in ast_output_dict:
            if "CLOUDMASK" not in entry and "B030201" not in entry and \
                "RGF" not in entry and "OVERLAY" not in entry and \
                "TEMP" not in entry:
                input_filepath = output_filepath_prefix + ast_output_dict[entry]
                output_filepath = output_filepath_prefix + \
                    os.path.splitext(ast_output_dict[entry])[0] + "_S.rst"
                idrisi_cmd = input_filepath + "*" + output_filepath
                ###IDRISI32.RunModule('STANDARD',idrisi_cmd,1,'','','','',1)
        
        for entry in dem_dict:
            input_filepath = output_filepath_prefix + dem_dict[entry]
            output_filepath = output_filepath_prefix + \
                os.path.splitext(dem_dict[entry])[0] + "_S.rst"
            idrisi_cmd = input_filepath + "*" + output_filepath
            ###IDRISI32.RunModule('STANDARD',idrisi_cmd,1,'','','','',1)
        
        #Make raster group files
        #MNF_SOL_S datasets
        print "Making some raster group files..."
        rgf_mnf_sol_s_filepath = output_filepath_prefix + \
            ast_output_dict['AST_MNF_SOL_S_RGF']
        rgf_file = open(rgf_mnf_sol_s_filepath, "w")
        rgf_file.write("3\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF1_SOL'])[0] + "_S\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF2_SOL'])[0] + "_S\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF3_SOL'])[0] + "_S\n")
        rgf_file.close()
        
        #Other ASTER datasets
        file_counter = 0
        file_content = []
        for entry in ast_output_dict:
            if "CLOUDMASK" not in entry and "B030201" not in entry and \
            "AST_MNF1_SOL" is not entry and "AST_MNF2_SOL" is not entry and \
            "AST_MNF3_SOL" is not entry and "RGF" not in entry and \
            "OVERLAY" not in entry and "TEMP" not in entry:
                file_counter = file_counter + 1
                file_content.append(output_filepath_prefix + \
                    os.path.splitext(ast_output_dict[entry])[0] + "_S\n")
        rgf_ast_s_classification_filepath = output_filepath_prefix + \
            ast_output_dict['AST_S_CLASSIFICATION_RGF']
        rgf_file = open(rgf_ast_s_classification_filepath, "w")
        rgf_file.write(str(file_counter) + "\n")
        for line in sorted(file_content):
            rgf_file.write(line)
        rgf_file.close()
        
        #All ASTER datasets (inkl. MNF_SOL_S files)
        rgf_ast_all_s_classification_filepath = output_filepath_prefix + \
            ast_output_dict['AST_ALL_S_CLASSIFICATION_RGF']
        rgf_file = open(rgf_ast_all_s_classification_filepath, "w")
        rgf_file.write(str(file_counter+3) + "\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF1_SOL'])[0] + "_S\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF2_SOL'])[0] + "_S\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF3_SOL'])[0] + "_S\n")
        for line in sorted(file_content):
            rgf_file.write(line)
        rgf_file.close()
        
        #Other ASTER and DEM datasets
        for entry in dem_dict:
            file_counter = file_counter + 1
            file_content.append(output_filepath_prefix + \
                os.path.splitext(dem_dict[entry])[0] + "_S\n")
        rgf_ast_dem_s_classification_filepath = output_filepath_prefix + \
            ast_output_dict['AST_DEM_S_CLASSIFICATION_RGF']
        rgf_file = open(rgf_ast_dem_s_classification_filepath, "w")
        rgf_file.write(str(file_counter) + "\n")
        for line in sorted(file_content):
            rgf_file.write(line)
        rgf_file.close()

        #All ASTER and DEM datasets (inkl. MNF_SOL_S files)
        rgf_ast_all_dem_s_classification_filepath = output_filepath_prefix + \
            ast_output_dict['AST_ALL_DEM_S_CLASSIFICATION_RGF']
        rgf_file = open(rgf_ast_all_dem_s_classification_filepath, "w")
        rgf_file.write(str(file_counter+3) + "\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF1_SOL'])[0] + "_S\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF2_SOL'])[0] + "_S\n")
        rgf_file.write(output_filepath_prefix + \
            os.path.splitext(ast_output_dict['AST_MNF3_SOL'])[0] + "_S\n")
        for line in sorted(file_content):
            rgf_file.write(line)
        rgf_file.close()

        
        #Clean up a little bit
        print "Cleaning up a little bit..."
        misc_output_path = output_path + target_plot + "_misc" + os.sep
        if not os.path.exists(misc_output_path):
            os.mkdir(misc_output_path)
        files=locate("*.*", "*", output_path)
        for file in files:
            if "_S." not in file and "osm_mrg_epsg-32737_123" not in file and \
                "030201" not in file and "SEGTRAIN" not in file:
                try:
                    shutil.move(file, misc_output_path) 
                except:
                    pass
        
        #Compute segmentation based on AST_MNF_SOL_SCM dataset
        print "Computing segmentation..."
        weight_filepath = output_filepath_prefix + \
            "SEGMENTATION_WEIGHTS.txt"
        weight_file = open(weight_filepath, "w")
        weight_file.write("3 \n")
        weight_file.write("0.20 \n")
        weight_file.write("0.70 \n")
        weight_file.write("0.10 \n")
        weight_file.close()
        idrisi_cmd = rgf_mnf_sol_s_filepath + "*" + \
            output_filepath_prefix + "MNF_SOL_S_207010_7030" + \
            "*" + "3" + "*" + \
            "200, 180, 160, 140, 130, 120, 110, 100, " + \
            "90, 80, 70, 60, 50, 40, 30, 20, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1" + \
            "*" + weight_filepath + "*" + "0.70" + "*" + "0.30"
        ###IDRISI32.RunModule('SEGMENTATION',idrisi_cmd,1,'','','','',1)
        
        segmentation_files=locate("*SEGTRAIN.vct", "*", output_path)
        for segmentation_filepath in segmentation_files:
            #Extract signature based on manually defined segmentations
            print "Extracting signature..."
            #Remove existing sig and spf files
            sig_files=locate("*.sig", "*", output_path)
            for sig_file in sig_files:
                os.remove(sig_file)
            spf_files=locate("*.spf", "*", output_path)
            for spf_file in spf_files:
                os.remove(spf_file)
            #Create signature group file
            metadata = read_metadata(\
                    os.path.splitext(segmentation_filepath)[0] + ".vdc")
            siggroup_filepath = os.path.splitext(\
                segmentation_filepath)[0] + "_SIGNATURE.sgf"
            signame_file = open(siggroup_filepath, "w")
            for code in metadata["codes"]:
                signame_file.write(str(code[4:].split(":")[0].strip()) + " ")
                signame_file.write(output_filepath_prefix + \
                    str(code[4:].split(":")[1].strip()) + "\n")
            signame_file.close()
            idrisi_cmd = "v*" + segmentation_filepath + "*50*" + \
                rgf_ast_all_s_classification_filepath + "*" + siggroup_filepath
            IDRISI32.RunModule('MAKESIG',idrisi_cmd,1,'','','','',1)
            #Move sig and spf files from IDRISI working directory to output path
            sig_files=locate("*.sig", "*", idrisi_working_directory)
            for sig_file in sig_files:
                shutil.move(sig_file, output_path)
            spf_files=locate("*.spf", "*", idrisi_working_directory)
            for spf_file in spf_files:
                shutil.move(spf_file, output_path)

            #MAXLIKE
            print "Computing MAXLIKE..."
            signame_file = open(siggroup_filepath, "w")
            signame_file.write(str(len(metadata["codes"])) + "\n")
            for code in metadata["codes"]:
                signame_file.write(output_filepath_prefix + \
                    str(code[4:].split(":")[1].strip()) + "\n")
            signame_file.close()
            maxlike_filepath = os.path.splitext(\
                segmentation_filepath)[0] + "_MAXLIKE"
            idrisi_cmd = maxlike_filepath + "*" + siggroup_filepath + "*0.0*1"
            ###IDRISI32.RunModule('MAXLIKE',idrisi_cmd,1,'','','','',1)
            segmentation_filepath_rst = \
                os.path.splitext(segmentation_filepath)[0] + ".rst"
            maxlike_filepath_mode = os.path.splitext(\
                segmentation_filepath)[0] + "_MAXLIKE_MODE.rst"
            idrisi_cmd = segmentation_filepath_rst + "*" + maxlike_filepath + \
                "*3*5*" + maxlike_filepath_mode
            ###IDRISI32.RunModule('EXTRACT',idrisi_cmd,1,'','','','',1)
            
            #KNN
            print "Computing KNN..."
            knn_filepath = os.path.splitext(\
                segmentation_filepath)[0] + "_KNN"
            idrisi_cmd = siggroup_filepath + "*" + knn_filepath + \
                "*100*500*none"
            ###IDRISI32.RunModule('KNN',idrisi_cmd,1,'','','','',1)
            knn_filepath_mode = os.path.splitext(\
                segmentation_filepath)[0] + "_KNN_MODE.rst"
            idrisi_cmd = segmentation_filepath_rst + "*" + knn_filepath + \
                "*3*5*" + knn_filepath_mode
            ###IDRISI32.RunModule('EXTRACT',idrisi_cmd,1,'','','','',1)
            
            #BAYCLASS
            print "Computing BAYCLASS..."
            bayclass_filepath = os.path.splitext(\
                segmentation_filepath)[0] + "_BAYCLASS_"
            idrisi_cmd = bayclass_filepath + "*" + siggroup_filepath + "*1"
            ###IDRISI32.RunModule('BAYCLASS',idrisi_cmd,1,'','','','',1)
            harden_filepath = output_filepath_prefix + "harden.txt"
            harden_file = open(harden_filepath, "w")
            rgf_file = open(os.path.splitext(\
                segmentation_filepath)[0] + "_BAYCLASS_.rgf")
            first_line = True
            for line in rgf_file:
                if first_line == True:
                    harden_file.write(line)
                    first_line = False
                else:
                    harden_file.write(output_path + line + "0\n")
            rgf_file.close()
            harden_file.close()
            idrisi_cmd = "#*" + bayclass_filepath + "*4*" + harden_filepath
            ###IDRISI32.RunModule('MDCHOICE',idrisi_cmd,1,'','','','',1)
            
            
            #MAHALCLASS
            print "Computing MAHALCLASS..."
            mahalclass_filepath = os.path.splitext(\
                segmentation_filepath)[0] + "_MAHALCLASS_"
            idrisi_cmd = siggroup_filepath + "*" + mahalclass_filepath
            ###IDRISI32.RunModule('MAHALCLASS',idrisi_cmd,1,'','','','',1)
            harden_filepath = output_filepath_prefix + "harden.txt"
            harden_file = open(harden_filepath, "w")
            rgf_file = open(os.path.splitext(\
                segmentation_filepath)[0] + "_MAHALCLASS_.rgf")
            first_line = True
            for line in rgf_file:
                if first_line == True:
                    harden_file.write(line)
                    first_line = False
                else:
                    harden_file.write(output_path + line + "0\n")
            rgf_file.close()
            harden_file.close()
            idrisi_cmd = "#*" + mahalclass_filepath + "*4*" + harden_filepath
            ###IDRISI32.RunModule('MDCHOICE',idrisi_cmd,1,'','','','',1)

            #BELCLASS
            print "Computing BELCLASS..."
            belclass_filepath = os.path.splitext(\
                segmentation_filepath)[0] + "_BELCLASS_"
            idrisi_cmd = "1*" + belclass_filepath + "*" + \
                siggroup_filepath + "*1"
            ###IDRISI32.RunModule('BELCLASS',idrisi_cmd,1,'','','','',1)
            harden_filepath = output_filepath_prefix + "harden.txt"
            harden_file = open(harden_filepath, "w")
            rgf_file = open(os.path.splitext(\
                segmentation_filepath)[0] + "_BELCLASS_.rgf")
            first_line = True
            for line in rgf_file:
                if first_line == True:
                    harden_file.write(line)
                    first_line = False
                else:
                    harden_file.write(output_path + line + "0\n")
            rgf_file.close()
            harden_file.close()
            idrisi_cmd = "#*" + belclass_filepath + "*4*" + harden_filepath
            ###IDRISI32.RunModule('MDCHOICE',idrisi_cmd,1,'','','','',1)

            #FUZCLASS
            print "Computing FUZCLASS..."
            fuzclass_filepath = os.path.splitext(\
                segmentation_filepath)[0] + "_FUZCLASS_"
            idrisi_cmd = siggroup_filepath + "*2.5*1*" + fuzclass_filepath
            IDRISI32.RunModule('FUZCLASS',idrisi_cmd,1,'','','','',1)
            harden_filepath = output_filepath_prefix + "harden.txt"
            harden_file = open(harden_filepath, "w")
            rgf_file = open(os.path.splitext(\
                segmentation_filepath)[0] + "_FUZCLASS_.rgf")
            first_line = True
            for line in rgf_file:
                if first_line == True:
                    harden_file.write(line)
                    first_line = False
                else:
                    harden_file.write(output_path + line + "0\n")
            rgf_file.close()
            harden_file.close()
            idrisi_cmd = "#*" + fuzclass_filepath + "*4*" + harden_filepath
            IDRISI32.RunModule('MDCHOICE',idrisi_cmd,1,'','','','',1)
            
            os.sys.exit()

        #Create idrisi environment
        idrisi_env = open(output_path + target_plot + ".env", "w")
        idrisi_env.write(output_path + "\n")
        idrisi_env.write(output_path + target_plot + "_misc\n")
        idrisi_env.close()
        gc.collect()
    
    print
    print "...finished."
    
if __name__ == '__main__':
    main()
