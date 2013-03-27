################################################################################
##  
##  This program visualizes the station network of SP1.
##  
################################################################################
##
##  Copyright (C) 2012 Tim Appelhans, Thomas Nauss
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

library(sp)
library(rgdal)
library(plotKML)
library(raster)
library(RColorBrewer)
library(plotGoogleMaps)
library(evaluate)

setwd("C:/Users/tnauss/Desktop/phase_02/abbildungen/R")

projnew <- CRS("+proj=longlat +ellps=WGS84 +towgs84=-160,-6,-302,0,0,0,0")
#projraster <- "+proj=latlon +datum=WGS84"

stations <- read.csv("stations_master_20120912_proposal.csv",
                     stringsAsFactors = F,
                     sep = ";")
coordinates(stations) <- c("Easting", "Northing")
stations@proj4string@projargs <- "+proj=utm +zone=37 +south +ellps=clrk80 +units=m +south"
stationssp <- spTransform(stations, projnew)

station.basic <- subset(stationssp, stationssp@data$Keyword == "Basic")
station.enhanced <- subset(stationssp, stationssp@data$Keyword == "Enhanced")
station.aws <-  subset(stationssp, stationssp@data$Keyword == "AWS")
station.throughfall <- subset(stationssp, stationssp@data$Keyword == "Throughfall")
station.dslr <- subset(stationssp, stationssp@data$Keyword == "DSLR")
station.cbt <- subset(stationssp, stationssp@data$Keyword == "CBT")


map.basic <- plotGoogleMaps(station.basic, 
                            layerName = "Basic",
                            iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/Ta_200_in.png',
                            add = T)

map.enhanced <- plotGoogleMaps(station.enhanced,
                               previousMap=map.basic,
                               layerName = "Enhanced",
                               iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/P_RT_NRT_in.png',
                               add = T)

map.aws <- plotGoogleMaps(station.aws, 
                          previousMap=map.enhanced, layerName = "AWS",
                          iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/SWDR_300_in.png',
                          add = T)

map.throughfall <- plotGoogleMaps(station.throughfall, 
                                  previousMap=map.aws, layerName = "Throughfall",
                                  iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/TF_in.png',
                                  add = T)

map.dslr <- plotGoogleMaps(station.dslr, 
                           previousMap=map.throughfall, layerName = "DSLR",
                           iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/tlc_in.png',
                           add = T)

map.cbt <- plotGoogleMaps(station.cbt, 
                          previousMap=map.dslr, layerName = "Nubiscan",
                          iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/nbs_pl.png',
                          add = F,
                          filename = "sp1.htm")


# Temperature_inst <- subset(stationssp, stationssp@data$Ta_200 == "INSTALLED")
# Humidity_inst <- subset(stationssp, stationssp@data$rH_200 == "INSTALLED")
# Radiation_inst <- subset(stationssp, stationssp@data$SWDR_300 == "INSTALLED")
# PAR_inst <- subset(stationssp, stationssp@data$PAR == "INSTALLED")
# Wind_inst <- subset(stationssp, stationssp@data$WD == "INSTALLED")
# Precipitation_inst <- subset(stationssp, stationssp@data$P_RT_NRT == "INSTALLED")
# Fog_inst <- subset(stationssp, stationssp@data$F_RT_NRT == "INSTALLED")
# Throughfall_inst <- subset(stationssp, stationssp@data$TF == "INSTALLED")
# Photo_inst <- subset(stationssp, stationssp@data$TLC == "INSTALLED")
# Radiation_pl <- subset(stationssp, stationssp@data$SWDR_300 == "OCT_2012")
# Wind_pl <- subset(stationssp, stationssp@data$WD == "OCT_2012")
# Precipitation_pl <- subset(stationssp, stationssp@data$P_RT_NRT == "OCT_2012")
# Fog_pl <- subset(stationssp, stationssp@data$F_RT_NRT == "OCT_2012")
# Throughfall_pl <- subset(stationssp, stationssp@data$TF == "OCT_2012")
#  Radiation_pl <- subset(stationssp, stationssp@data$SWDR_300 == "OCT_2012")
#  Wind_pl <- subset(stationssp, stationssp@data$WD == "OCT_2012")
#  Precipitation_pl <- subset(stationssp, stationssp@data$P_RT_NRT == "OCT_2012")
#  Fog_pl <- subset(stationssp, stationssp@data$F_RT_NRT == "OCT_2012")
#  Throughfall_pl <- subset(stationssp, stationssp@data$TF == "OCT_2012")
# Photo_pl <- subset(stationssp, stationssp@data$TLC == "2nd_PHASE")
# EVapotranspiration_pl <- subset(stationssp, stationssp@data$ET == "2nd_PHASE")
# CloudTemperature_pl <- subset(stationssp, stationssp@data$NBS == "2nd_PHASE")

