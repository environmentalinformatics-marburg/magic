library(rioja)
data(RLGH)
diss <- dist(sqrt(RLGH$spec/100))
clust <- chclust(diss)

bstick(clust, 10)
plot(clust, hang=-1)


### ------

val <- mat[1, 13:ncol(mat)]
dsn <- deseason(val, cycle.window = 24L)

tmp <- foreach(i = 1982:2015, .combine = "cbind") %do% {
  dsn[grep(paste0("^MCD.", i), names(val))]
}
colnames(tmp) <- as.character(1982:2015)

diss <- diss(t(tmp), "EUCL")
clust <- chclust(diss)
plot(clust)

c10 <- cutree(clust, 10)
cluster.stats(diss, c10)

diss_matrix <- diss(t(tmp), "EUCL")
clust_result <- hclust(diss_matrix, "complete")
plot(clust_result)

c5 <- cutree(clust_result, 5)
cluster.stats(diss_matrix, c5)

bfs <- bfast(ts(val, start = c(1982, 1), end = c(2015, 12), deltat = 1/24), 
             season = "harmonic", max.iter = 5L, hpc = "foreach")
plot(bfs)
