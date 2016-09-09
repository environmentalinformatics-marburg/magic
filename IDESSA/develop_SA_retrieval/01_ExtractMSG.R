library(raster)
library(rgdal)
library(Rainfall)
library(Rsenal)
library(gdalUtils)

years <- 2010

datapath <- "/media/memory01/data/data01/msg-out-hanna/"
cloudmaskpath <- "/media/memory01/data/data01/CM_SAF_CMa/"
cloudmaskpathCLAAS <- "/media/memory01/data/data01/CLAAS2_cloudmask/ftp-cmsaf.dwd.de/cloudmask/cloudmask/"
stationpath <- "/media/memory01/data/IDESSA/statdat/"
outpath<-"/media/memory01/data/IDESSA/Results/ExtractedData/"
untardir <- "/media/memory01/data/IDESSA/tmp/"

stations <- readOGR(paste0(stationpath,"allStations.shp"),"allStations")
stations <- spTransform(stations,
                        CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"))

#msg in unterordnern: zb: "MT9P201011292345_mt09s"
MSG_extract<-data.frame()

for (year in years){
  yearpath <-paste0(datapath,year,"/")
  setwd(yearpath)
  months <- list.dirs(recursive=FALSE,full.names = FALSE)
  
  
  if (year>=2013){
    ###prepare claas cloudmask
    tarfilelist <- list.files(cloudmaskpathCLAAS,pattern=".tar$",full.names = TRUE)
    cloudlist <- lapply(tarfilelist,function(x){
      result <- data.frame("folder"=x,"tar"=untar(x,list=TRUE))})
    cloudlist <- do.call("rbind", cloudlist)
  }
  
  
  for (month in months){
    monthdir <- paste0(yearpath,"/",month,"/")
    setwd(monthdir)
    days <- list.dirs(,recursive=FALSE,full.names = FALSE)
    for (day in days){
      daydir <- paste0(yearpath,"/",month,"/",day,"/")
      setwd(daydir)
      scenes <- list.dirs(recursive=FALSE,full.names = FALSE)
      
      for (scene in scenes){
        scenedir <- paste0(yearpath,"/",month,"/",day,"/",scene,"/")
        setwd(scenedir)
        #########################################
        #Get MSG data
        ########################################
        MSG <- tryCatch(getChannels(paste0(scenedir,"/cal")),error = function(e)e)
        sunzen <- tryCatch(getSunzenith(paste0(scenedir,"/meta")),error = function(e)e)
        if(inherits(MSG, "error")||inherits(sunzen, "error")) {
          next
        }
        date <- getDate(paste0(scenedir,"/cal"))
        MSG <- stack(MSG,sunzen)
        MSG <- cr2Geos(MSG)
        #     extent(MSG)<-c(1408689.286,2908890.869, -3493969.487,-2293808.22)
        #      proj4string(MSG)<-CRS("+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs")
        ######
        #Process Cloud Mask
        #####
        if (year<2013){
          cloudpath <- paste0(cloudmaskpath,"/",year,"/",month,"/",day,"/")
          setwd(cloudpath)
          Cloudmaskfile <- list.files(,pattern=date)
          if(length(Cloudmaskfile)==0){next}
          cloudmask <- raster(readGDAL(paste0('HDF5:\"',Cloudmaskfile,'\"://CMa')))
          #      cloudmask <- crop(cloudmask,c(2325, 2825, 3712-3020, 3712-2620))
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
          cloudmask <- list.files()
          Sys.setenv(GDAL_NETCDF_BOTTOMUP="NO")
          cloudmask <- gdal_translate(paste0('NETCDF:',cloudmask,':cma'), 
                                      'tmp.tif', 
                                      of="GTiff", output_Raster=TRUE, verbose=TRUE)
          
        }
        extent(cloudmask)<-c(extent(cloudmask)@xmin+38,extent(cloudmask)@xmax+38,
                             extent(cloudmask)@ymin+38,extent(cloudmask)@ymax+38)
        cloudmask <- cr2Geos(cloudmask)
        cloudmask <- crop(cloudmask,extent(MSG))
        
     
        cloudmask[cloudmask==1]=NA
        cloudmask[cloudmask>1]=1
        #Extract data
        #####
        MSG <- tryCatch(mask(MSG,cloudmask),error = function(e)e)
        if(inherits(MSG, "error")){next}
        MSG_extract <- rbind(MSG_extract,data.frame(date,as.character(stations@data$Name),extract(MSG,stations)))
        if (year>=2013){
          setwd(untardir)
          file.remove(list.files(untardir,recursive = TRUE))
        }
      }
    }
    print (paste0("year ", year, " month ",month, " in process..."))
  }
  #}
  
  save(MSG_extract,file=paste0(outpath,"ExtractedData_",year,".RData"))
}




