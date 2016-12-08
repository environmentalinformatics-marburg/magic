extractMSG <- function(year=2010,
                       setcloudNA=TRUE,
                       datapath,# msg folder. subfolder must be named /year
                       cloudmaskpath,
                       masktype="CMa", # or "CLAASS
                       outpath,
                       untardir,
                       stations,
                       ...
){
  require(raster)
  require(rgdal)
  require(Rainfall)
  require(Rsenal)
  require(gdalUtils)
  
  
  stations <- spTransform(stations,
                          CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"))
  
  #msg in unterordnern: zb: "MT9P201011292345_mt09s"
  MSG_extract <- data.frame()
  
    yearpath <- paste0(datapath,year,"/")
 #   setwd(yearpath)
    months <- list.dirs(yearpath,recursive=FALSE,full.names = FALSE)
    
    if (masktype=="CLAAS"){
      ###prepare claas cloudmask
      tarfilelist <- list.files(cloudmaskpath,pattern=".tar$",full.names = TRUE)
      cloudlist <- lapply(tarfilelist,function(x){
        result <- data.frame("folder"=x,"tar"=untar(x,list=TRUE))})
      cloudlist <- do.call("rbind", cloudlist)
    }
    
    
    for (month in months){
      monthdir <- paste0(yearpath,"/",month,"/")
  #    setwd(monthdir)
      days <- list.dirs(monthdir,recursive=FALSE,full.names = FALSE)
      for (day in days){
        daydir <- paste0(yearpath,"/",month,"/",day,"/")
        #setwd(daydir)
        scenes <- list.dirs(daydir,recursive=FALSE,full.names = FALSE)
        
        for (scene in scenes){
          scenedir <- paste0(yearpath,"/",month,"/",day,"/",scene,"/")
          #setwd(scenedir)
          #########################################
          #Get MSG data
          ########################################
          MSG <- tryCatch(getChannels(paste0(scenedir,"/cal"),
                                      ...),error = function(e)e)
          sunzen <- tryCatch(getSunzenith(paste0(scenedir,"/meta")),error = function(e)e)
          if(inherits(MSG, "error")||inherits(sunzen, "error")) {
            next
          }
          date <- getDate(paste0(scenedir,"/cal"))
          MSG <- stack(MSG,sunzen)
          MSG <- cr2Geos(MSG)
        
          ######
          #Process Cloud Mask
          #####
          if (masktype=="CMa"){
            cloudpath <- paste0(cloudmaskpath,"/",year,"/",month,"/",day,"/")
            #setwd(cloudpath)
            Cloudmaskfile <- list.files(cloudpath,pattern=date,full.names = TRUE)
            if(length(Cloudmaskfile)==0){next}
            cloudmask <- raster(readGDAL(paste0('HDF5:\"',Cloudmaskfile,'\"://CMa')))
          }
          if (masktype=="CLAAS"){
            #setwd(cloudmaskpath)
            cloudmask <- cloudlist[grep(date,cloudlist[,2]),]
            if(nrow(cloudmask)==0){next}
            untar(as.character(cloudmask$folder),
                  files=as.character(cloudmask$tar),
                  exdir=untardir)
            #setwd(untardir)
            cloudmask <- list.files(untardir,recursive = TRUE,full.names = TRUE)     
            #setwd(paste0(cloudmask,"/level2/",year,"/",month,"/",day,"/"))
            #cloudmask <- list.files(paste0(cloudmask,"/level2/",year,"/",month,"/",day,"/"),full.names = TRUE)
            #cloudmask <- list.files(paste0(cloudmask,"/level2/",year,"/",month,"/",day,"/"),full.names = TRUE)
            Sys.setenv(GDAL_NETCDF_BOTTOMUP="NO")
            cloudmask <- gdal_translate(paste0('NETCDF:',cloudmask,':cma'), 
                                        paste0(untardir,"level2/",year,"/",month,"/",day,'/tmp.tif'), 
                                        of="GTiff", output_Raster=TRUE, verbose=TRUE)
            
            extent(cloudmask)<-c(extent(cloudmask)@xmin+38,extent(cloudmask)@xmax+38,
                                 extent(cloudmask)@ymin+38,extent(cloudmask)@ymax+38)
          }
          cloudmask <- cr2Geos(cloudmask)
          cloudmask <- crop(cloudmask,extent(MSG))
          
          if (setcloudNA){
            cloudmask[cloudmask==1] <- NA
            cloudmask[cloudmask>1] <- 1
          }else{
            cloudmask[cloudmask>1] <- NA
          }
          #Extract data
          #####
          MSG <- tryCatch(mask(MSG,cloudmask),error = function(e)e)
          if(inherits(MSG, "error")){next}
          MSG_extract <- rbind(MSG_extract,data.frame(date,as.character(stations@data$Name),extract(MSG,stations)))
          if (masktype=="CLAAS"){
            #setwd(untardir)
            file.remove(paste0(untardir,list.files(untardir,recursive = TRUE)))
          }
        }
      }
      print (paste0("year ", year, " month ",month, " in process..."))
    }
    
    save(MSG_extract,file=paste0(outpath,"ExtractedData_",year,".RData"))
}



