### environment -----

## working directory
setwd("dfg_for_bale/p3")

## libraries and functions
# devtools::install_github("environmentalinformatics-marburg/Rsenal", local = FALSE)
# devtools::install_github("fdetsch/Orcs", local = FALSE)
library(Orcs)
library(foreach)
library(grid)
library(latticeExtra)

source("../p1/R/panel.smoothconts.R")
source("../p1/R/visDEM.R")

## paths
dir_dat = "D:/data/bale"


### data import -----

## plots from 1st field phase
plots = read.csv2(file.path(dir_dat, "shp/p3/Study Plots.csv"))
coordinates(plots) = ~ Longitude + Latitude
proj4string(plots) = "+init=epsg:4326"

## settlements from reber's field survey
settlements = shapefile(file.path(dir_dat, "shp/settlements.shp"))
settlements = subset(settlements, type %in% c("towns", "villages"))

ref = union(ext2spy(plots), ext2spy(settlements))
ext = extend(extent(ref), c(.14, .05))

## digital elevation model
dem = raster(file.path(dir_dat, "dem/dem_srtm_01.tif"))
dem = crop(dem, ext, snap = "out")

## project data
plots = spTransform(plots, CRS = CRS("+init=epsg:32637"))
settlements = spTransform(settlements, CRS = CRS("+init=epsg:32637"))

nms = "data/dem_bale.tif"
dem = if (file.exists(nms)) {
  raster(nms)
} else {
  trim(projectRaster(dem, crs = "+init=epsg:32637", method = "ngb")
       , filename = "data/dem_bale.tif", datatype = "INT2S")
}

### visualize study area -----

## retrieve aerial image
rgb = OpenStreetMap::openmap(c(ymax(ext), xmin(ext)), c(ymin(ext), xmax(ext))
                             , type = "bing", minNumTiles = 40L)
rgb = raster(rgb)
rgb = trim(projectRaster(rgb, crs = "+init=epsg:32637", method = "ngb")
           , filename = "data/osm_bale.tif", datatype = "INT1U"
           , overwrite = TRUE)

## create contour lines
p_dem = visDEM(dem, seq(1250, 4500, 50), col = "black", labcex = .6
               , labels = NULL)

## create figures, one with contour lines superimposed upon a semi-transparent
## satellite image, and one with the non-transparent satellite image only
foreach(alpha = c(.8, 1), nms = c("map_bale_dem.tiff", "map_bale.tiff")) %do% {
  rsl = Rsenal::rgb2spLayout(rgb, quantiles = c(0, 1), alpha = alpha)
          
  p_bale = spplot(rgb[[1]], col.regions = "transparent", colorkey = FALSE
                  , scales = list(draw = TRUE, cex = .8, alternating = 3
                                  , x = list(at = seq(560000, 620000, 10000))
                                  , y = list(rot = 90))
                  , sp.layout = rsl
                  , maxpixels = ncell(rgb))

  if (alpha != 1) {
    p_bale = p_bale + as.layer(p_dem)
  }
  
  tiff(file.path("img", nms), width = 42, height = 29.7, units = "cm", res = 500
       , compression = "lzw")
  plot.new()
  
  print(p_bale + 
          layer(sp.points(plots, pch = 22, col = "white", fill = "grey65"
                          , cex = 2, lwd = 2)) + 
          layer(sp.points(settlements, pch = 24, col = "white", fill = "#f1a340"
                          , cex = 2, lwd = 2)), newpage = FALSE)
  
  # legend
  downViewport(trellis.vpname("figure"))
  vp_key = viewport(x = .875, y = .9, width = .1, height = .1
                    , just = c("left", "bottom"))
  pushViewport(vp_key)
  draw.key(key = list(points = list(fill = c("grey65", "#f1a340"), pch = c(22, 24)
                                    , col = "white", cex = 2, lwd = 2)
                      , text = list(c("Sampling plot", "Settlement"))
                      , background = "white", alpha.background = .8
                      , padding.text = 3), 
           draw = TRUE)
  
  # epsg code
  upViewport()
  Rsenal::grid.stext("EPSG:32637\n\uA9 OpenStreetMap contributors"
                     , x = unit(.99, "npc"), y = unit(.01, "npc")
                     , just = c("right", "bottom") , gp = gpar(cex = .8))
  invisible(dev.off())
}


