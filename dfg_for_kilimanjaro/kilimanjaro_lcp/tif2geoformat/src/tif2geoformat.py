"""Convert geo data sets between format
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

import ConfigParser
import datetime
import fnmatch
import os
import optparse


def locate(pattern, patternpath, root=os.curdir):
    '''Locate files matching filename pattern recursively
    
    This routine is based on the one from Simon Brunning at
    http://code.activestate.com/recipes/499305/ and extended by the patternpath.
     
    Args:
        pattern: Pattern of the filename
        patternpath: Pattern of the filepath
        root: Root directory for the recursive search
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
    parser.add_option("-i", nargs=1, dest="input_path",
      help="Path to the input folder.", metavar="string")
    parser.add_option("-o", nargs=1, dest="output_path",
      help="Path to the output folder.", metavar="string")
    parser.add_option("-c", nargs=1, dest="output_format",
      help="Final output format (gdal ids).", metavar="string")
    (options, args) = parser.parse_args()

    if options.input_path != None: 
        input_path = options.input_path
    else:
        input_path = os.getcwd()+os.sep
    if options.output_path != None: 
        output_path = options.output_path
    else:
        output_path = os.getcwd()+os.sep
    if options.output_format != None: 
        output_format = options.output_format
    else:
        output_format = "GTiff"
    return input_path, output_path, output_format
           
           
def main():
    '''Project tiff files in a directory to a target projection and file type. 
    
    The projection is done by using an os call to gdalwarp. For this, the output
    format is GeoTiff. Afterwards, the projected files are transfered in the
    target projection. This is done because of an error which occured for Idrisi
    RST files as target projection in gdalwarp and can be changed if the error
    no longer occures in a future release.
    '''
    print
    print 'Module: osm2utm37s'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print   
    
    input_path, output_path, output_format = command_line_parsing()
    
    satellite_datasets=locate("*.tif", "*", input_path)

    if not os.path.exists(output_path):
        os.mkdir(output_path)

    # Project all tiff files in the input folder
    for dataset in satellite_datasets:
        print " "
        print "Processing dataset ", dataset
        output_filepath = output_path + os.sep + \
                          os.path.splitext(os.path.basename(dataset))[0] + \
                          "." + output_format
        
        gdal_cmd = "gdal_translate -of " + output_format + " " +\
                       dataset + " " + output_filepath
        os.system(gdal_cmd)
if __name__ == '__main__':
    main()

