"""This program orders the images from the given directory by date 
into a new order structure year-month.

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
from PIL import Image
from PIL.ExifTags import TAGS
import os
import re 
import shutil
from optparse import OptionParser

__author__ = "Spaska Froteva<spaska.forteva@geo.uni-marburg.de>"
__version__ = "2013-08-08"
__license__ = "GNU GPL, see http://www.gnu.org/licenses/"

""" Read from the console the main directory 
"""
parser = OptionParser()
parser.add_option('-s', '--source', 
                  dest = "source", 
                  default = " /home/eikistations/ei_data_kilimanjaro/processing/tlc/incoming/",
                  )
parser.add_option('-d', '--dest', 
                  dest = "dest", 
                  default = " /home/eikistations/ei_data_kilimanjaro/processing/tlc/processing",
                  )

(options, args) = parser.parse_args()

src = options.source
dest = options.dest
years = ('2011', '2012', '2013')
months = ('01', '02', '03', '04', '05', '06', '07', '08', '09','10','11','12')

"""def ensure_dirs():
    for year in years:
        make_sure_path_exists(dest + "" + year)
        for month in months:
            make_sure_path_exists(dest + "" + year + "/" + month + "_" + year)
"""


def make_sure_path_exists(path):
    try:
        if not os.path.exists(path): 
            os.makedirs(path)
    except OSError as exception:
        if OSError.errno == 2:
            pass
        else:
            raise      

def get_exif(fn):
    ret = {}
    image = Image.open(fn)
    from PIL.ExifTags import TAGS as id_names
    image_tags = image._getexif()
    creation_date = image_tags[36867]
    creation_date = re.sub (':', '-', creation_date)
    creation_date = re.sub (' ', '_', creation_date)
    return creation_date  

def get_year_exif(fn):
    ret = {}
    image = Image.open(fn)
    from PIL.ExifTags import TAGS as id_names
    image_tags = image._getexif()
    creation_date = image_tags[36867]
    
    creation_date = split(creation_date, " ")
    creation_date = split (creation_date[0], ':')
    return creation_date
   
     
def orderFiles(sourcePath, file):
    srcPath = sourcePath + "/" + file
    date = get_exif(srcPath)
    d = get_year_exif(srcPath)
    fileName = split(file, ".")
    destPath = dest + d[0] + "/" + d[1] + "_" + d[0] + "/" + date  + "_0000_.JPG"
    make_sure_path_exists(dest + d[0] + "/" + d[1] + "_" + d[0])
    if not (os.path.exists(destPath)):
        shutil.copyfile(srcPath, destPath)
             
def main():
    '''Call the file rename recursively

    Args:
        src: Source directory for the recursive search
    '''
    try:
        
        for sourcePath, dirs, files in os.walk(src):
            if len(files) > 0:
                for file in files:
                    orderFiles(sourcePath,file)
            #if len(meinDirs) > 0:
            #    for dir in meinDirs:
            #        orderFiles(mainRoot + dir)
            
                
    except Exception as inst:
        print "An error occured."
        print "Some details:"
        print "Exception type: " , type(inst)
        print "Exception args: " , inst.args
        print "Exception content: " , inst 
    
    
main()
    
    
