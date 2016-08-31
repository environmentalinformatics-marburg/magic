library(MODIS)
library(raster)
library(rgdal)
library(gdalUtils)

setwd("/media/memory01/casestudies/hmeyer/IDESSA_LandCover/")

MODISoptions(localArcPath, outDirPath,

#product <- "MCD43A4"
product <- "MOD09A1"

h=c(19,20,21)
v=c(11,12)
dates <- as.POSIXct( as.Date(c("01/01/2013","31/12/2013"),format = "%d/%m/%Y") )


dates2 <- transDate(dates[1],dates[2]) # Transform input dates from before

MODISdat <- runGdal(product=product,begin=dates2$beginDOY,end = dates2$endDOY,
                    tileH = h,tileV = v)

