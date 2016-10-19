rm(list=ls())
library(raster)
library(rgdal)


path_basis <- "/media/hanna/data/IDESSA_Bush/MODIS/"
datapath <- paste0(path_basis,"raster/MODIS/")
auxpath <-paste0(path_basis,"/auxiliary/")
outpath <- paste0(path_basis,"raster/")
tmppath <- paste0(path_basis,"tmp/")
setwd(datapath)

rasterOptions(tmpdir=tmppath)
### get MODIS information

files <- list.files(,pattern="b0",recursive=TRUE)
files <- files[substr(files,nchar(files)-3,nchar(files))==".tif"]
jday <- substr(files,nchar(files)-19,nchar(files)-17)
month <- format(strptime(jday, 
                         format="%j"), format="%m")

season_lut <- cbind(1:12,c(rep("summer",2),rep("autumn",3),rep("winter",3),rep("spring",3),"summer"))
season <- season_lut[,2][as.numeric(month)]

datinfo <- data.frame ("season"=season, "jday" =jday,
                        "month"=month)
### get MODIS data
filestack <-stack(files)
names(filestack) <- paste0(datinfo$season,"_",substr(names(filestack),
                                                 nchar(names(filestack))-2,nchar(names(filestack))))
### crop data
LUC <- raster (paste0(auxpath,"/MCD12Q1.A2013001.Land_Cover_Type_1.tif"))
values(LUC)[values(LUC)%in%c(6:10,16)] <- 100
values(LUC)[values(LUC)!=100] <- NA
filestack <- mask(filestack,LUC) #mask mit modis land cover product
filestack <- crop(filestack,c(1200000,3700000,-3900000,-2200000 ))


writeRaster(filestack,paste0(outpath,"/MODISstack.tif"),overwrite=TRUE)



