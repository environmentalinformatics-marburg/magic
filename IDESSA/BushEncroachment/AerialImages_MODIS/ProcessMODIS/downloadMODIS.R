library(MODIS)
library(raster)
library(rgdal)
library(gdalUtils)

#setwd("/media/memory01/casestudies/hmeyer/IDESSA_LandCover/Woody_MODIS")
setwd("/media/hanna/data/IDESSA_Bush/MODIS/")

MODISoptions(localArcPath=paste0(getwd(),"/MODIS_ARC"), outDirPath=paste0(getwd(),"/MODIS"))

#product <- "MCD43A4"
product <- "MOD09A1"
product <-MCD12Q2 #land cover

h=c(19,20,21)
v=c(11,12)
dates <- list(as.POSIXct( as.Date(c("01/10/2013","08/10/2013"),format = "%d/%m/%Y") ),
as.POSIXct( as.Date(c("01/01/2013","08/01/2013"),format = "%d/%m/%Y")),
as.POSIXct( as.Date(c("01/04/2013","08/04/2013"),format = "%d/%m/%Y")),
as.POSIXct( as.Date(c("01/07/2013","08/07/2013"),format = "%d/%m/%Y")))
#names(dates)<-c("spring","summer","autumn","winter")

for (i in 1:length(dates)){
dates2 <- transDate(dates[[i]][1],dates[[i]][2]) # Transform input dates from before

MODISdat <- runGdal(product=product,begin=dates2$beginDOY,end = dates2$endDOY,
                    tileH = h,tileV = v)
}

