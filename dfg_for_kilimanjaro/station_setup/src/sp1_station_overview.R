library(raster)
library(latticeExtra)
library(Rtography)
library(gridExtra)
library(gnumeric)
library(stargazer)

path <- "/media/tims_ex/kilimanjaro_sp1_station_overview"
setwd(path)

colorimage <- stack("kili_from_bing.tif")

colim.recl <- reclassify(colorimage, cbind(NA, 1))
colim.recl[colim.recl < 0] <- 1

### use downloaded map for sp raster layout definition
cols <- rgb(colim.recl[[1]][] / 255, 
            colim.recl[[2]][] / 255, 
            colim.recl[[3]][] / 255)

map.cols <- matrix(cols,
                   nrow = colim.recl@nrows,
                   ncol = colim.recl@ncols)

attr(map.cols, "class") <- c("ggmap", "raster")
attr(map.cols, "bb") <- data.frame(ll.y = colim.recl@extent@ymin,
                                   ll.x = colim.recl@extent@xmin,
                                   ur.y = colim.recl@extent@ymax,
                                   ur.x = colim.recl@extent@xmax)

bbMap <- attr(map.cols, 'bb')
latCenter <- with(bbMap, ll.y + ur.y)/2
lonCenter <- with(bbMap, ll.x + ur.x)/2
height <- with(bbMap, ur.y - ll.y)
width <- with(bbMap, ur.x - ll.x)

## Use sp.layout of spplot: a list with the function and its
## arguments
sp.raster <- list('grid.raster', map.cols,
                  x=lonCenter, y=latCenter,
                  width=width, height=height,
                  default.units='native')

sheets <- c("ta", "precip", "swdr", "aws")

stns <- lapply(seq(sheets), function(i) {
  dat <- read.gnumeric.sheet("ki_config_station_inventory_detail.ods",
                             sheet = sheets[i], stringsAsFactors = TRUE, 
                             head = TRUE)
  dat <- dat[!is.na(dat$EASTING), ]
  dat <- subset(dat, dat$DATE_END == "2099-12-31")
  coordinates(dat) <- c("EASTING", "NORTHING")
  dat@proj4string <- CRS("+init=epsg:21037")
  dat <- spTransform(dat, CRS(projection(colim.recl)))
  nms <- rownames(dat@bbox)
  dat@bbox <- as.matrix(extent(colim.recl))
  rownames(dat@bbox) <- nms
  return(dat)
})

### get elevation from dem
# dem <- raster("../kiliDEM/in/dem_hemp_utm37s1.tif/dem_hemp_utm37s1.tif")
# ele <- lapply(seq(stns), function(i) {
#   data.frame(plotid = stns[[i]]$PLOTID,
#              elevation = extract(dem, stns[[i]]))
# })

labels <- c("TRH", "PRCP", "SWD", "AWS", "AWS (KINAPA)")


clrs <- list("red2", 
             "cornflowerblue",
             "#FFFFBF",
             c("white", "grey40"))

pts <- lapply(seq(stns), function(i) {
  print(levels(stns[[i]]$PROVIDER))
  tmp <- spplot(stns[[i]]["PROVIDER"], col.regions = clrs[[i]],
                sp.layout = list(sp.raster), xlim = stns[[i]]@bbox[1, ],
                ylim = stns[[i]]@bbox[2, ], as.table = TRUE, cex = 0.1)
  
  Rtographize(tmp, point.type = "rectangles", alpha = 0.8,
              point.size = 1)
})

outLayer <- function(x, y) {
  x + as.layer(y)
}

outLayout <- function(x, y) {
  update(c(x, y, layout = c(2, 2)))
}

out <- Reduce(outLayout, pts)

out

png("sp1_trh_precip_aws_20140407.png", width = 30, height = 25, 
    units = "cm", res = 300)
grid.newpage()
print(out)

#downViewport(trellis.vpname(name = "figure"))

seekViewport("plot_01.panel.1.2.vp")
vp1 <- viewport(x = unit(0.01, "npc"), y = unit(0.01, "npc"),
                width = 0.5, height = 0.1, just = c("left", "bottom"),
                name = "inset_scalebar", gp = gpar(cex = 0.5))

pushViewport(vp1)
#grid.rect(gp = gpar(fill = "transparent", col = "transparent"))
gridScaleBar(out, addParams = list(noBins = 4,
                                    vpwidth = as.numeric(vp1$width)),
             unit = "kilometers", scale.fact = 2.2)
upViewport(1)

seekViewport("plot_01.panel.1.1.vp")
vp2 <- viewport(x = unit(0.01, "npc"), y = unit(0.97, "npc"),
                width = 0.1, height = 0.25, just = c("left", "top"),
                name = "inset_northarrow", gp = gpar(cex = 0.8))

pushViewport(vp2)
gridNorthArrow()
upViewport(1)

seekViewport("plot_01.panel.2.1.vp")
vp3 <- viewport(x = unit(0.98, "npc"), y = unit(0.98, "npc"),
                width = 0.21, height = 0.05 * length(clrs), 
                just = c("right", "top"),
                name = "inset_legend")

pushViewport(vp3)
gridMapLegend(labs = labels, clrs = unlist(clrs), 
              type = "rectangles")
upViewport(0)
dev.off()


#### temperature table
ta.monthly <- read.csv("sp01_plot_monthly_mean_temperature.csv",
                       stringsAsFactors = FALSE)

yrly <- colMeans(ta.monthly[, 2:66])

ta.mnthly <- data.frame(round(t(ta.monthly[, 2:66]), 1),
                        round(yrly, 1))

names(ta.mnthly) <- c(months(seq.Date(as.Date("2013-01-01"), 
                                      as.Date("2013-12-31"), 
                                      by = "months"),
                             abbreviate = TRUE),
                      "Annual")
#rownames(ta.mnthly) <- NULL

stargazer(ta.mnthly, out = "monthly_teperatures.txt",
          out.header = TRUE, summary = FALSE, digits = 1)
