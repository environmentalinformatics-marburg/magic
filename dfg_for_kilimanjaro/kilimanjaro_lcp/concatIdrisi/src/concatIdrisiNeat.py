"""Concat Idrisi datasets
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
      help="Path to the input folder.", metavar="string")
    parser.add_option("-o", nargs=1, dest="output_path",
      help="Path to the output folder.", metavar="string")
    (options, args) = parser.parse_args()

    if options.input_osm_path != None: 
        input_path = options.input_osm_path
    else:
        input_osm_path = os.getcwd()+os.sep
    if options.output_path != None: 
        output_path = options.output_path
    else:
        output_path = os.getcwd()+os.sep
    return input_path, output_path

    
def find_strings(string, content):
    #Taken from Karl Knechtel@http://stackoverflow.com/
    #Index: "find-all-occurrences-of-a-substring-in-python"
    occurence = 0
    while True:
        occurence = string.find(content, occurence)
        if occurence == -1: return
        yield occurence
        occurence += len(content)
    
        
        
def main():
    '''Concat Idrisi files
    '''
    print
    print 'Module: concatIdrisi'
    print 'Version: ' + __version__
    print 'Author: ' + __author__
    print 'License: ' + __license__
    print   
    
    #Get command line arguments
    input_path, output_path = command_line_parsing()
        
    IDRISI32 = win32com.client.Dispatch('IDRISI32.IdrisiAPIServer')

    if not os.path.exists(output_path):
            os.mkdir(output_path)

    #Get datasets
    satellite_datasets=locate("*.rst", "*", input_path)

    #Process data for each osm plot region
    concat_filepath = {}
    for dataset in satellite_datasets:
        print 
        print "Processing dataset: " + dataset
        #Add file to concatenate group
        occurence = list(find_strings(os.path.splitext(os.path.basename(\
            dataset))[0], "_"))[1]
        if os.path.splitext(os.path.basename(dataset))[0][occurence:] in \
            concat_filepath:
            concat_filepath[os.path.splitext(os.path.basename(\
                dataset))[0][occurence:]].append(dataset)
        else:
            concat_filepath[os.path.splitext(os.path.basename(\
                dataset))[0][occurence:]] = [dataset]

    sort = ["14997", "15002", "15004", "14991"]
    sort = ["20051102", "20081102", "20130224", "20110228"]
    for entry in concat_filepath:
        sorted_content = []
        for item in sort:
            for content in concat_filepath[entry]:
                if item in content:
                    sorted_content.append(concat_filepath[entry].index(\
                        [c for c in concat_filepath[entry] if item in c][0]))

        path, output_file  = os.path.split(concat_filepath[entry][0])
        occurence = list(find_strings(output_file, "_"))[1]
        output_filepath = output_path + os.sep + \
            output_file[0:3] + "C" + output_file[occurence:]
        
        idrisi_cmd = "#*" + str(len(sort)) + "*" + output_filepath + "*2"
        for item in sorted_content:
            idrisi_cmd = idrisi_cmd + "*" + concat_filepath[entry][item]
        print idrisi_cmd
        #IDRISI32.RunModule('CONCAT', idrisi_cmd, 1, '', '', '', '', 1)

        
    print
    print "...finished."
    
if __name__ == '__main__':
    main()
