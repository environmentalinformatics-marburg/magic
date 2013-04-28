"""ZIP all files in a folder.
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
__version__ = "2013-04-28"
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
      help="Path to the input folder.", metavar="string")
    parser.add_option("-o", nargs=1, dest="output_path",
      help="Path to the output folder.", metavar="string")
    parser.add_option("-e", nargs=1, dest="exclude",
      help="Pattern of files to be excluded.", metavar="string")
    (options, args) = parser.parse_args()

    if options.input_osm_path != None: 
        input_path = options.input_osm_path
    else:
        input_osm_path = os.getcwd()+os.sep
    if options.output_path != None: 
        output_path = options.output_path
    else:
        output_path = os.getcwd()+os.sep
    if options.exclude != None: 
        exclude = options.exclude
    else:
        exclude = None
    return input_path, output_path, exclude

    
def main():
    '''Concat Idrisi files
    '''
    print
    print 'Module: zipping'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print   
    
    #Get command line arguments
    input_path, output_path, exclude = command_line_parsing()
        
    if not os.path.exists(output_path):
            os.mkdir(output_path)

    #Get datasets
    datasets=locate("*.rst", "*", input_path)

    #Process data for each osm plot region
    zip_files = {}
    for dataset in datasets:
        #print 
        #print "Processing dataset: " + dataset
        if os.path.split(dataset)[0] in zip_files:
            zip_files[os.path.split(dataset)[0]].append(dataset)
        else:
            zip_files[os.path.split(dataset)[0]] = [dataset]

    for entry in zip_files:
        print entry
        act_folder = os.path.split(entry)[1]
        print 
        print "Processing folder: " + act_folder
        zip_cmd = []
        for item in zip_files[entry]:
            if exclude not in item:
                zip_cmd.append(item)
        if len(zip_cmd) > 0:
            zip_cmd = "7z a -mx=9 " + output_path + os.sep + act_folder + ".7z " + \
                " ".join(zip_cmd)
            os.system(zip_cmd)
        
    print
    print "...finished."
    
if __name__ == '__main__':
    main()
