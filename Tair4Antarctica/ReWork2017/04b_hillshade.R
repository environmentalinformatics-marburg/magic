#########################################################
# Calculate hillshade

#this script calculates min/mean/max daily hillshade on a pixel basis
#and exports them as a multilayer sunproperties dataset.
# The layers of the resulting tif are 
# "min_hillshade","mean_hillshade","max_hillshade"

#########################################################

rm(list=ls())
library(raster)
mainpath <- "/media/hanna/data/Antarctica/ReModel2017/"
datapath <- paste0(mainpath,"/data/raster/")
outpath <- paste0(datapath,"/hillshade/")
rasterOptions(tmpdir=paste0(mainpath,"tmpdir/"))

hillShadeAdj <- function (slope,aspect,direction,angle){
  # bases on the hillshade function but allows for variable
  # sun direction and zenith on a pixel basis
  direction <- direction * pi/180
  zenith <- (90 - angle) * pi/180
  result <- cos(slope) * cos(zenith) + sin(slope) * sin(zenith) * 
    cos(direction - aspect) #function from hillshade function
  result <- round(result*1000,0)
  return(result) 
}

alt <- raster(paste0(datapath,"dem.tif"))
slope <- terrain(alt, opt='slope')
aspect <- terrain(alt, opt='aspect')


solarprops <- list.files(paste0(datapath,"/solarinfo/"),pattern=".tif$")
for (i in 1:length(solarprops)){
  solarprop <- stack(paste0(datapath,"/solarinfo/",solarprops[i]))
  hill_min <- hillShadeAdj(slope,aspect, solarprop[[4]], solarprop[[1]])
  hill_mean <- hillShadeAdj(slope,aspect, solarprop[[5]], solarprop[[2]])
  hill_max <- hillShadeAdj(slope,aspect, solarprop[[6]], solarprop[[3]])
  hillshades <- stack(hill_min,hill_mean,hill_max)
  writeRaster(hillshades,paste0(outpath,"/hillshade_",substr(solarprops[i],11,13),".tif"),
              datatype='INT2S')
  print(i)
}

