# lcc 1 km tiles in the molopo region

library(raster)
library(rgdal)

# path to the input tiles
datasrc <- "F:/ludwig/aerial_16/tiles_rgb_vvi"
tiles <- list.files(datasrc, full.names = TRUE, pattern = ".tif$")

# workaround for alphabetical order: use creation time as order
tiles <- tiles[order(file.info(tiles)$mtime)]


for(h in seq(4)){
  # load matching input tile
  cur <- stack(tiles[h])
  image.df <- as.data.frame(cur)
  
  
  #######################################################################
  # determine number of clusters
  # Elbow method
  cluster.image <- list()
  pExp <- c()
  # only go from 3 classes to max 7 classes
 # for (i in 3:7){
#    cluster.image[[i]] <- kmeans(na.omit(image.df), i, iter.max = 10, 
#                                 nstart = 25)
#    pExp[i] = 1 - cluster.image[[i]]$tot.withinss / cluster.image[[i]]$totss
#    print (paste0(i, " processed..."))
#  }
  
#  pExpFunc <- splinefun(1:10, pExp)
#  optNrCluster <- min(which(round(pExpFunc(1:10, deriv=2), 1) == 0))
  ########################################################################
  
  
  ########################################################################
  ### Cluster image with optimal nr of clusters
  ########################################################################
  cluster.image <- kmeans(na.omit(image.df), optNrCluster, iter.max = 50, 
                          nstart = 25)
  
  ### Create raster output from clusering
  image.df.factor <- rep(NA, length(image.df[,1]))
  image.df.factor[!is.na(image.df[,1])] <- cluster.image$cluster
  clustered <- raster(cur) 
  clustered <- setValues(clustered, image.df.factor) 
  
  # # # reclass based on vvi # # #
  # # # # # # # # # # # # # # # #
  recode <- lapply(seq(optNrCluster), function(k){
    # figure out the mean vvi per class
    return(data.frame(class = k, vvi =  mean(cur[[4]][clustered == k])))
  })
  recode <- do.call(rbind, recode)
  # highest vvi comes first; bushes should always be class 1 after replacing
  recode <- recode[order(recode$vvi, decreasing = TRUE),]
  recode$new_class <- seq(nrow(recode))
  # save coding for future analysis
  write.csv(recode, paste0("F:/ludwig/aerial_16/bush_classification_vvi/vvi_class_", h,".csv"), row.names = FALSE)
  recode_m <- matrix(cbind(recode$class, recode$new_class), ncol = 2)
  
  reclustered <- raster::reclassify(clustered, recode_m)
  
  # # # # # # # # # # # # # # # #
  
  
  writeRaster(reclustered, paste0("F:/ludwig/aerial_16/bush_classification/lcc_", h, ".tif"), overwrite=TRUE)
  gc()  
  
}
