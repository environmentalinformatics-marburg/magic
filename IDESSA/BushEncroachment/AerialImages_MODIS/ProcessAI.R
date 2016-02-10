rm(list=ls())

vvi <- function(rgb, r = 1, g = 2, b = 3) {
  
  ### prerequisites
  
  ## compatibility check
  if (nlayers(rgb) < 3)
    stop("Argument 'rgb' needs to be a Raster* object with at least 3 layers (usually red, green and blue).")
  
  
  ### processing
  
  ## separate visible bands
  red <- rgb[[r]]
  green <- rgb[[g]]
  blue <- rgb[[b]]
  
  ## calculate vvi
  rst_vvi <- (1 - abs((red - 30) / (red + 30))) * 
    (1 - abs((green - 50) / (green + 50))) * 
    (1 - abs((blue - 1) / (blue + 1)))
  
  ## return vvi
  return(rst_vvi)
}



datapath <- "/media/memory01/casestudies/hmeyer/IDESSA_LandCover/AI_2013/"
library(gdalUtils)
library(raster)
library(rgdal)
#library(Rsenal)
library(gdalUtils)
setwd(datapath)
library(caret)

outpath<- "/media/memory01/casestudies/hmeyer/IDESSA_LandCover/AI_pred/"
newproj="+proj=aea +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

load("/media/memory01/casestudies/hmeyer/IDESSA_LandCover/model.RData")

clusters <- list.dirs(datapath,full.names = TRUE,recursive=FALSE)
clustersnames <- list.dirs(datapath,full.names = FALSE,recursive=FALSE)
setwd(outpath)
for (i in 1:length(clusters)){
  clusterpath <- clusters[i]
  image <- list.files(clusterpath,pattern=".tif$",full.names = TRUE)
  imagenames <- list.files(clusterpath,pattern=".tif$",full.names = FALSE)
  for (k in 1:length(image)){
    print(paste0("cluster ",i," image", imagenames[k], " in progress..."))
    
    print("reproject data...")
    gdalwarp(image[k], dstfile=paste0(outpath,"pred_",imagenames[k]), 
             t_srs=newproj,overwrite=TRUE,output_Raster=FALSE)
    
    print("load data...")
    rasters <- tryCatch(stack(paste0(outpath,"pred_",imagenames[k])),
                        error = function(e)e)
    if (inherits(rasters,"error")){
      print(paste0("cluster ",i," image ",k," could not be processed"))
      next
    }
    print("calculate vvi...")
    rasters <- tryCatch(stack(rasters,vvi(rasters)),error = function(e)e)
    if (inherits(rasters,"error")){
      print(paste0("cluster ",i,"image ",k," could not be processed"))
      next
    }
    names(rasters)<- c("R","G","B","VVI")
    print("predict woody vegetation...")
    pred <- tryCatch(predict(rasters,model),error = function(e)e)
    if (inherits(pred,"error")){
      print(paste0("cluster ",i,"image ",k," could not be processed"))
      next
    }
    
    pred_prob <- tryCatch(predict(rasters,model,type="prob"),error = function(e)e)
    if (inherits(pred_prob,"error")){
      print(paste0("cluster ",i,"image ",k," could not be processed"))
      next
    }
    
    print("write results...")
    writeRaster(pred,paste0(outpath,"pred_",imagenames[k]),overwrite=TRUE) 
    writeRaster(pred_prob,paste0(outpath,"pred_prob_",imagenames[k]),overwrite=TRUE) 
    
  }
  print (paste0("cluster ", clusters[i], " processed"))
}

