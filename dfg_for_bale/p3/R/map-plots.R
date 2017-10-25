### environment -----

## working directory
setwd("dfg_for_bale/p3")

## libraries and functions
# devtools::install_github("environmentalinformatics-marburg/Rsenal", local = FALSE)
# devtools::install_github("fdetsch/Orcs", local = FALSE)
lib = c("Orcs", "doParallel", "Rsenal", "latticeExtra", "grid", "rgeos"
        , "stargazer", "Hmisc", "OpenStreetMap", "dismo")
Orcs::loadPkgs(lib)

source("../R/panel.smoothconts.R")
source("../R/visDEM.R")

## parallelization 
cl = makeCluster(detectCores() * .75)
registerDoParallel(cl)

## paths
dir_dat = "../../../../data/bale/"


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
nms = "data/osm_bale.tif"
rgb = if (file.exists(nms)) {
  brick(nms)
} else {
  tmp = openmap(c(ymax(ext), xmin(ext)), c(ymin(ext), xmax(ext))
                , type = "bing", minNumTiles = 40L)
  tmp = raster(tmp)
  trim(projectRaster(tmp, crs = "+init=epsg:32637", method = "ngb")
       , filename = nms, datatype = "INT1U")
}

## create contour lines
p_dem = visDEM(dem, seq(1250, 4500, 100), col = "black", labcex = .6
               , labels = NULL)

## create figures, one with contour lines superimposed upon a semi-transparent
## satellite image, and one with the non-transparent satellite image only
alpha = c(.9, 1); nms = c("map_bale_dem.tiff", "map_bale.tiff")
for (i in 1) {
  rsl = rgb2spLayout(rgb, quantiles = c(0, 1), alpha = alpha[i])
  
  p_bale = spplot(rgb[[1]], col.regions = "transparent", colorkey = FALSE
                  , scales = list(draw = TRUE, cex = .8, alternating = 3
                                  , x = list(at = seq(560000, 620000, 10000))
                                  , y = list(rot = 90))
                  , sp.layout = rsl
                  , maxpixels = ncell(rgb))
  
  if (alpha[i] != 1) {
    p_bale = p_bale + as.layer(p_dem)
  }
  
  tiff(file.path("img", nms[i]), width = 42, height = 29.7, units = "cm"
       , res = 300, compression = "lzw")
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
  draw.key(key = list(title = "Bale Mountains"
                      , cex.title = 1.1
                      , lines.title = 1.5
                      , points = list(fill = c("grey65", "#f1a340"), pch = c(22, 24)
                                      , col = "white", cex = 2, lwd = 2)
                      , text = list(c("Sampling plot", "Settlement"))
                      , background = "white", alpha.background = .8
                      , padding.text = 3), 
           draw = TRUE)
  
  # epsg code
  upViewport()
  grid.stext("EPSG:32637\n\uA9 OpenStreetMap contributors"
                     , x = unit(.99, "npc"), y = unit(.01, "npc")
                     , just = c("right", "bottom") , gp = gpar(cex = .8))
  invisible(dev.off())
}


### visualize settlements (OpenStreetMap) -----

