rm(list=ls())
library(raster)
library(Rainfall)
library(rgdal)
msgpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/ToProject/MSG/2010/"
radarpath="/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/ToProject/Radar_R_Grid/"

msgpathout<-"/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/MSGProj/2010/"
radarpathout<-"/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/RadarProj/2010/"

template_rw<-raster("/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/ToProject/templates/raa01-rw_10000-1005312050.tif")
template_msg<-raster("/media/memory01/casestudies/hmeyer/Improve_DE_retrieval/ToProject/templates/201010101150_mt09s_B0103xxxx_m1hct_1000_rg01de_003000.rst")
proj4string(template_msg)= "+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"


setwd(msgpath)

months=list.files()
#months=c("11","12")
for (i in months){
  dir.create(paste0(msgpathout,"/",i))
  dir.create(paste0(radarpathout,"/",i))
  setwd(paste0(msgpath,i)) 
  days=list.files()
  for (k in days){
    dir.create(paste0(msgpathout,"/",i,"/",k))
    dir.create(paste0(radarpathout,"/",i,"/",k))
    setwd(paste0(msgpath,i,"/",k))
    hours=list.files()
    for (l in hours){
      dir.create(paste0(msgpathout,"/",i,"/",k,"/",l))
      dir.create(paste0(radarpathout,"/",i,"/",k,"/",l))
      print (paste0("month: ", i, " day:", k, " hour: ", l, " in progress.."))
      setwd(paste0(msgpath,i,"/",k,"/",l))
      date=getDate(getwd())


      ### get MSG ###########################################################
      channels<-list.files(,pattern=".rst$")
      for(ch in 1:length(channels)){
        sceneraster <- tryCatch(raster(channels[ch]),error = function(e)e)
        if(inherits(sceneraster, "error")) {
          next
        }
        extent(sceneraster)<-extent(template_msg)
        proj4string(sceneraster)<-proj4string(template_msg)
        writeRaster(sceneraster, file= paste0(msgpathout,"/",i,"/",k,"/",l,"/",gsub("rst","tif",channels[ch])),overwrite=T)
      }
      ### get radar ##########################################################
      radarpathtmp= paste0(radarpath,i,"/",k)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))
      id <- grep(date,tmp)
      
      radardata <- tryCatch(raster(paste0(radarpathtmp,"/",tmp[id])),error = function(e)e)
      if(inherits(sceneraster, "error")) {
        next
      }
      radardata<-radardata/10
      extent(radardata)<-extent(template_rw)
      proj4string(radardata)<-proj4string(template_rw)
      
      radardata=projectRaster(radardata, crs=proj4string(sceneraster))
      radardata=resample(radardata, sceneraster)
      
      
      writeRaster(radardata,file=paste0(radarpathout,"/",i,"/",k,"/",l,"/",gsub("rst","tif",tmp[id])),overwrite=T)
      }
    }
  }

      