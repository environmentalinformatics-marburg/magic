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
                           SDSstring = c(100000000000,000010000000))
 
 
 
 ########## NUR TESTS
# test <- getHdf(product = "M.D11A1",
#                begin = "2004.01.01",
#                end = "2004.01.02",
#                tileV=2:3,tileH=18) 
#runGdal( product="M.D11A1",
#         begin = "2004.01.01",
#         end = "2004.01.02",
#         tileV=2:3,tileH=18,
#         SDSstring = c(100000000000,000010000000))
 
 
#  b1 <- runGdal(product = "MOD11A1", begin = "2016.12.01", 
#               end = "2016.12.02",
#               tileH = 18, tileV = 4,
#               SDSstring = c(100000000000,000010000000))
#  b1    
#  
# downloadMODIS <- getHdf(product = "MOD11A1",
#                          begin = "2003.03.01",
#                          end = "2003.03.02",
#                          tileV=2,tileH=18)
