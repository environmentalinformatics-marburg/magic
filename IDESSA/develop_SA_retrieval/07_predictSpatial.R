rm(list=ls())
lib <- c("R.utils","Rainfall","Rsenal","caret","rgdal","gdalUtils","foreach","doParallel","raster")
sapply(lib, function(x) require(x, character.only = TRUE))

year <- 2013
modelpath <- "/media/memory01/data/IDESSA/Results/Model/"
outpath <- "/media/memory01/data/IDESSA/Results/Predictions/"
msgpath <- paste0("/media/memory01/data/data01/msg-out-hanna/",year,"/")
untardir <- "/media/memory01/data/IDESSA/tmp/"
cloudmaskpath <- "/media/memory01/data/data01/CM_SAF_CMa/"
cloudmaskpathCLAAS <- "/media/memory01/data/data01/CLAAS2_cloudmask/ftp-cmsaf.dwd.de/cloudmask/cloudmask/"
tmpdir <- "/media/memory01/data/IDESSA/tmpout/"
mainpath <- "/home/hmeyer/Rainfall4SA/"
model_RA_night <- get(load(paste0(modelpath,"night_model_RA.RData")))
model_RR_night <- get(load(paste0(modelpath,"night_model_RR.RData")))
model_RA_day <- get(load(paste0(modelpath,"day_model_RA.RData")))
model_RR_day <- get(load(paste0(modelpath,"day_model_RR.RData")))


dir.create(tmpdir)


rasterdat <- listDirectory(msgpath, recursive=2,fullNames=TRUE)
rasterdat_names <- listDirectory(msgpath, recursive=2,fullNames=FALSE)
rasterdat_names <- rasterdat_names[nchar(rasterdat)>53]
rasterdat <- rasterdat[nchar(rasterdat)>53]
hours <- substr(rasterdat_names,11,20)
cloudlist <- NULL
if (year>=2013){
  ###prepare claas cloudmask
  tarfilelist <- list.files(cloudmaskpathCLAAS,pattern=".tar$",
                            full.names = TRUE)
  cloudlist <- lapply(tarfilelist,function(x){
    result <- data.frame("folder"=x,"tar"=untar(x,list=TRUE))})
  cloudlist <- do.call("rbind", cloudlist)
}



