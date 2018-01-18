# this script extracts time series of RADOLAN data for each plot in the Exploratories
#Author: Hanna Meyer
#Date: 14.01.2018

rm(list=ls())
library(rgdal)
library(raster)
datapath <- "/media/hanna/data/RADOLAN/"
tmppath <- paste0(datapath,"tmp/")
shppath <- "/home/hanna/Documents/Projects/Exploratories/RainfallExtraction/Plots/"
resultpath <- paste0(datapath,"results/")
rasterOptions(tmpdir=tmppath)

plots <- readOGR(paste0(shppath,"allExploratories.shp"))
plots <- spTransform(plots,"+proj=stere +lat_0=90.0 +lon_0=10.0 +lat_ts=60.0 +a=6370040 +b=6370040 +units=m")
#plots <- plots[,"name"]
plots@coords <- plots@coords[, 1:2]

years <- 2017:2018

for (year in years){
  yearpath <- paste0(datapath, year)
  files <- list.files(yearpath,pattern=".tar",full.names = TRUE)
  lapply(files,untar,exdir=yearpath)
  files <- list.files(yearpath,pattern=".tar.gz",full.names = TRUE)
  lapply(files,untar,exdir=yearpath)
  files <- list.files(yearpath,pattern=".asc",full.names = TRUE)
  results <- vector("list", length(files))
  for (i in 1:length(files)){
    file <- raster(files[i])
    projection(file) <- "+proj=stere +lat_0=90.0 +lon_0=10.0 +lat_ts=60.0 +a=6370040 +b=6370040 +units=m"
    results[[i]] <- extract(file,plots,df=FALSE)
  }

  results <- data.frame(do.call("rbind",results))
  names(results) <- plots$name
  results$Date <- strptime(substr(files,nchar(files)-16,nchar(files)-4),
                          format="%Y%m%d-%H%M")
  save(results,file=paste0(resultpath,"/RADOLAN_extracted_",year,".RData"))
  print(paste0("year ",year, " done..."))
}


