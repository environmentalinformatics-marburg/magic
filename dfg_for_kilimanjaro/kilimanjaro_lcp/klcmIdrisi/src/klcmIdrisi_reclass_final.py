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
    
    act_filepath = args[0]
    
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

    return act_filepath
    
def find_strings(string, content):
    #Taken from Karl Knechtel@http://stackoverflow.com/
    #Index: "find-all-occurrences-of-a-substring-in-python"
    occurence = 0
    while True:
        occurence = string.find(content, occurence)
        if occurence == -1: return
        yield occurence
        occurence += len(content)

        
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
        if ".rst" in filepath.lower():
            filepath = os.path.splitext(filepath)[0] + ".rdc"
        elif ".vct" in filepath.lower():
            filepath = os.path.splitext(filepath)[0] + ".vdc"
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
   
   '''
    print
    print 'Module: klcmIdrisi'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print   
    
    #Get command line arguments
    act_filepath = command_line_parsing()
    
    IDRISI32 = win32com.client.Dispatch('IDRISI32.IdrisiAPIServer')
               
    #Reclass dataset to match final land cover classes
    metadata = read_metadata(act_filepath)
    klcc_final = {}
    klcc_final_file =  open("klcc_final.txt")
    for line in klcc_final_file:
        key, val = line.split(":")
        klcc_final[key.strip()] = int(val)
    klcc_final_file.close()
    new_codes = []
    for code in metadata["codes"]:
        value, lc = code.split(":")
        lc = lc.strip()
        max_compare = 0
        act_compare = 0
        for entry in klcc_final:
            if entry.lower() in lc.lower():
                for i in range(len(entry)):
                    if i < len(lc):
                        if entry.lower()[i] == lc.lower()[i]:
                            act_compare = act_compare + 1
                if max_compare < act_compare:
                    max_compare = act_compare
                    max_entry = entry
        if "grassland_scattered_trees" in code.lower() or \
            "grassland_dense_trees" in code.lower():
            max_entry = "Grassland_trees"
        new_codes.append([int(value[4:]), \
        klcc_final[max_entry], lc.strip(), max_entry])
    reclass_pattern = ''
    legend_entries = {}
    legend_metadata = {}
    linestart_1 = "code      "
    linestart_2 = "code     "
    for entry in new_codes:
        legend_entries[entry[1]] = 1
        if entry[1] < 10:
            linestart = linestart_1
        else:
            linestart = linestart_2
        legend_metadata[entry[1]] = linestart + \
            str(entry[1]) + " : " + entry[3]
        reclass_pattern = reclass_pattern + "*" + \
            str(entry[1]) + "*" + str(entry[0]) + "*" + \
            str(entry[0]+1)
    act_filepath_final = os.path.splitext(act_filepath)[0] + "_final"
    idrisi_cmd = "i*" + act_filepath + \
        "*" + act_filepath_final + \
        "*2" + reclass_pattern + "*-9999*1"
    success = IDRISI32.RunModule('RECLASS', idrisi_cmd, 1, '', '', '', '', 1)
    meta_file = open(\
        act_filepath_final + ".rdc", "r")
    meta_content = meta_file.readlines()
    meta_file.close()
    meta_file = open(\
        act_filepath_final + ".rdc", "w")
    wrote_legend = False
    for line in meta_content:
        if wrote_legend == False:
            if "legend cats" not in line:
                meta_file.write(line)
            else:
                meta_file.write("legend cats : " + \
                    str(len(legend_entries)) + "\n")
                for code in legend_metadata:
                    meta_file.write(legend_metadata[code] + "\n")
                wrote_legend = True
        else:
            continue
        gc.collect()
    
    print
    print "...finished."
    
if __name__ == '__main__':
    main()
