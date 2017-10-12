i <- 2
ids <- cellFromPolygon(gms, plots[i, ], weights = TRUE)[[1]]
pct <- sapply(ids[, 2], function(j) j / sum(ids[, 2]))
val1 <- mat[ids, ]
val1 <- val1[grep("2003001", names(val1)):grep("2015349", names(val1))]

mds <- list.files(paste0("data/rasters/", exploratory, 
                         "/MYD13Q1.006/mvc"), 
                  pattern = "NDVI.tif$", full.names = TRUE)
mds <- mds[grep("2003001", mds):grep("2015349", mds)]
mds <- stack(mds)
mat_mds <- as.matrix(mds)
val2 <- mat_mds[ids, ]

plot(val2, pch = 20); lines(val2)
lines(val1, col = "orange")

library(zoo)
?rollapply
val3 <- rollapply(val2, width = 5L, FUN = function(x) max(x, na.rm = TRUE), na.pad = TRUE)
lines(val3, col = "green")

library(kza)
?kza
val4 <- kza(val2, m = 5, k = 5, impute_tails = TRUE)$kz
lines(val4, col = "red")
