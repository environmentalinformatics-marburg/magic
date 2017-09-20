# unsupervised landcover classification

# # # tasks: # # #
# 1. load tiles
# 2. visible vegetation index
# 3. determine number of clusters (Elbow)
# 4. cluster image with optimal number of clusters

###################################################



###################################################

wh_lcc <- function(indir, outdir){
  
  # load input tiles for the classification
  tile_list <- list.files(indir, full.names = TRUE, pattern = ".tif$")
  tile_names <- list.files(indir, full.names = FALSE, pattern = ".tif$")
  
  
  for(k in length(tile_list)){
    # # # # # # # # # # # #
    # prepare input stack 
    # # # # # # # # # # # #
    
    # load stack
    tile <- stack(tile_list[k])
    # separate visible bands
    red <- tile[[1]]
    green <- tile[[2]]
    blue <- tile[[3]]
    
    ## calculate vvi
    vvi <- (1 - abs((red - 30) / (red + 30))) * 
      (1 - abs((green - 50) / (green + 50))) * 
      (1 - abs((blue - 1) / (blue + 1)))
    
    result <- stack(tile, vvi)
    
    # make space in RAM
    rm(vvi, red, green, blue, tile)
    gc()
    
    # lower resolution so the PC can handle it
    agg <- aggregate(result, fact = 3, fun = mean, expand = FALSE)
    agg.df <- as.data.frame(agg)
    
    #######################################################################
    # determine number of clusters with lower resolution
    # Elbow method
    cluster.image <- list()
    pExp <- c()
    
    for (i in 1:10){
      cluster.image[[i]] <- kmeans(na.omit(agg.df), i, iter.max = 10, 
                                   nstart = 25)
      pExp[i] = 1 - cluster.image[[i]]$tot.withinss / cluster.image[[i]]$totss
      print (paste0(i, " processed..."))
    }
    
    pExpFunc <- splinefun(1:10, pExp)
    optNrCluster <- min(which(round(pExpFunc(1:10, deriv=2), 1) == 0))
    ########################################################################
    # make space in RAM again
    rm(agg, agg.df)
    gc()
    
    
    ########################################################################
    ### Cluster image with optimal nr of clusters
    ########################################################################
    # now cluster with the original resolution
    image.df <- as.data.frame(result)
    cluster.image <- kmeans(na.omit(image.df), optNrCluster, iter.max = 50, 
                            nstart = 25)
    
    ### Create raster output from clusering
    image.df.factor <- rep(NA, length(image.df[,1]))
    image.df.factor[!is.na(image.df[,1])] <- cluster.image$cluster
    clustered <- raster(result) 
    clustered <- setValues(clustered, image.df.factor) 
    
    writeRaster(clustered, paste0(outdir, "lcc_", tile_names[k]), overwrite=TRUE)
    unlink(tmpdir, recursive=TRUE)  
    
  }
  
  
  
  
  
}