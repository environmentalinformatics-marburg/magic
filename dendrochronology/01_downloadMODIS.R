###MODIS 
#run on 182

rm(list=ls())
library(MODIS)
library(rgdal)

MODISpath <- "/media/hanna/data/MODIS_EUROPE/"
shppath <- paste0(MODISpath,"/vector/")



MODISoptions(localArcPath=paste0(MODISpath,"/MODIS_ARC/"),
             outDirPath=paste0(MODISpath,"/MODIS/"),
             MODISserverOrder = c("LAADS", "LPDAAC"))



#b1 <- getHdf(product = "M.D11A1", begin = "2016.12.01", 
#             tileH = 18:19, tileV = 4) 
#b1               




 dat <- read.csv(paste0(shppath,"Koordinaten.csv"))
 
 dat_sp <- SpatialPoints(data.frame(dat[,3],dat[,2]))
 proj4string(dat_sp) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
 tiles <- getTile(dat_sp)
 

 
 downloadMODIS <- getHdf(product = "M.D11A1",
                begin = "2000.03.01",
               tileV=2:4,tileH=18:22)
 
# processMODIS <-  runGdal( product="M.D11A1",
#                           begin = "2000.03.01",
#                           tileV=2:4,tileH=18:22,
#                           SDSstring = c(100000000000,000010000000))
 
 
 
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
