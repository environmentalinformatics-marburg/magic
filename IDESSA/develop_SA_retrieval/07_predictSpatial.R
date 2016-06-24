rm(list=ls())
library(R.utils)
library(Rainfall)
library(Rsenal)
library(caret)
library(rgdal)
library(gdalUtils)

year <- 2012
modelpath <- "/media/memory01/data/IDESSA/Results/Model/"
outpath <- "/media/memory01/data/IDESSA/Results/Predictions/"
msgpath <- paste0("/media/memory01/data/data01/msg-out-hanna/",year,"/")
untardir <- "/media/memory01/data/IDESSA/tmp/"
cloudmaskpath <- "/media/memory01/data/data01/CM_SAF_CMa/"
cloudmaskpathCLAAS <- "/media/memory01/data/data01/CLAAS2_cloudmask/ftp-cmsaf.dwd.de/cloudmask/cloudmask/"


rasterdat <- listDirectory(msgpath, recursive=2,fullNames=TRUE)
rasterdat_names <- listDirectory(msgpath, recursive=2,fullNames=FALSE)
rasterdat_names <- rasterdat_names[nchar(rasterdat)>53]
rasterdat <- rasterdat[nchar(rasterdat)>53]


if (year>=2013){
  ###prepare claas cloudmask
  tarfilelist <- list.files(cloudmaskpathCLAAS,pattern=".tar$",
                            full.names = TRUE)
  cloudlist <- lapply(tarfilelist,function(x){
    result <- data.frame("folder"=x,"tar"=untar(x,list=TRUE))})
  cloudlist <- do.call("rbind", cloudlist)
}


for (daytime in c("day","night")){
  model_RA<-get(load(paste0(modelpath,daytime,"_model_RA.RData")))
  model_RR<-get(load(paste0(modelpath,daytime,"_model_RR.RData")))
  for (i in 1:length(rasterdat)){
    print(i)
    ############################################################################
    #get MSG Data
    ############################################################################
    szenext<-extent(getSunzenith(paste0(rasterdat[i],"/meta/")))
    msgdat <- cr2Geos(getChannels(paste0(rasterdat[i],"/cal/")))
    szen <- cr2Geos(getSunzenith(paste0(rasterdat[i],"/meta/")))
    date <- Rainfall::getDate(paste0(rasterdat[i],"/meta/"))
    year<- substr(date,1,4)
    month <- substr(date,5,6)
    day <- substr(date,7,8)
    
    ############################################################################
    #Process Cloud Mask
    ############################################################################
    if (year<2013){
      cloudpath <- paste0(cloudmaskpath,"/",year,"/",month,"/",day,"/")
      setwd(cloudpath)
      Cloudmaskfile <- list.files(,pattern=date)
      if(length(Cloudmaskfile)==0){next}
      cloudmask <- raster(readGDAL(paste0('HDF5:\"',Cloudmaskfile,'\"://CMa')))
    }
    if (year>=2013){
      setwd(cloudmaskpathCLAAS)
      cloudmask <- cloudlist[grep(date,cloudlist[,2]),]
      if(nrow(cloudmask)==0){next}
      untar(as.character(cloudmask$folder),
            files=as.character(cloudmask$tar),
            exdir=untardir)
      setwd(untardir)
      cloudmask <- list.files(untardir,recursive = TRUE,full.names = FALSE)     
      setwd(paste0("level2/",year,"/",month,"/",day,"/"))
      cloudmask <- list.files(,pattern=date)
#      print(cloudmask)
      Sys.setenv(GDAL_NETCDF_BOTTOMUP="NO")
      cloudmask <- gdal_translate(paste0('NETCDF:',cloudmask,':cma'), 
                                  'tmp.tif', 
                                  of="GTiff", output_Raster=TRUE, verbose=TRUE)
      
    }
 

    cloudmask <- cr2Geos(cloudmask)    
    cloudmask <- crop(cloudmask,extent(msgdat))
#    writeRaster(cloudmask,paste0(outpath,"/Rate/cloudmask",date,".tif"),overwrite=T)
     cloudmask[cloudmask==1]=NA
    cloudmask[cloudmask>1]=1
  
    
#    writeRaster(msgdat$IR10.8,paste0(outpath,"/Rate/msgcheck_",date,".tif"),overwrite=T)
   
     msgdat <- tryCatch(mask(msgdat,cloudmask),error = function(e)e)
    if(inherits(msgdat, "error")){next}
    szen <- tryCatch(mask(szen,cloudmask),error = function(e)e)
    if(inherits(szen, "error")){next}
    
    ############################################################################
    #Predict RA
    ############################################################################
    
    
    pred_RA <- predictRainfall(model_RA,sceneraster=msgdat,
                               sunzenith=szen,type="rst")
    writeRaster(pred_RA,paste0(outpath,"/Area/",date,".tif"),overwrite=TRUE)
    ############################################################################
    #Predict RR
    ############################################################################
    pred_RA[pred_RA==2] <- NA
    pred_RR <- predictRainfall(model_RR,sceneraster=msgdat,
                               sunzenith=szen,type="rst",
                               rainmask=pred_RA)
    writeRaster(pred_RR,paste0(outpath,"/Rate/",date,".tif"),overwrite=TRUE)
  }}
