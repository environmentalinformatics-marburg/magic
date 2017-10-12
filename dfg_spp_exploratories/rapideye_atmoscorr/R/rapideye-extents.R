library(Orcs)

cl = makePSOCKcluster(3L)
jnk = clusterEvalQ(cl, library(raster))

out = vector("list", 3L); n = 1L
for (exploratory in c("alb", "hai", "sch")) {
  raw <- list.files(exploratory, pattern = "_ortho.tif$", full.names = TRUE)
  
  lst = parLapply(cl, raw, function(i) {
    rst = brick(i)
    ext = extent(rst)
    list(xmin(ext), xmax(ext), ymin(ext), ymax(ext), projection(rst))
  })
  
  ext = numeric(4L)
  for (i in 1:4)  {
    ext[i] = if (i %in% c(1, 3)) {
      min(sapply(lst, "[[", i))
    } else {
      max(sapply(lst, "[[", i))
    }
  }
  
  ext = extent(ext)
  spy = ext2spy(ext, unique(sapply(lst, "[[", 5)))
  spy = SpatialPolygonsDataFrame(spy, data.frame(loc = exploratory))
  spy = spTransform(spy, CRS = CRS("+init=epsg:4326"))
  writeOGR(spy, "shp", exploratory, "ESRI Shapefile"
           , check_exists = TRUE, overwrite_layer = TRUE)
  
  out[[n]] = spy; names(out)[n] = exploratory
  n = n + 1L
}

ref = do.call("rbind", out)
stopCluster(cl)

# xmn = unique(sapply(lst, "[[", 1))
# xmx = unique(sapply(lst, "[[", 2))
# ymn = unique(sapply(lst, "[[", 3))
# ymx = unique(sapply(lst, "[[", 4))
