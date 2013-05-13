'''
Created on May 2, 2013

@author: Spaska Forteva
'''
"""This program counts all EEMUS, AEMU, CEMU rows(data records) from the directory
processing/plots/be/. You can write parameters per console 
for example: calc_number_rows.py -y 2013 -f 05.dat -d SEW.
If you not give this, it will be used per default

Copyright (C) 2013 Spaska Forteva

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
reports to sforteva@yahoo.de
"""

__author__ = "Spaska Forteva <sforteva@yahoo.de>, "
__version__ = "2013-05-09"
__license__ = "GNU GPL, see http://www.gnu.org/licenses/"

import ConfigParser
import fnmatch
import os
from optparse import OptionParser

'''
Read parameters from the console
'''
parser = OptionParser()
parser.add_option('-y', '--year', 
                  dest="year", 
                  default="2013",
                  )
parser.add_option('-f', '--file', 
                  dest="file", 
                  default="05.dat",
                  )
parser.add_option('-s', '--station', 
                  dest="station", 
                  default="HEG",
                  )
parser.add_option('-p', '--path', 
                  dest="path", 
                  default="/home/dogbert/julendat/processing/plots/be/",
                  )

(options, args) = parser.parse_args()

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


def configure(config_file):
    """Reads configuration settings and configure object.
    
    Args:
        config_file: Full path and name of the configuration file.
    """
    config = ConfigParser.ConfigParser()
    config.read(config_file)
    toplevel_processing_plots_path = config.get('repository', \
                                          'toplevel_processing_plots_path')
    project_id = config.get('project','project_id')
    return toplevel_processing_plots_path, project_id

    
def main():
    """Main program function
    """
    print
    print 'Module: calc_number_rows'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print   
    
    station_dataset=sorted(locate("*" + options.file, "*" + options.station +"*", options.path))
    index = 0
    rowNumberCEMU = 0
    dateAEMU = ""
    dateCEMU = ""
    dateEEMU = ""
    indexAEMU = 0
    indexCEMU = 0
    indexEEMU = 0
    rowNumberAEMU = 0
    rowNumberEEMU = 0
    for dataset in station_dataset:
        if index == 0:
            index = index +1
        try:
            fobj = open(dataset, "r")
            
            for line in fobj: 
                
                row = line.find("CEMU") 
                if row > 1:
                    dateCEMU = line.split(',')
                    dateCEMU = dateCEMU[0]
                    dateCEMU = dateCEMU.split("-")
                    dateCEMUNum = int(dateCEMU[0].replace("\"", ""))
                    if dateCEMUNum < options.year :
                        rowNumberCEMU = rowNumberCEMU +1
                    else :
                        #print dateCEMU
                        break
                    if indexCEMU == 0:
                        indexCEMU = indexCEMU +1
                        print "CEMU Start Date"
                        print dateCEMU
                        
                row = line.find("AEMU") 
                if row > 1:
                    dateAEMU = line.split(',')
                    dateAEMU = dateAEMU[0]
                    dateAEMU = dateAEMU.split("-")
                    dateAEMUNum = int(dateAEMU[0].replace("\"", ""))
                    if dateAEMUNum < options.year :
                        rowNumberAEMU = rowNumberAEMU +1
                    else :
                        #print dateAEMU
                        break
                    if indexAEMU == 0:
                        indexAEMU = indexAEMU +1
                        print "AEMU Start Date"
                        print dateAEMU
                        
                row = line.find("EEMU") 
                if row > 1:
                    dateEEMU = line.split(',')
                    dateEEMU = dateEEMU[0]
                    dateEEMU = dateEEMU.split("-")
                    dateEEMUNum = int(dateEEMU[0].replace("\"", ""))
                    if dateEEMUNum < options.year :
                        rowNumberEEMU = rowNumberEEMU +1
                    else :
                        #print dateEEMU
                        break
                    if indexEEMU == 0:
                        indexEEMU = indexEEMU +1
                        print "EEMU Start Date"
                        print dateEEMU
            fobj.close()
        except Exception as inst:
            print "Error."
            print "Some details:"
            print "Filename: " + dataset
            print "Exception type: " , type(inst)
            print "Exception args: " , inst.args
            print "Exception content: " , inst        
    
    print "AEMU"
    print rowNumberAEMU

    
    print "CEMU"
    print rowNumberCEMU
    
    print "EEMU"
    print rowNumberEEMU
    
if __name__ == '__main__':
    main()

