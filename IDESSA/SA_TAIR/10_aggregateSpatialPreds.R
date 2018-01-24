rm(list=ls())
library(raster)
library(rgdal)
mainpath <-"/media/memory02/users/hmeyer/IDESSA_TAIR/"
inpath <-paste0(mainpath,"sppredictions/")
outpath <-paste0(mainpath,"spatialpred_daily/")
tempdir <-paste0(mainpath,"tmpdir/")

rasterOptions(tmpdir=tempdir)


files <- list.files(inpath,full.names = TRUE)
uniquedates <- unique(substr(files,nchar(files)-13,nchar(files)-6))
for (i in 1:length(uniquedates)){
  files_date <- files[grep(uniquedates[i],files)]
  daydat <- stack(files_date)
  quality <- sum(!is.na(daydat))/24
  daydat <- mean(daydat, na.rm = TRUE)
  writeRaster(daydat,paste0(outpath,"averageT_",uniquedates[i],".tif"),overwrite=TRUE)
  writeRaster(quality,paste0(outpath,"Quality_averageT_",uniquedates[i],".tif"),overwrite=TRUE)
}
