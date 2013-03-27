"""Nibble land cover data.
Copyright (C) 2013 Florian Detsch, Tim Appelhans, Thomas Nauss

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
reports to admin@environmentalinformatics-marburg.com
"""

__author__ = "Florian Detsch, Tim Appelhans, Thomas Nauss"
__contact__ = "www.environmentalinformatics-marburg.de"
__version__ = "2013-03-26"
__license__ = "GNU GPL, see http://www.gnu.org/licenses/"


import arcinfo
import arcpy
from arcpy import env
from arcpy.sa import *
import fnmatch
import os

def get_license():
    '''Get ArcGIS license
    
    '''
    try:
        if arcpy.CheckExtension("Spatial") == "Available":
            arcpy.CheckOutExtension("Spatial")
        else:
            raise LicenseError
    except LicenseError:
        print "Spatial license is unavailable"  
    except:
        print arcpy.GetMessages(2)


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


def main():
    """Main program function
    """
    print
    print 'Module: nibble'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print 'Contact: ' + __contact__
    print   
    
    get_license()
    input_path = "E:/plot_landuse/el_fi/"
    output_path = "E:/plot_landuse/el_fi/nibble_output/"
    input_dataset = locate('*250*.tif', '*', input_path)

    for input_raster_filepath in input_dataset:

        #Set workspace and actual filenames/filepathes
        env.workspace = os.path.dirname(output_path)
        input_raster_file = os.path.basename(input_raster_filepath)
        output_raster_file, output_raster_extension = \
            os.path.splitext(input_raster_file)
        output_setnull_file = output_raster_file + "_setnull" + \
                              output_raster_extension
        output_nibble_file = output_raster_file + "_nibble" + \
                             output_raster_extension
        print
        print 'Processing file ' + input_raster_file 
        print
        
        #Set null
        print "Setting null..."
        try:
            os.remove(output_setnull_file)
        except OSError:
            pass
        where_clause = "Class_name = 'cloud' OR Class_name = 'shadow'"
        setnull_raster = SetNull(input_raster_filepath, input_raster_filepath, \
                                 where_clause)

        #Nibble
        print "Nibbleing..."
        try:
            os.remove(output_nibble_file)
        except OSError:
            pass
        nibble_raster = Nibble(input_raster_filepath, setnull_raster, \
                               "DATA_ONLY")

        #Write output
        print "Writing output..."
        setnull_raster.save(output_setnull_file)
        nibble_raster.save(output_nibble_file)
        
if __name__ == '__main__':
    main()
    