"""This programm renames the images from the given directory. 
The name have to be created by datetime from the meta data datetime exif
Copyright (C) 2013, Spaska forteva

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
reports to spaska.forteva@geo.uni-marburg.de
"""
from string import split

__author__ = "Spaska Froteva<spaska.forteva@geo.uni-marburg.de>"
__version__ = "2013-08-08"
__license__ = "GNU GPL, see http://www.gnu.org/licenses/"

import os
import re 
from PIL import Image
from PIL.ExifTags import TAGS
from optparse import OptionParser

""" Read from the console the directory with the images
"""
parser = OptionParser()
parser.add_option('-d', '--dir', 
                  dest = "dir", 
                  default = "/home/eibestations/ei_data_kilimanjaro/processing/tic/incoming/",
                  )

(options, args) = parser.parse_args()

src = options.dir

print 'Module: be_process_level0100'
print 'Version: ' + __version__
print 'Author: ' + __author__
print 'License: ' + __license__
print   


def get_exif(fn):
    ret = {}
    image = Image.open(fn)
    from PIL.ExifTags import TAGS as id_names
    image_tags = image._getexif()
    creation_date = image_tags[36867]
    creation_date = re.sub (':', '-', creation_date)
    creation_date = re.sub (' ', '_', creation_date)
    return creation_date  
   
def rename_files(root, files):
    '''Matching filename to datetime as name

    Args:
        root: Root directory 
        files: List with the files
    '''
    try:
        for filename in files:
           newFileName = get_exif(root + "/" + filename)
           if not os.path.exists(newFileName):
               os.rename(root + "/" + filename, root + "/" + newFileName + "_0000_.JPG")

    except Exception as inst:
        print "An error occured with the following dataset."
        print "Some details:"
        print "Exception type: " , type(inst)
        print "Exception args: " , inst.args
        print "Exception content: " , inst     


def main(src):
    '''Call the file rename recursively

    Args:
        src: Source directory for the recursive search
    '''
    try:
        for mainRoot, meinDirs, mainFiles in os.walk(src):
            if len(mainFiles) > 0:
                rename_files(mainRoot, mainFiles)
            if len(meinDirs) > 0:
                for dir in meinDirs:
                    main(mainRoot + dir)
            
                
    except Exception as inst:
        print "An error occured with the following dataset."
        print "Some details:"
        print "Exception type: " , type(inst)
        print "Exception args: " , inst.args
        print "Exception content: " , inst     
            

main(src)
