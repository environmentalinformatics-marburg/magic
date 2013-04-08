pkgGetAndLoad <- function(pkg, 
                          ...) {
  

################################################################################
##  
##  This is a short function that checks if a certain R package is installed on 
##  the system prior to loading it. The package is being installed automatically 
##  in case it cannot be found on the local hard drive.
##  
##  Parameters are as follows:
##
##  pkg (character): Name of the required R package.
##  ...              Further arguments to be passed.
##
################################################################################
##
##  Copyright (C) 2013 Florian Detsch
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##  Please send any comments, suggestions, criticism, or (for our sake) bug
##  reports to admin@environmentalinformatics-marburg.de
##
################################################################################


  # Install package (optional)
  if (!is.element(pkg, installed.packages()[,1])) {
    install.packages(pkg)
  }
  # Load package
  library(pkg, character.only = TRUE, quietly = TRUE)  
  
}

# ### Call
#
# pkgGetAndLoad(pkg = "latticeExtra")