for (i in 1:length(settlements)) {
  
  stm = tolower(settlements[i, ]@data$name)
  lbl = if (is.na(stm)) {
    "Unknown"
  } else {
    paste(sapply(strsplit(stm, " "), capitalize), collapse = " ")
  }
  stm = gsub(" ", "-", stm)
  
  cat(lbl, "is in, start processing.\n")
  
  ## retrieve aerial image
  bff_small = gBuffer(settlements[i, ], width = 100, quadsegs = 250)
  bff = gBuffer(settlements[i, ], width = 2000, quadsegs = 250)
  ext = extend(extent(bff), c(1e3, 100))
  ext = spTransform(ext2spy(ext, "+init=epsg:32637"), CRS("+init=epsg:4326"))
  
  nms = paste0(file.path("data/osm", paste0("osm_", stm)), ".tif")
  rgb = if (file.exists(nms)) {
    brick(nms)
  } else {
    tmp = openmap(c(ymax(ext), xmin(ext)), c(ymin(ext), xmax(ext))
                  , type = "bing", minNumTiles = 40L)
    tmp = raster(tmp)
    
    trim(projectRaster(tmp, crs = "+init=epsg:32637", method = "ngb")
         , filename = nms, datatype = "INT1U")
  }
  
  ## create contour lines
  tmp = crop(dem, rgb, snap = "out")
  ele = extract(tmp, settlements[i, ])
  p_dem = visDEM(tmp, seq(1250, 4500, 25), col = "black", labcex = .6
                 , labels = NULL, cex = 2)
  
  ## create figures, one with contour lines superimposed upon a semi-transparent
  ## satellite image, and one with the non-transparent satellite image only
  alpha = c(.9, 1)
  nms = c(paste("map", stm, "dem.tiff", sep = "_"), paste0("map_", stm, ".tiff"))
  for (j in 1) {
    rsl = rgb2spLayout(rgb, quantiles = c(0, 1), alpha = alpha[j])
    
    p_bale = spplot(rgb[[1]], col.regions = "transparent", colorkey = FALSE
                    , scales = list(draw = TRUE, cex = .8, alternating = 3
                                    , y = list(rot = 90))
                    , sp.layout = rsl, maxpixels = ncell(rgb))
    
    if (alpha[j] != 1) {
      p_bale = p_bale + as.layer(p_dem)
    }
    
    tiff(file.path("img/settlements/osm", nms[j]), width = 42, height = 29.7
         , units = "cm", res = 300, compression = "lzw")
    plot.new()
    
    crd = as.numeric(coordinates(settlements[i, ]))
    crd[1] = crd[1] + 250
    print(p_bale + 
            layer(sp.points(settlements[i, ], pch = 24, col = "white"
                            , fill = "black", cex = 2, lwd = 2)) + 
            layer(sp.polygons(bff, lty = 2, lwd = 2)) + 
            layer(sp.polygons(bff_small, lwd = 2)), newpage = FALSE)

    # legend
    downViewport(trellis.vpname("figure"))
    vp_key = viewport(x = .875, y = .87, width = .1, height = .1
                      , just = c("left", "bottom"))
    pushViewport(vp_key)
    draw.key(key = list(title = paste0(lbl, "\n(", ele, " m.a.s.l.)")
                        , cex.title = 1.1
                        , lines.title = 1.5
                        , lines = list(lty = 1:2, lwd = 2)
                        , text = list(c("0.1 km", "2.0 km"))
                        , background = "white", alpha.background = .8
                        , padding.text = 3), 
             draw = TRUE)
    
    # epsg code
    upViewport()
    grid.stext("EPSG:32637\n\uA9 OpenStreetMap contributors"
               , x = unit(.99, "npc"), y = unit(.01, "npc")
               , just = c("right", "bottom") , gp = gpar(cex = .8))
    # grid.stext(lbl, gp = gpar(cex = 1.8), just = c("left", "bottom")
    #            , x = unit(.52, "npc"), y = unit(.5, "npc"))
    
    invisible(dev.off())
  }
}


### visualize settlements (dismo) -----

rps <- "../../dfg_for_kilimanjaro/osm_google_kili/src/"
source(paste0(rps, "getTileCenters.R")); source(paste0(rps, "getGoogleTiles.R"))

tls <- getTileCenters(4000, 800)

## download (and merge) google maps tiles
rgb = foreach(i = 1:length(settlements), .packages = c("raster", "rgeos")
              , .export = "getGoogleTiles") %dopar% {
                
  stm = tolower(settlements[i, ]@data$name)
  stm = gsub(" ", "-", stm)
  
  bff = gBuffer(settlements[i, ], width = 2000, quadsegs = 250)
  ext = extend(extent(bff), c(1e3, 100))
  
  nms_dsm = paste0(file.path("data/dsm", paste0("dsm_", stm)), ".tif")
  ext_dsm = extend(ext, c(0, 0, 250, 0))
  
  if (file.exists(nms_dsm)) {
    brick(nms_dsm)
  } else {
    
    # # retrieve aerial image (single image, coarse spatial resolution)
    #   tmp = gmap(ext2spy(ext_dsm, "+init=epsg:32637"), type = "satellite"
    #              , scale = 2, rgb = TRUE)
    
    # retrieve aerial image (single tiles, higher spatial resolution)
    odr = file.path("data/dsm", stm)
    ofl = file.path(odr, paste0(stm, ".tif"))
    
    tmp = if (file.exists(ofl)) {
      brick(ofl)
    } else {
      getGoogleTiles(tile.cntr = tls, location = settlements[i, ]
                     , plot.res = 800, path.out = odr, plot.bff = 100
                     , loc_name = "name", scale = 2, rgb = TRUE
                     , type = "satellite", prefix = paste0(stm, "_tile_")
                     , mosaic = ofl)
    }
    
    tmp = projectRaster(tmp, crs = "+init=epsg:32637", method = "ngb")
    crop(tmp, ext, snap = "out", filename = nms_dsm, datatype = "INT1U")
  }
}

