################################################################################
### UNSUPERVIDED CLASSIFICATION FOR SOUTH AFRICA AERIAL IMAGES
# script calculates predictor variables from aerial images and applys a k-means 
# clustering algorithm
################################################################################

rm(list=ls())
library(Rsenal)
library(cluster)
library(fuerHanna) # for fortran implementation of vvi, hsi, simpletexture
require(vegan)

################################################################################
### Do adjustments here
################################################################################
pathToSampleImages <- "/media/hanna/data/IDESSA_Bush/AERIALIMAGERY/samples/"
tmpdir <- "/media/hanna/data/IDESSA_Bush/AERIALIMAGERY/samples/tmpdir"
outdir <- "/media/hanna/data/IDESSA_Bush/AERIALIMAGERY/samples/clusterResults/"

fname <- list.files(pathToSampleImages,pattern=".tif$")[4] # file to be clustered
sizeOfImage <- 150 # in m
method="elbow" # or"cascadeKM" method to determine optimal nr of clusters
applyShadowMask <- FALSE
################################################################################
### Load and crop
################################################################################
setwd(pathToSampleImages)
tmpdir <- paste0(tmpdir,"/001")
dir.create(tmpdir)
rasterOptions(tmpdir=tmpdir)
rgb_img <- brick(fname)
center <- c((extent(rgb_img)@xmin+extent(rgb_img)@xmax)/2,
            (extent(rgb_img)@ymin+extent(rgb_img)@ymax)/2)
rgb_img <- crop(rgb_img,c(center[1]-sizeOfImage/2,center[1]+sizeOfImage/2,
                          center[2]-sizeOfImage/2,center[2]+sizeOfImage/2))
names(rgb_img) <- c("R","G","B")
################################################################################
### Calculate further variables
################################################################################
rgb_hsi <- hsi(red = raster(rgb_img, layer = 1), 
               green = raster(rgb_img, layer = 2),
               blue = raster(rgb_img, layer = 3))
vvindex <- vvi(red = raster(rgb_img, layer = 1), 
               green = raster(rgb_img, layer = 2),
               blue = raster(rgb_img, layer = 3))
names(vvindex) <- "VVI"
result <- brick(c(rgb_img,vvindex))
txt <- simpletexture(result,3)
result <- stack(result,txt)
################################################################################
### Shadow detection
################################################################################
## shadow detection
if(applyShadowMask){
  shadow <- rgbShadowMask(rgb_img)
  # modal filter
  shadow <- focal(shadow, w = matrix(c(1, 1, 1, 
                                       1, 1, 1, 
                                       1, 1, 1), nc = 3), 
                  fun = modal, na.rm = TRUE, pad = TRUE)
}
################################################################################
### Determine Number of clusters
################################################################################
image.df <- as.data.frame(result) 

############################# Elbow method
if (method=="elbow"){
  cluster.image<-list()
  pExp <- c()
  for (i in 1:10){
    cluster.image[[i]] <- kmeans(na.omit(image.df), i, iter.max = 10, 
                                 nstart = 25)
    pExp[i] = 1- cluster.image[[i]]$tot.withinss / cluster.image[[i]]$totss
    print (paste0(i," processed..."))
  }
  
  pExpFunc <-splinefun(1:10,pExp)
  optNrCluster <- min(which(round(pExpFunc(1:10,deriv=2),1)==0))
  pdf(paste0(outdir,"/Nclust_elbow_",fname,".pdf"))
  plot(1:10, pExp, 
       type="b", xlab="Number of Clusters",
       ylab="Within groups sum of squares")
  points(optNrCluster,p.exp[optNrCluster],col="red",pch=16)
  dev.off()
}
############################# cascadeKM method
if (method=="cascadeKM"){
  fit <- cascadeKM(na.omit(image.df), 2, 8, iter = 50)
  optNrCluster <- as.numeric(which.max(fit$results[2,]))
}
################################################################################
### Cluster image with optimal nr of clusters
################################################################################
cluster.image <- kmeans(na.omit(image.df), optNrCluster, iter.max = 50, 
                        nstart = 25)

### Create raster output from clusering
image.df.factor <- rep(NA, length(image.df[,1]))
image.df.factor[!is.na(image.df[,1])] <- cluster.image$cluster
clustered <- raster(result) 
clustered <- setValues(clustered, image.df.factor) 
if(applyShadowMask){
  clustered[shadow==0] <- NA
}
################################################################################
### Save clustered image and clean tmpdir
################################################################################
writeRaster(clustered,paste0(outdir,"/clustered_",fname,".tif"))
unlink(tmpdir, recursive=TRUE)



