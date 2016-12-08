library(rgdal)

rm(list=ls())
source("/home/hmeyer/magic/IDESSA/SA_TAIR/functions.R")

years <- 2010:2014
cloudNA <- FALSE #if true then clouds well be kept

datapath <- "/media/memory01/data/data01/msg-out-hanna/"
cloudmaskpathcma <- "/media/memory01/data/data01/CM_SAF_CMa/"
cloudmaskpathCLAAS <- "/media/memory01/data/data01/CLAAS2_cloudmask/ftp-cmsaf.dwd.de/cloudmask/cloudmask/"
stationpath <- "/media/memory01/data/IDESSA/Tair/statdat/"
outpath<-"/media/memory01/data/IDESSA/Tair/Results/ExtractedData/"
untardir <- "/media/memory01/data/IDESSA/Tair/tmp/"

stations <- readOGR(paste0(stationpath,"allStations.shp"),"allStations")


cloudmaskpath <- years
cloudmaskpath[years<2013]<-cloudmaskpathcma
cloudmaskpath[years>=2013]<-cloudmaskpathCLAAS
masktype <- years
masktype[years<2013]<-"CMa"
masktype[years>=2013]<-"CLAASS"

for (i in 1:length(years)){
  extractMSG(year=years[i],datapath=datapath,
             setcloudNA=FALSE,masktype=masktype,
             cloudmaskpath=cloudmaskpath[i],
             outpath=outpath,untardir=untardir,stations=stations,
             channels=c("IR10.8", "IR12.0"))
}

