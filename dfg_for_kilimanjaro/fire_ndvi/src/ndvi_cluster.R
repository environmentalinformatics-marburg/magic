library(latticeExtra)
library(raster)
library(fpc)
library(remote)

fls_ndvi <- list.files("data/processed/whittaker_myd13q1", pattern = "^WHT", 
                       full.names = TRUE)
rst_ndvi <- stack(fls_ndvi)

#### cluster spatially deseasoned
fire_dsn_df <- as.data.frame(rst_ndvi)
clusters_dsn <- rst_agg1m[[1]]

#clust_clouds_dsn_df <- clara(clouds_dsn_df, 4, metric = "euclidian", samples = 1000) 
clust_fire_dsn_df2 <- kmeans(fire_dsn_df, centers = 3, nstart = 4, iter.max = 100, algorithm = "Ll") ### kmeans, with 4 clusters

clusters_dsn[] <- clust_fire_dsn_df2$cluster
plot(clusters_dsn)

# clusplot(fire_dsn_df, clust_fire_dsn_df2$cluster)
# d <- dist(clouds_dsn_df)
# cluster.stats(d, clustering = clust_clouds_dsn_df2$cluster)
# 
# ### mean frequency per cluster
# meanFreq <- function(x) {
#   ind <- which(clusters_dsn[] == x)
#   as.numeric(colMeans(clouds[][ind, ], na.rm = TRUE))
# }
# 
# df_clust <- data.frame("clust1" = meanFreq(1),
#                        "clust2" = meanFreq(2),
#                        "clust3" = meanFreq(3))
# 
# write.csv(df_clust, "clust_mean_series.csv", row.names = FALSE)