### visualize settlements -----

for (i in 1:length(settlements)) {

  stm = tolower(settlements[i, ]@data$name)
  lbl = paste(sapply(strsplit(stm, " "), Hmisc::capitalize), collapse = " ")
  stm = gsub(" ", "-", stm)
  
  cat(lbl, "is in, start processing.\n")
  
  ## retrieve aerial image
  bff = rgeos::gBuffer(settlements[i, ], width = 2000, quadsegs = 250)
  ext = extend(extent(bff), c(1e3, 100))
  # rgb = dismo::gmap(ext2spy(ext, "+init=epsg:32637"), type = "satellite"
  #                   , scale = 2, rgb = TRUE)
  ext = spTransform(ext2spy(ext, "+init=epsg:32637"), CRS("+init=epsg:4326"))
  
  nms = paste0(file.path("data/osm", paste0("osm_", stm)), ".tif")
  rgb = if (file.exists(nms)) {
    brick(nms)
  } else {
    tmp = OpenStreetMap::openmap(c(ymax(ext), xmin(ext)), c(ymin(ext), xmax(ext))
                                 , type = "bing", minNumTiles = 40L)
    tmp = raster(tmp)
    
    trim(projectRaster(tmp, crs = "+init=epsg:32637", method = "ngb")
         , filename = nms, datatype = "INT1U")
  }
  
  ## create contour lines
  tmp = crop(dem, rgb, snap = "out")
  p_dem = visDEM(tmp, seq(1250, 4500, 10), col = "black", labcex = .6
                 , labels = NULL)
  
  ## create figures, one with contour lines superimposed upon a semi-transparent
  ## satellite image, and one with the non-transparent satellite image only
  jnk = foreach(alpha = c(.8, 1), nms = c(paste("map", stm, "dem.tiff", sep = "_")
                                          , paste0("map_", stm, ".tiff"))) %do% {
    rsl = Rsenal::rgb2spLayout(rgb, quantiles = c(0, 1), alpha = alpha)
    
    p_bale = spplot(rgb[[1]], col.regions = "transparent", colorkey = FALSE
                    , scales = list(draw = TRUE, cex = .8, alternating = 3
                                    , y = list(rot = 90))
                    , sp.layout = rsl, maxpixels = ncell(rgb))
    
    if (alpha != 1) {
      p_bale = p_bale + as.layer(p_dem)
    }
    
    tiff(file.path("img/settlements", nms), width = 42, height = 29.7
         , units = "cm", res = 300, compression = "lzw")
    plot.new()
    
    crd = as.numeric(coordinates(settlements[i, ]))
    crd[1] = crd[1] + 250
    print(p_bale + 
            layer(sp.points(settlements[i, ], pch = 24, col = "white"
                            , fill = "black", cex = 2, lwd = 2)) + 
            layer(sp.polygons(bff, lty = 2, lwd = 2)), newpage = FALSE)
    
    # epsg code
    downViewport(trellis.vpname("figure"))
    Rsenal::grid.stext("EPSG:32637\n\uA9 OpenStreetMap contributors"
                       , x = unit(.99, "npc"), y = unit(.01, "npc")
                       , just = c("right", "bottom") , gp = gpar(cex = .8))
    Rsenal::grid.stext(lbl, gp = gpar(cex = 1.8), just = c("left", "bottom")
                       , x = unit(.52, "npc"), y = unit(.5, "npc"))
    invisible(dev.off())
  }
}
