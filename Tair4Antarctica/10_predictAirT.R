predictAirT <- function (model, LSTpath, month="Jan", outname=NULL,
                         returnRaster=FALSE){
  require(caret)
  require(rgdal)
  require(raster)
  origin_of_file <- c(-3282496.232239199, 3333134.0276302756)
  LST <- raster(readGDAL(paste0("HDF5:",LSTpath,"://BAND1/DATA")))
  proj4string(LST) <- CRS("+proj=stere +lat_0=-90 +lat_ts=-71 +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs") 
  extent(LST) <- c(origin_of_file[1],origin_of_file[1]+dim(LST)[2]*1000,
                       origin_of_file[2]-dim(LST)[1]*1000,origin_of_file[2])
  monthSp <- LST
  values(monthSp) <- as.factor(month)
  names(LST) <- "LST"
  names(monthSp) <- "month"
  prediction <- predict(stack(LST,monthSp),model_GBM)
  if (!is.null(outname)){
    writeRaster(prediction,paste0(outname,".tif"),overwrite=TRUE)
  }
  if(!returnRaster){
    rm(prediction)
    gc()
  }
  if(returnRaster){
    return(prediction)
  }
}

rasterOptions(tmpdir = "/media/hanna/data/Antarctica/rastertmp")

filelist <- list.files("/media/hanna/data/Antarctica/data/MODIS_LST/integrated/2013/mosaics/",pattern=".kea$",full.names = TRUE)
filename <- list.files("/media/hanna/data/Antarctica/data/MODIS_LST/integrated/2013/mosaics/",pattern=".kea$",full.names = FALSE)




load("/media/hanna/data/Antarctica/results/MLFINAL/model_GBM.RData")
outpath<-"/media/hanna/data/Antarctica/results/predictions/"



for (i in 1:length(filelist)){
  year<-substr(filename[i],nchar(filename[i])-10,nchar(filename[i])-7)
  jday<-substr(filename[i],nchar(filename[i])-6,nchar(filename[i])-4)
  month<-month.abb[as.numeric(substr(strptime(paste(year, jday), "%Y %j"),6,7))]
  outname <- paste0(outpath,"/",substr(filename[i],1,nchar(filename[i])-4))
  predictAirT(model_GBM,LSTpath = filelist[i],month=month,outname=outname)
  print(i)
  file.remove(list.files("/media/hanna/data/Antarctica/rastertmp"))
}



