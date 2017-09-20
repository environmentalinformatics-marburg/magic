
#this script applys the trained air temperature model
# on spatio-temporal MSG SEVIRI and MODIS data considering
# a cloud mask. MSG processing bases on script of the IDESSA SA_Rainfall project.

rm(list=ls())
lib <- c("R.utils","Rainfall","Rsenal","caret","rgdal","gdalUtils","foreach",
         "doParallel","raster")
sapply(lib, function(x) require(x, character.only = TRUE))

year <- 2012

mainpath <- "/media/memory01/data/hmeyer/IDESSA_TAIR/"
msgpath <- paste0("/media/memory01/data/data01/msg-out-hanna/",year,"/")
cloudmaskpath <- "/media/memory01/data/data01/CM_SAF_CMa/"
cloudmaskpathCLAAS <- "/media/memory01/data/data01/CLAAS2_cloudmask/ftp-cmsaf.dwd.de/cloudmask/cloudmask/"
outpath <- paste0(mainpath,"/MSG/")
##
auxdatpath <- paste0(mainpath,"auxdat/")
untardir <- paste0(mainpath,"tmp/",year,"/")
tmpdir <- paste0(mainpath,"tmpout/",year,"/")
dir.create(outpath)
dir.create(tmpdir)
dir.create(untardir)


base <- readOGR(paste0(auxdatpath,"TM_WORLD_BORDERS-0.3.shp"),
                "TM_WORLD_BORDERS-0.3")
base <- crop(base,c(2,44,-40,-9))
base <- spTransform(base,"+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs")

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
                         untardir,cloudmaskpath,cloudmaskpathCLAAS,model,
                         rasterdat_names,tmpdir,cloudlist,mainpath){
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
    ############################################################################
    #Process Cloud Mask
    ############################################################################
    cloudmask <- NULL
    if (year<2013){
      cloudpath <- paste0(cloudmaskpath,"/",year,"/",month,"/",day,"/")
      Cloudmaskfile <- list.files(cloudpath,pattern=date,full.names = TRUE)
      if(length(Cloudmaskfile)==0){stop}
      cloudmask <- tryCatch(raster(readGDAL(paste0('HDF5:\"',Cloudmaskfile,'\"://CMa'))),
                            error = function(e)e)
      if(inherits(cloudmask, "error")){
        next
      }
      
    }
    if (year>=2013){
      cloudmask <- cloudlist[grep(date,cloudlist[,2]),]
      if(nrow(cloudmask)==0){stop}
      tmp <- tryCatch(
        untar(as.character(cloudmask$folder),
              files=as.character(cloudmask$tar),
              exdir=untardir_i),error = function(e)e)
      if(inherits(tmp, "error")){
        next
      }
      cloudmask <- list.files(paste0(untardir_i,"/level2/",year,"/",month,"/",day,"/"),pattern=date,full.names = TRUE)
      if (length(cloudmask)==0){ stop("error")}
      Sys.setenv(GDAL_NETCDF_BOTTOMUP="NO")
      cloudmask <- tryCatch(gdal_translate(paste0('NETCDF:',cloudmask,':cma'), 
                                           paste0(tmpdir,"/tmp_",i,".tif"), 
                                           of="GTiff", output_Raster=TRUE, verbose=TRUE),
                            error = function(e)e)
      
      unlink(paste0(untardir_i,"/level2/",year,"/",month,"/",day,"/"))
      if(inherits(cloudmask, "error")){
        stop("error")
      }
      if(is.null(cloudmask)){next}
      extent(cloudmask)<-c(extent(cloudmask)@xmin+38,extent(cloudmask)@xmax+38,
                           extent(cloudmask)@ymin+38,extent(cloudmask)@ymax+38)
    }
    if(is.null(cloudmask)){next}
    
    cloudmask <- cr2Geos(cloudmask)
    cloudmask <- crop(cloudmask,extent(msgdats[[subhours]]))
    cloudmask[cloudmask==1] <- 1
    cloudmask[cloudmask>1] <- NA
    
    msgdats[[subhours]] <- tryCatch(mask(msgdats[[subhours]],cloudmask),
                                    error = function(e)e)
    
    szen[[subhours]] <- tryCatch(mask(szen[[subhours]],cloudmask),
                                 error = function(e)e)
    if(inherits(msgdats[[subhours]], "error")||inherits(szen[[subhours]], 
                                                        "error")){
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
  msgdat <- stack(msgdat,szen)
  names(msgdat) <- c(names(msgdats[[1]]),"sunzenith")
  msgdat <- mask(msgdat,base)
  rm(msgdats,cloudmask)
  file.remove(paste0(tmpdir,"/tmp_",i,".tif"))
  gc()
  writeRaster(msgdat,paste0(outpath,"/msg_",unique(hours)[i],".tif"),overwrite=TRUE)
}
 
for(i in 1:length(unique(hours))){
  print(i)
  functmp <- tryCatch(doPrediction(i,rasterdat,hours,year,modelpath,outpath,msgpath,
                                   untardir,cloudmaskpath,cloudmaskpathCLAAS,
                                  rasterdat_names,tmpdir,cloudlist,mainpath),
                      error = function(e)e)
  if(inherits(functmp, "error")){next}
}

