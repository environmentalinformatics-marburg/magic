################################################################################
# This short R script crops one or multiple images in a given folder based on 
# the ImageMagick command-line utilities.
# Author: Florian Detsch, 2014-06-30
################################################################################

# Remove white margins from output images
system("cd out/; for file in *.png; do convert -trim $file $file; done")