for (i in 1:length(settlements)) {
  
  stm = tolower(settlements[i, ]@data$name)
  lbl = if (is.na(stm)) {
    "Unknown"
  } else {
    paste(sapply(strsplit(stm, " "), capitalize), collapse = " ")
  }
  stm = gsub(" ", "-", stm)
  
  cat(lbl, "is in, start processing.\n")

  bff_small = gBuffer(settlements[i, ], width = 100, quadsegs = 250)
  bff = gBuffer(settlements[i, ], width = 2000, quadsegs = 250)
  
  ## create contour lines
  tmp = crop(dem, rgb[[i]], snap = "out")
  ele = extract(tmp, settlements[i, ])
  p_dem = visDEM(tmp, seq(1250, 4500, 25), col = "black", labcex = .6
                 , labels = NULL)
  
  ## create figures, one with contour lines superimposed upon a semi-transparent
  ## satellite image, and one with the non-transparent satellite image only
  alpha = c(.9, 1)
  nms = c(paste("map", stm, "dem.tiff", sep = "_"), paste0("map_", stm, ".tiff"))
  for (j in 1) {
    rsl = rgb2spLayout(rgb[[i]], quantiles = c(0, 1), alpha = alpha[j])
    
    p_bale = spplot(rgb[[i]][[1]], col.regions = "transparent", colorkey = FALSE
                    , scales = list(draw = TRUE, cex = .8, alternating = 3
                                    , y = list(rot = 90))
                    , sp.layout = rsl, maxpixels = ncell(rgb))
    
    if (alpha[j] != 1) {
      p_bale = p_bale + as.layer(p_dem)
    }
    
    tiff(file.path("img/settlements/dsm", nms[j]), width = 42, height = 29.7
         , units = "cm", res = 300, compression = "lzw")
    plot.new()
    
    crd = as.numeric(coordinates(settlements[i, ]))
    crd[1] = crd[1] + 250
    print(p_bale + 
            layer(sp.points(settlements[i, ], pch = 24, col = "white"
                            , fill = "black", cex = 2, lwd = 2)) + 
            layer(sp.polygons(bff, lty = 2, lwd = 2)) + 
            layer(sp.polygons(bff_small, lwd = 2)), newpage = FALSE)
    
    # legend
    downViewport(trellis.vpname("figure"))
    vp_key = viewport(x = .875, y = .87, width = .1, height = .1
                      , just = c("left", "bottom"))
    pushViewport(vp_key)
    draw.key(key = list(title = paste0(lbl, "\n(", ele, " m.a.s.l.)")
                        , cex.title = 1.1
                        , lines.title = 1.5
                        , lines = list(lty = 1:2, lwd = 2)
                        , text = list(c("0.1 km", "2.0 km"))
                        , background = "white", alpha.background = .8
                        , padding.text = 3), 
             draw = TRUE)

    # epsg code
    upViewport()
    grid.stext("EPSG:32637\n\uA9 Google, TerraMetrics"
                       , x = unit(.99, "npc"), y = unit(.01, "npc")
                       , just = c("right", "bottom") , gp = gpar(cex = .8))
    # grid.stext(lbl, gp = gpar(cex = 1.8), just = c("left", "bottom")
    #                    , x = unit(.52, "npc"), y = unit(.5, "npc"))
    invisible(dev.off())
  }
}


### elevation -----

lbl = sapply(1:length(settlements), function(i) {
  stm = tolower(settlements[i, ]@data$name)
  if (is.na(stm)) {
    "<Unknown>"
  } else if (stm == "abel kassim ii") {
    "Abel Kassim II"
  } else {
    paste(sapply(strsplit(stm, " "), capitalize), collapse = " ")
  }
})

ele = extract(dem, settlements)
dat = data.frame(Settlement = lbl, Elevation = ele)
dat = dat[order(dat$Elevation), ]

stargazer(dat, summary = FALSE, rownames = FALSE)

## close parallel backend
stopCluster(cl)