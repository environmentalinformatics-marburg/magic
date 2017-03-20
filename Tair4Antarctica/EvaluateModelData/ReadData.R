rm(list=ls())
library(raster)
library(rgdal)
library(Rsenal)
setwd("/media/hanna/data/Antarctica/data/RegCM_2013/hdf/")
outpath <- "/media/hanna/data/Antarctica/data/RegCM_2013/tiffs/"
filelist <- list.files(,pattern="h5$")
namelist<-list.files(,pattern=".txt")
monthlookup <- data.frame("nr"=sprintf("%02d",1:12),"month"=c("Jan","Feb","Mar","Apr",
                                                 "May","Jun","Jul","Aug","Sep",
                                                 "Oct","Nov","Dec"))

lat <- stack(readGDAL(paste0("HDF5:",filelist[1],"://lat")))
lon <- stack(readGDAL(paste0("HDF5:",filelist[1],"://long")))

for (month in 1:length(namelist)){
  namelist_i <- read.table(namelist[month])
  namelist_i<-apply(namelist_i,2,function(x) gsub(",", "",x))

  dat <- stack(readGDAL(paste0("HDF5:",filelist[month],"://T_air")))
  dat_proj <- rasterizeRegCM(dat,lat,lon,res=c(10000,10000))
  for (i in 1:nlayers(dat_proj)){
    name <- paste0(substr(namelist_i[i,1],8,11),monthlookup[,1][monthlookup[,2]==
                                                                substr(namelist_i[i,1],4,6)],
                 substr(namelist_i[i,1],1,2),substr(namelist_i[i,2],1,2))
    writeRaster(dat_proj[[i]], paste0(outpath,"/RegCM_AirT_",name,".tif",overwrite=T))
  }
  print(paste0("month ",month, " of 12 processed"))
}