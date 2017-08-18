### environment -----

## working directory
repo = file.path(getwd(), "dfg_for_bale/p1")
setwd("/media/fdetsch/XChange/bale")

## packages and functions
# devtools::install_github("environmentalinformatics-marburg/chirps")
library(heavyRain)
library(Rsenal)
library(RStoolbox)

source(file.path(repo, "R/visDEM.R"))
source(file.path(repo, "R/panel.smoothconts.R"))


### process -----

odr = "chirps/africa_monthly"
# fls <- getCHIRPS("africa", "tifs", "monthly", cores = 3L, dsn = odr)
# tfs <- extractChirps(fls, dsn = file.path(odr, "tfs"), cores = 3L)

## reimport extracted images
tfs <- list.files(file.path(odr, "tfs"), full.names = TRUE, 
                  pattern = "^chirps.*.tif$")
rst <- stack(tfs)

## clip images in parallel
ref <- spTransform(readRDS(file.path(repo, "inst/extdata/uniformExtent.rds")), 
                   CRS = "+init=epsg:4326")

cl <- makePSOCKcluster(detectCores() * .75)
jnk = clusterEvalQ(cl, library(raster))
clusterExport(cl, "ref")

crp <- stack(parLapply(cl, unstack(rst), function(i) {
    raster::crop(i, ref, snap = "out")
}))


### monthly anomalies in late 2015 -----

## overview chart
clr = colorRampPalette(brewer.pal(4, "PuOr"))

tiff("~/Downloads/move/rainfall-anomalies.tiff", width = 22, height = 16, 
     units = "cm", res = 300, compression = "lzw")
par(mfrow = c(2, 3))
for (i in 7:12) {
  lbl = paste0("2015.", formatC(i, width = 2, flag = "0"))
  plot(dsn[[grep(lbl, tfs)]], main = lbl, zlim = c(-70, 70), col = clr(100))
  lines(rasterToContour(dem_utm), col = "grey50")
}
dev.off()

## long-term monthly means
y36 = crp[[1:grep("2016.12", tfs)]]

clusterExport(cl, "y36")
ltm_mts = stack(parLapply(cl, 8:10, function(i) {
  rst = y36[[seq(i, nlayers(y36), 12)]]
  calc(rst, fun = mean, na.rm = TRUE)
}))

small = extent(c(39 + 36 / 60, 40, 6 + 42 / 60, 7 + 6 / 60))
small = as(small, "SpatialPolygons"); proj4string(small) = "+init=epsg:4326"

lbl = c("b) Aug 2015", "c) Sep 2015", "d) Oct 2015")
p_mts = lapply(1:nlayers(ltm_mts), function(i) {
  spplot(ltm_mts[[i]], colorkey = FALSE, col.regions = "transparent"
         , scales = list(draw = TRUE), sp.layout = list(
           list("sp.polygons", small, col = "black", fill = "transparent", lwd = 2)
           , list("sp.text", c(39.46, 6.36), lbl[i], font = 2, cex = .8)
         )) + 
    as.layer(visDEM(disaggregate(ltm_mts[[i]], 8, "bilinear"), seq(50, 150, 25)
                    , labcex = .6, col = "black"
                    , labels = as.character(seq(50, 150, 25))))
})

## anomalies
anm = crp[[grep("2015.08|2015.09|2015.10", tfs)]]
anm = (anm - ltm_mts) / ltm_mts

# areas = vector("list", nlayers(anm))
# for (n in 1:nlayers(anm)) {
#   cat("Layer", n, "out of", nlayers(anm), "is in, start processing ...\n")
#   
#   areas[[n]] = lapply(seq(-.15, -.45, -.15), function(i) {
#     tmp = anm[[n]]
#     
#     dag = disaggregate(tmp, 50, "bilinear")
#     ids = dag[] > i
#     
#     if (length(which(ids)) == ncell(dag)) {
#       return(NULL)
#     } else {
#       dag[ids] = NA
#       
#       spy = rasterToPolygons(dag)
#       spy = maptools::unionSpatialPolygons(spy, IDs = rep(i, length(spy)))
#       return(spy)
#     }
#   })
# }

clr = c(rev(brewer.pal(3, "Reds")), "transparent")
p_anm = lapply(1:nlayers(anm), function(i) {
  p_mts[[i]] + 
    as.layer(spplot(anm[[i]], at = seq(-.6, .2, .2), col.regions = clr)
             , under = TRUE)
})

## landsat 8 image
ref_utm = extent(projectExtent(ltm_mts, crs = "+init=epsg:32637"))
ref_utm = as(ref_utm, "SpatialPolygons")
proj4string(ref_utm) = "+init=epsg:32637"

# ls8 = list.files("landsat", pattern = "^LC08.*T1.tif$"
#                  , recursive = TRUE, full.names = TRUE)
# 
# crp = vector("list", length(ls8)); n = 1L
# for (i in ls8) {
#   cat("File", basename(i), "is in, start processing ...\n")
#   
#   rst = crop(stack(i), ref_utm, snap = "out")
#   val = getValues(rst)
#   nan = apply(val, 1, FUN = function(x) all(x == 0))
#   rst[nan] = NA; rm(val)
#   
#   for (j in 1:10) {
#     adj = adjacent(rst, which(nan), directions = 4, pairs = FALSE)
#     adj = unique(adj)
#     rst[adj] = NA
#     nan = is.na(rst[])
#   }
#   
#   crp[[n]] = rst; n = n + 1L
# }
# 
# right = merge(crp[[1]], crp[[2]])
# hsm = histMatch(crp[[3]], right)
# rgb = merge(right, hsm); rm(list = c("right", "hsm"))
# rgb = trim(projectRaster(rgb, crs = "+init=epsg:4326", method = "ngb")
#            , filename = file.path(repo, "inst/extdata/lc8.tif")
#            , overwrite = TRUE, datatype = "INT1U")

rgb = brick(file.path(repo, "inst/extdata/lc8.tif"))

rsl = rgb2spLayout(rgb, c(0, 1))
rsl_crp = rgb2spLayout(crop(rgb, small), c(0, 1))
p_rgb = spplot(ltm_mts[[1]], colorkey = FALSE, col.regions = "transparent"
               , scales = list(draw = TRUE, y = list(rot = 90))
               , sp.layout = list(
                 rsl, rsl_crp
                 , list("sp.polygons", small, col = "black", fill = "transparent", lwd = 2)
                 , list("sp.text", c(39.46, 6.36), "a) Landsat 8", font = 2, cex = .8)
               ))

## create figure in reber et al. 2017
p = Orcs::latticeCombineGrid(list(p_rgb, p_anm[[1]], p_anm[[2]], p_anm[[3]]))

tiff(file.path(repo, "out/figure-reber.tiff"), compression = "lzw"
     , width = 18, height = 20, units = "cm", res = 300)
plot.new()

vp1 = viewport(x = 0, y = 0, width = .875, height = 1, just = c("left", "bottom"))
pushViewport(vp1)
print(p, newpage = FALSE)

downViewport(trellis.vpname("figure"))
vp2 = viewport(x = 1.15, y = .5, width = .1, height = 1)
pushViewport(vp2)
draw.colorkey(key = list(col = clr, width = .75, height = .4
                         , at = seq(-.6, .2, .2)
                         , labels = list(labels = seq(-60, 20, 20)
                                         , at = round(seq(-.6, .2, .2), 1L)))
              , draw = TRUE)
grid.text("Rain anomalies\n[%]", x = .4, y = .8, just = c("center", "top")
          , gp = gpar(font = 2, cex = .85))

dev.off()

## deregister parallel backend
stopCluster(cl)