# Wnd_inst <- plotGoogleMaps(Wind_inst, layerName = "Wind direction & speed: INSTALLED",
#                            iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/WD_in.png',
#                            add = T)
# cam_inst <- plotGoogleMaps(Photo_inst, previousMap=Wnd_inst, layerName = "Time lapse camera: INSTALLED",
#                            iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/tlc_in.png',
#                            add = T)
# Par_inst <- plotGoogleMaps(PAR_inst, previousMap=cam_inst, layerName = "Photosynthetic active radiation: INSTALLED",
#                            iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/PAR_in.png',
#                            add = T)
# SWDR_inst <- plotGoogleMaps(Radiation_inst, previousMap=Par_inst, layerName = "Global radiation: INSTALLED",
#                             iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/SWDR_300_in.png',
#                             add = T)
# FRT_inst <- plotGoogleMaps(Fog_inst, previousMap=SWDR_inst, layerName = "Fog: INSTALLED",
#                            iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/F_RT_NRT_in.png',
#                            add = T)
# TF_inst <- plotGoogleMaps(Throughfall_inst, previousMap=FRT_inst, layerName = "Through-fall: INSTALLED",
#                           iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/TF_in.png',
#                           add = T)
# PRT_inst <- plotGoogleMaps(Precipitation_inst, previousMap=TF_inst, layerName = "Precipitation: INSTALLED",
#                            iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/P_RT_NRT_in.png',
#                            add = T)
# rH_inst <- plotGoogleMaps(Humidity_inst, previousMap=PRT_inst, layerName = "relative Humidity: INSTALLED",
#                           iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/rH_200_in.png',
#                           add = T)
# Ta_inst <- plotGoogleMaps(Temperature_inst, previousMap=rH_inst, layerName = "Air temperature: INSTALLED",
#                           iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/Ta_200_in.png', 
#                           add = T)
# 
# Wnd_pl <- plotGoogleMaps(Wind_pl, previousMap=Ta_inst, layerName = "Wind direction & speed: OCT_2012",
#                          iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/WD_pl.png',
#                          add = T)
# cam_pl <- plotGoogleMaps(Photo_pl, previousMap=Wnd_pl, layerName = "Time lapse camera: OCT_2012",
#                          iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/tlc_pl.png',
#                          add = T)
# # Par_pl <- plotGoogleMaps(PAR_pl, previousMap=cam_pl, , layerName = "Photosynthetic active radiation: OCT_2012",
# #                       iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/PAR_pl.png',
# #                       add = T)
# SWDR_pl <- plotGoogleMaps(Radiation_pl, previousMap=cam_pl, layerName = "Global radiation: OCT_2012",
#                           iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/SWDR_300_pl.png',
#                           add = T)
# FRT_pl <- plotGoogleMaps(Fog_pl, previousMap=SWDR_pl, layerName = "Fog: OCT_2012",
#                          iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/F_RT_NRT_pl.png',
#                          add = T)
# TF_pl <- plotGoogleMaps(Throughfall_pl, previousMap=FRT_pl, layerName = "Through-fall: OCT_2012",
#                         iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/TF_pl.png',
#                         add = T)
# PRT_pl <- plotGoogleMaps(Precipitation_pl, previousMap=TF_pl, layerName = "Precipitation: OCT_2012",
#                          iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/P_RT_NRT_pl.png',
#                          add = T)
# # rH_pl <- plotGoogleMaps(Humidity_pl, previousMap=PRT_pl, layerName = "relative Humidity: OCT_2012",
# #                      iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/rH_200_pl.png',
# #                      add = T)
# # Ta_pl <- plotGoogleMaps(Temperature_pl, previousMap=rH_pl, layerName = "Air temperature: OCT_2012",
# #                      iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/Ta_200_pl.png', 
# #                      add = T)
# et_pl <- plotGoogleMaps(EVapotranspiration_pl, previousMap=PRT_pl, layerName = "Evapotranspiration: 2nd_PHASE",
#                         iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/et_pl.png',
#                         add = T)
# nbs_pl <- plotGoogleMaps(CloudTemperature_pl, previousMap=et_pl, layerName = "Cloud temperature: 2nd_PHASE",
#                          iconMarker = 'http://www.staff.uni-marburg.de/~appelhat/mapicons/nbs_pl.png', 
#                          add = F, filename = "parameters_SP1.htm")