large_utm = readRDS(file.path(repo, "inst/extdata/uniformExtent.rds"))
large <- spTransform(large_utm, CRS = CRS("+init=epsg:4326"))

ls8 = list.files("landsat", pattern = "^LC08.*T1.tif$"
                 , recursive = TRUE, full.names = TRUE)

crp = vector("list", length(ls8)); n = 1L
for (i in ls8) {
  cat("File", basename(i), "is in, start processing ...\n")
  
  rst = crop(stack(i), large_utm, snap = "out")
  val = getValues(rst)
  nan = apply(val, 1, FUN = function(x) all(x == 0))
  rst[nan] = NA; rm(val)
  
  for (j in 1:10) {
    adj = adjacent(rst, which(nan), directions = 4, pairs = FALSE)
    adj = unique(adj)
    rst[adj] = NA
    nan = is.na(rst[])
  }
  
  crp[[n]] = rst; n = n + 1L
}

right = merge(crp[[1]], crp[[2]])
hsm = histMatch(crp[[3]], right)
rgb = merge(right, hsm)
rgb = trim(projectRaster(rgb, crs = "+init=epsg:4326", method = "ngb")
           , filename = file.path(repo, "inst/extdata/lc8.tif")
           , overwrite = TRUE)

small = extent(c(39 + 36 / 60, 40, 6 + 42 / 60, 7 + 6 / 60))
small = as(small, "SpatialPolygons"); proj4string(small) = "+init=epsg:4326"

p_rgb = spplot(ltm_mts[[1]], colorkey = FALSE, col.regions = "transparent"
               , scales = list(draw = TRUE), sp.layout = list(
                 Rsenal::rgb2spLayout(rgb, c(.00775, .99225))
                 , list("sp.polygons", small, col = "black", fill = "transparent", lwd = 2)
               ))
