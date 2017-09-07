# lcc 1 km tiles in the molopo region

library(raster)
library(rgdal)

# path to the input tiles
datasrc <- "F:/ludwig/input/"

# load sample points
spp <- readOGR("F:/ludwig/sample_points.shp")

for(h in seq(length(spp))){
  # load matching input tile
  cur <- stack(paste0(datasrc, spp[h,]$tile))
  
  # crop the 1 km tile
  tile <- crop(cur, y = c(spp[h,]@coords[1], 
                          spp[h,]@coords[1] + 1000,
                          spp[h,]@coords[2],
                          spp[h,]@coords[2] + 1000))
  
  #### VVI from the Rsenal Package ####
  #### eventually replace with function! ####
  ## separate visible bands
  red <- tile[[1]]
  green <- tile[[2]]
  blue <- tile[[3]]
  
  ## calculate vvi
  vvi <- (1 - abs((red - 30) / (red + 30))) * 
    (1 - abs((green - 50) / (green + 50))) * 
    (1 - abs((blue - 1) / (blue + 1)))
  
  result <- stack(tile, vvi)
  image.df <- as.data.frame(result)
  
  
  #######################################################################
  # determine number of clusters
  # Elbow method
  cluster.image <- list()
  pExp <- c()
  
  for (i in 1:10){
    cluster.image[[i]] <- kmeans(na.omit(image.df), i, iter.max = 10, 
                                 nstart = 25)
    pExp[i] = 1 - cluster.image[[i]]$tot.withinss / cluster.image[[i]]$totss
    print (paste0(i, " processed..."))
  }
  
  pExpFunc <- splinefun(1:10, pExp)
  optNrCluster <- min(which(round(pExpFunc(1:10, deriv=2), 1) == 0))
  ########################################################################
  
  
  ########################################################################
  ### Cluster image with optimal nr of clusters
  ########################################################################
  cluster.image <- kmeans(na.omit(image.df), optNrCluster, iter.max = 50, 
                          nstart = 25)
  
  ### Create raster output from clusering
  image.df.factor <- rep(NA, length(image.df[,1]))
  image.df.factor[!is.na(image.df[,1])] <- cluster.image$cluster
  clustered <- raster(result) 
  clustered <- setValues(clustered, image.df.factor) 
  
  writeRaster(clustered, paste0("F:/ludwig/output/lcc_", i, ".tif"),overwrite=TRUE)
  gc()  
  
}

