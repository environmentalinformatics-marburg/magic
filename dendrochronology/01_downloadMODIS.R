###MODIS 
#run on 182

rm(list=ls())
library(MODIS)
library(rgdal)

MODISpath <- "/media/memory01/data/processing_data/modis_europe/"
shppath <- paste0(MODISpath,"/vector/")

MODISoptions(localArcPath=paste0(MODISpath,"/MODIS_ARC/"),
             outDirPath=paste0(MODISpath,"/MODIS/"),
             MODISserverOrder = c("LPDAAC", "LAADS"))


 dat <- read.csv(paste0(shppath,"Koordinaten.csv"))
 
 dat_sp <- SpatialPoints(data.frame(dat[,3],dat[,2]))
 proj4string(dat_sp) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
 tiles <- getTile(dat_sp)
 

 
# downloadMODIS <- getHdf(product = "M.D11A1",
#                begin = "2000.03.01",
#               tileV=2:4,tileH=18:22)
 
 processMODIS <-  runGdal( product="M.D11A1",
                           begin = "2000.03.01",
                           tileV=2:4,tileH=18:22,
                           SDSstring ='100010000000',
                           job = "mcd11a1-europe")
 
 
