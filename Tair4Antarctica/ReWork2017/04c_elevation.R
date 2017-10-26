
alt <- raster("/media/hanna/data/Antarctica/data/Auxiliary/Overall/dem_crop.tif")
alt <- crop(alt,c(323788.2 ,556632.9,-1353055,-1081403))


alt_recl <- alt
alt_recl[alt<=1000] <- 1
alt_recl[alt>1000&alt<=2000] <- 2
alt_recl[alt>2000&alt<=3000] <- 3
alt_recl[alt>3000] <- 4


