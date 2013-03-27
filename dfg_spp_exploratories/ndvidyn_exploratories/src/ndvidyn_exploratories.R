################################################################################
##  
##  This program visualizes the NDVI dynamics for the region of the DFG
##  exploratories.
##  
################################################################################
##
##  Copyright (C) 2012 Meike Kühnlein, Thomas Nauss, Tim Appelhans
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

### Staging area ###############################################################
# Load libraries (echo=FALSE,)
library(lattice)
library(latticeExtra)
library(Kendall)
library(mgcv)
library(gamair)
library(stats)
library(bfast)
library (ggplot2)
library (mapproj)
library (maps)
library (maptools)
library(gridExtra)
library(dtw)
library(tojulian)
# Check operation system and set paths.
actsys <- Sys.info()['sysname']
setwd("D:/temp/2002_2011_ndvi_gp_exploratories_gf")

ndvi.org <- read.csv("2002_2011_ndvi_gp_exploratories_gf.csv",
                      header=TRUE, sep = ";", dec=",")
ndvi.org$date <- as.Date(strptime(paste(ndvi.org$date), "%Y-%m-%d"))


pdf("ndvi.org.pdf")

plot(ndvi.org$A11087 ~ ndvi.org$date,
     type="o", xlab = "Date", ylab = "NDVI", main = "A11087")

plot(ndvi.org$H40123 ~ ndvi.org$date,
     type="o", xlab = "Date", ylab = "NDVI", main = "H40123")

plot(ndvi.org$S520 ~ ndvi.org$date,
     type="o", xlab = "Date", ylab = "NDVI", main = "S520")

dev.off()