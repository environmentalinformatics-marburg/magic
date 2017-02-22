### environmental stuff -----

rm(list = ls(all = TRUE))

## packages and functions
library(raster)
library(RColorBrewer)
library(latticeExtra)


### visualization: trends -----

## exploratories
library(ESD)
exp <- lapply(c("alb", "hai", "sch"), function(i) {
  readRDS(system.file("extdata", paste0(i, ".rds"), package = "ESD"))
})

## aerial images
rgb <- lapply(exp, function(i) {
  ext <- suppressWarnings(rgeos::gBuffer(i, width = .01))
  Rsenal::kiliAerial(template = ext, minNumTiles = 12L)
})

## seasonality
source("R/fig05__seasonality.R")

## colors
clr <- colorRampPalette(brewer.pal(5, "BrBG"))

fls <- list.files("out", pattern = "trd_mk05.*.tif$", full.names = TRUE)

lst <- lapply(1:length(fls), function(i) {
  rst <- raster::raster(fls[i])

  plt <- substr(unlist(strsplit(fls[i], "_"))[[3]], 1, 3)

  p2 <- spplot(rst, scales = list(draw = TRUE, cex = .9), maxpixels = ncell(rgb[[i]]),
               col.regions = "transparent", colorkey = FALSE,
               sp.layout = mapview::rgb2spLayout(rgb[[i]], c(.01, .95)))

  p1 <- spplot(rst, scales = list(draw = TRUE, cex = .9), colorkey = FALSE,
               # colorkey = list(height = .5, space = "top"),
               main = list(plt, hjust = 0.5, vjust = 1, cex = 1.4), 
               col.regions = clr(100), at = seq(-.41, .41, .01)) + 
    as.layer(p2)
  
  p2 <- spplot(rst, scales = list(draw = TRUE, cex = .9), 
               main = list(plt, hjust = 0.5, vjust = 1, cex = 1.4), 
               col.regions = clr(100), at = seq(-.41, .41, .01))
  
  p <- Rsenal::latticeCombineGrid(list(p1, p2, ssn[[i]][[1]], ssn[[i]][[2]]), 
                                  layout = c(2, 2))
  
  png(paste0("out/trd_mk05_ssn_", plt, ".png"), width = 22, height = 28, 
      units = "cm", res = 500)
  grid.newpage()
  
  vp0 <- viewport(x = 0, y = .1, width = 1, height = .8,
                  just = c("left", "bottom"), name = "figure.vp")
  pushViewport(vp0)
  print(p, newpage = FALSE)

  ## colorkey: seasonal shift
  downViewport(trellis.vpname("figure"))
  vp1 <- viewport(x = .25, y = ifelse(plt == "alb", -.18, -.12),
                  height = 0.07, width = .3,
                  just = c("center", "bottom"),
                  name = "key1.vp")
  pushViewport(vp1)
  draw.colorkey(key = list(col = rev(brewer.pal(9, "RdBu")), width = 1, height = .5,
                           at = seq(-1.5, 1.5, 1),
                           labels = list(labels = c("-", "0", "+"), at = c(-1, 0, 1)),
                           space = "bottom"), draw = TRUE)
  grid.text("Seasonal shift", x = 0.5, y = ifelse(plt == "alb", -.25, -.075), 
            just = c("centre", "top"), gp = gpar(font = 2, cex = .85))

  ## colorkey: Delta NDVI_EOTmax
  upViewport()
  vp2 <- viewport(x = .75, y = ifelse(plt == "alb", -.18, -.12),
                  height = 0.07, width = .35,
                  just = c("center", "bottom"),
                  name = "key2.vp")
  pushViewport(vp2)
  draw.colorkey(key = list(col = cols_div(20), width = 1,
                           at = seq(-.07, .07, .01),
                           space = "bottom"), draw = TRUE)
  grid.text(expression(bold(Delta ~ "NDVI"[EOTmax])), 
            x = 0.5, y = ifelse(plt == "alb", -.25, -.075),
            just = c("centre", "top"), gp = gpar(font = 2, cex = .85))
  
  ## colorkey: trends
  upViewport()
  vp3 <- viewport(x = 1.075, y = .55,
                  height = .4, width = .3,
                  just = c("center", "bottom"),
                  name = "key3.vp")
  pushViewport(vp3)
  draw.colorkey(key = list(col = clr(100), width = 1,
                           at = seq(-.41, .41, .01),
                           space = "right"), draw = TRUE)
  grid.text(expression(bold(tau)), x = 0.5, y = ifelse(plt == "alb", 1.175, 1.1),
            just = c("centre", "top"), gp = gpar(font = 2, cex = .95))
  
  dev.off()
})

