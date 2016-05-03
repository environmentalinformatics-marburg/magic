rm(list=ls())
library(raster)
library(Rsenal)
library(cluster)

library(snow)
ncores <- 2
setwd("/media/hanna/data/IDESSA_Bush/AERIALIMAGERY/samples")
allFiles <- list.files(,pattern=".tif$")
test<- brick(allFiles[1])
test=crop(test,c(-13000,-11000,-2870000,-2867000))

snow_fun <- function(fname)
{
  require(fuerHanna)
  tryCatch({
    rasterOptions(tmpdir="/media/hanna/data/tmp/")
    rgb <- brick(fname)
    names(rgb)<-c("R","G","B")
    rgb_hsi <- hsi(rgb)
    names(rgb_hsi)<-c("H","S","I")
    vvi <- vvi(rgb)
    names(vvi)<-"VVI"
    vvi_txt <- simpletexture(vvi, 3)
    names(vvi_txt)<-c("VVI_mean","VVI_sd")
    rgb_txt <- simpletexture(rgb, 3)
    names(rgb_txt)<-paste0(c("R_mean","R_sd","G_mean","G_sd","B_mean","B_sd"))
    rgb_hsi_txt <- simpletexture(rgb_hsi, 3)
    names(rgb_hsi_txt)<-paste0(c("H_mean","H_sd","S_mean","S_sd","I_mean","I_sd"))
    result <- stack(rgb,rgb_hsi,vvi,rgb_txt,rgb_hsi_txt,vvi_txt)

#    0
  }, error = function(e) 1)
}




cl <- makeSOCKcluster(rep.int("localhost",ncores))
status <- parSapply(cl = cl, X = allFiles, FUN = snow_fun)
stopCluster(cl)





#predictors<-brick(g1,vvi(g1))
#predictors <- as.matrix(predictors)
#clustered <- kmeans(predictors, centers = 2, iter.max = 100, nstart = 10)

