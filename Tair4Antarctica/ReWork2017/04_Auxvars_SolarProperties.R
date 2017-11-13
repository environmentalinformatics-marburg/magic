#########################################################
# Calculate Solar position

#this script calculates min/mean/max daily sun angles on a pixel basis
#and exports them as a multilayer sunproperties dataset.
# The layers of the resulting tif are "min_altitude","mean_altitude","max_altitude",
#                                   "min_azimuth","mean_azimuth","max_altitude"

#########################################################

rm(list=ls())
library(oce)
library(raster)
library(gdalUtils)
library(lubridate)
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/raster/")
outpath <- paste0(datapath,"/solarinfo/")
template_PS <- raster(paste0(datapath,"dem.tif"))
projection(template_PS) <- "+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"

template <- raster(paste0(datapath,"/template_ll.tif"))
template <- aggregate(template,15)

coord <- coordinates(template)



days <- seq(as.POSIXct("2010-01-01"), as.POSIXct("2010-12-31"), 
            by="days")

for (i in 1:length(days)){
  tmpdiri <- paste0(mainpath,"/tmpdir/",i,"/")
  rasterOptions(tmpdir=tmpdiri)
  altitude_day <- list()
  azimuth_day <- list()
  for (k in 1:nrow(coord)){
  hours <- seq(as.POSIXct(paste0(days[i]," 00:00:00")), 
               as.POSIXct(paste0(days[i]," 23:00:00")), by="hour")
    altitude <- c()
    azimuth <- c()
    #calculate hourly sun properties for each pixel and each day
    for (hour in 1:length(hours)){
    sunprop <- sunAngle(hours[hour],coord[k,1],coord[k,2])
    azimuth <- c(azimuth, sunprop$azimuth)
    altitude <- c(altitude, sunprop$altitude)
    }
    ######## calculate daily min/max for each pixel
    azimuth_day$mean_azimuth <- c(azimuth_day$mean_azimuth,mean(azimuth))
    altitude_day$mean_altitude <- c(altitude_day$mean_altitude,mean(altitude))
    azimuth_day$min_azimuth <- c(azimuth_day$min_azimuth,min(azimuth))
    altitude_day$min_altitude <- c(altitude_day$min_altitude,min(altitude))
    azimuth_day$max_azimuth <- c(azimuth_day$max_azimuth,max(azimuth))
    altitude_day$max_altitude <- c(altitude_day$max_altitude,max(altitude))
  }
  ######## create daily raster
  
  solarprop_rst <- stack(template,template,template,
                        template,template,template)
  values(solarprop_rst[[1]])<-altitude_day$min_altitude
  values(solarprop_rst[[2]])<-altitude_day$mean_altitude
  values(solarprop_rst[[3]])<-altitude_day$max_altitude
  
  values(solarprop_rst[[4]])<-azimuth_day$min_azimuth
  values(solarprop_rst[[5]])<-azimuth_day$mean_azimuth
  values(solarprop_rst[[6]])<-azimuth_day$max_azimuth
  
  ######## project and export
  
  solarprop_rst_PS <- projectRaster(solarprop_rst,template_PS)
  solarprop_rst_PS_proj <- mask(solarprop_rst_PS,template_PS)
  writeRaster(solarprop_rst_PS_proj,paste0(outpath,"/solarprop_",sprintf("%03d", yday(days[i])),".tif"),
              datatype='INT2S')
  print(i)
  unlink(tmpdiri,recursive = TRUE)
}