doPrediction <- function(i,rasterdat,hours,year,modelpath,outpath,msgpath,
                         untardir,cloudmaskpath,cloudmaskpathCLAAS,model_RA_night,model_RA_day,
                         model_RR_night,model_RR_day,rasterdat_names,tmpdir,cloudlist,mainpath){
  #  tmpdiri <- paste0(tmpdir,"/",i)
  #  dir.create(tmpdiri)
  #  rasterOptions(tmpdir=tmpdiri)
  untardir_i <-paste0(untardir,"/",i,"/")
  dir.create(untardir_i)
  rasterdat_sub <- rasterdat[hours==unique(hours)[i]]
  
  ############################################################################
  #get MSG Data
  ############################################################################
  # szenext <- extent(getSunzenith(paste0(rasterdat_sub[1],"/meta/")))
  szenext <- tryCatch(extent(getSunzenith(paste0(rasterdat_sub[1],"/meta/"))),
                      error = function(e)e)
  if(inherits(szenext, "error")){next}
  msgdats <- list()
  szen <- list()
  ############################################################################
  #Processess 15 minutes raster
  ############################################################################
  for (subhours in 1:length(rasterdat_sub)){
    msgdats[[subhours]] <- tryCatch(cr2Geos(getChannels(paste0(rasterdat_sub[subhours],"/cal/"))),
                                    error = function(e)e)
    szen[[subhours]] <- tryCatch(cr2Geos(getSunzenith(paste0(rasterdat_sub[subhours],"/meta/"))),
                                 error = function(e)e)
    if(inherits(msgdats[[subhours]], "error")||
       inherits(szen[[subhours]], "error")){
      next
    }
    
    date <- Rainfall::getDate(paste0(rasterdat_sub[subhours],"/meta/"))
    year <- substr(date,1,4)
    month <- substr(date,5,6)
    day <- substr(date,7,8)
    outname <- substr(date,1,(nchar(date)-2))
    #   print(date)
    ############################################################################
    #Process Cloud Mask
    ############################################################################
    cloudmask <- NULL
    if (year<2013){
      cloudpath <- paste0(cloudmaskpath,"/",year,"/",month,"/",day,"/")
      setwd(cloudpath)
      Cloudmaskfile <- list.files(,pattern=date)
      if(length(Cloudmaskfile)==0){stop}
      cloudmask <- tryCatch(raster(readGDAL(paste0('HDF5:\"',Cloudmaskfile,'\"://CMa'))),
                            error = function(e)e)
      setwd(mainpath)
      if(inherits(cloudmask, "error")){
        next
      }
      
    }
    if (year>=2013){
      setwd(cloudmaskpathCLAAS)
      cloudmask <- cloudlist[grep(date,cloudlist[,2]),]
      if(nrow(cloudmask)==0){stop}
      tmp <- tryCatch(
        untar(as.character(cloudmask$folder),
              files=as.character(cloudmask$tar),
              exdir=untardir_i),error = function(e)e)
      if(inherits(tmp, "error")){
        next
      }
      setwd(untardir_i)
      cloudmask <- list.files(untardir_i,recursive = TRUE,full.names = FALSE)     
      setwd(paste0("level2/",year,"/",month,"/",day,"/"))
      cloudmask <- list.files(,pattern=date)
      if (length(cloudmask)==0){ stop("error")}
      Sys.setenv(GDAL_NETCDF_BOTTOMUP="NO")
      cloudmask <- tryCatch(gdal_translate(paste0('NETCDF:',cloudmask,':cma'), 
                                           paste0(tmpdir,"/tmp_",i,".tif"), 
                                           of="GTiff", output_Raster=TRUE, verbose=TRUE),
                            error = function(e)e)
      setwd(mainpath)
      unlink(paste0(untardir_i,"/level2/",year,"/",month,"/",day,"/"))
      if(inherits(cloudmask, "error")){
        stop("error")
      }
      
    }
    
    if(is.null(cloudmask)){next}
    cloudmask <- cr2Geos(cloudmask)
    cloudmask <- crop(cloudmask,extent(msgdats[[subhours]]))
    cloudmask[cloudmask==1] <- NA
    cloudmask[cloudmask>1] <- 1
    
    msgdats[[subhours]] <- tryCatch(mask(msgdats[[subhours]],cloudmask),error = function(e)e)
    
    szen[[subhours]] <- tryCatch(mask(szen[[subhours]],cloudmask),error = function(e)e)
    if(inherits(msgdats[[subhours]], "error")||inherits(szen[[subhours]], "error")){
      stop("error")
    }
  }
  ############################################################################
  #Aggregation to hour
  ############################################################################
  
  if(inherits(cloudmask,"error")){stop("error")}
  if(is.null(cloudmask)){stop('error')}
  if (length(msgdats)==0){stop('error')}
  szen <- calc(stack(unlist(szen)),median)
  
  msgdat <- stackApply(stack(unlist(msgdats)), c(1:nlayers(msgdats[[1]])), 
                       median,na.rm=FALSE)
  msgdat<-stack(msgdat,szen)
  names(msgdat) <- c(names(msgdats[[1]]),"sunzenith")
  
  rm(msgdats,cloudmask)
  file.remove(paste0(tmpdir,"/tmp_",i,".tif"))
  gc()
  #  writeRaster(msgdat,paste0(outpath,"MSG/msgdat_",unique(hours)[i],".tif"),overwrite=TRUE)
  ############################################################################
  #Predict RA
  ############################################################################
  if (getDaytime(szen)=="day"){
    model_RA <- model_RA_day
    model_RR <-model_RR_day
  }else{
    model_RA <- model_RA_night
    model_RR <-model_RR_night
  }
  model_RA$levels<-c("Rain","NoRain")
  
  pred_RA <- predictRainfall(model_RA,sceneraster=msgdat,
                             sunzenith=szen,date=date)
  
  writeRaster(pred_RA,paste0(outpath,"/Area/area_",outname,".tif"),overwrite=TRUE)
  ############################################################################
  #Predict RR
  ############################################################################
  pred_RA[pred_RA==2] <- NA
  pred_RR <- predictRainfall(model_RR,sceneraster=msgdat,
                             sunzenith=szen,date=date,
                             rainmask=pred_RA)
  rm(msgdat,szen,pred_RA)
  gc()
  writeRaster(pred_RR,paste0(outpath,"/Rate/rate_",outname,".tif"),overwrite=TRUE)
  rm(pred_RR)
  gc()
  unlink(untardir_i)
  #   unlink(tmpdiri, recursive=TRUE)
  
  
}

#cl <- makePSOCKcluster(detectCores() - 4)
#clusterExport(cl, varlist = c("rasterdat", "hours", "year", "modelpath", 
#                              "outpath", "msgpath", "untardir", "cloudmaskpath", 
#                              "cloudmaskpathCLAAS", "model_RA_night", 
#                              "model_RA_day", "model_RR_night", "model_RR_day", 
#                              "rasterdat_names", "tmpdir", "cloudlist","mainpath","doPrediction", "lib"))
#clusterEvalQ(cl, sapply(lib, function(x) library(x, character.only = TRUE)))

#rslt <- parLapply(cl, 1:length(unique(hours)), function(i) { 
#                  doPrediction(i,rasterdat,hours,year,modelpath,outpath,msgpath,
#                               untardir,cloudmaskpath,cloudmaskpathCLAAS,model_RA_night,model_RA_day,
#                               model_RR_night,model_RR_day,rasterdat_names,tmpdir,cloudlist,
#                               mainpath)
#                })
#stopCluster(cl)


#cl <- makeCluster(detectCores()-4, outfile = "debug.txt")
#registerDoParallel(cl) 

#rslt <- foreach(i=62:length(unique(hours)),.errorhandling = "remove",
#                .packages=lib,.combine = c)%dopar%{ 
#                  doPrediction(i,rasterdat,hours,year,modelpath,outpath,msgpath,
#                               untardir,cloudmaskpath,cloudmaskpathCLAAS,model_RA_night,model_RA_day,
#                               model_RR_night,model_RR_day,rasterdat_names,tmpdir)}
#stopCluster(cl)           


for(i in 62:length(unique(hours))){
  print(i)
  doPrediction(i,rasterdat,hours,year,modelpath,outpath,msgpath,
               untardir,cloudmaskpath,cloudmaskpathCLAAS,model_RA_night,model_RA_day,
               model_RR_night,model_RR_day,rasterdat_names,tmpdir,cloudlist,mainpath)
  }

