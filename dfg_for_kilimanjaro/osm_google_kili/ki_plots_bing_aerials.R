library(sp)
library(ggmap)
library(RColorBrewer)
library(raster)
library(rgdal)
library(OpenStreetMap)
library(directlabels)
library(latticeExtra)


setwd("/media/tims_ex/kilimanjaro_sp1_station_overview/bing_aerials")

bpoles <- readOGR("24.03.2014/BPoles.shp", "BPoles")
bpoles.ll <- spTransform(bpoles, CRS("+init=epsg:4326"))
bpoles.utm37s <- spTransform(bpoles, CRS("+init=epsg:32737"))
bpoles.clrk80 <- spTransform(bpoles, CRS("+init=epsg:21037"))

# +proj=utm +zone=37 +south +ellps=clrk80 +units=m +towgs84=-160,-6,-302
# 
# +proj=utm +zone=37 +south +a=6378249.145 +b=6356514.96582849 +units=m +towgs84=-175,-23,-303


###### EXAMPLE FOR INDIVIDUAL PLOT #############################################



# bpoles <- read.csv('/media/windows/tappelhans/uni/marburg/kili/plots/plot/16.05.2013/bpoles.csv')
# coordinates(bpoles) <- ~ POINT_X + POINT_Y
# proj4string(bpoles) <- CRS("+proj=utm +zone=37 +south +datum=WGS84")
# bpoles.ll <- spTransform(bpoles, CRS("+proj=longlat"))

# apoles <- read.csv2('/media/windows/tappelhans/uni/marburg/kili/plots/AMiddlePole_GPSData_UTMWGS84.csv',
#                     stringsAsFactors = FALSE)
# apoles$POINT_X <- as.numeric(apoles$POINT_X)  
# apoles$POINT_Y <- as.numeric(apoles$POINT_Y)                                                                                                  
# coordinates(apoles) <- ~ POINT_X + POINT_Y
# proj4string(apoles) <- CRS("+proj=utm +zone=37 +south +datum=WGS84")
# apoles.ll <- spTransform(apoles, CRS("+proj=longlat"))
# all.plots.sp <- apoles.ll

# apoles <- read.csv2('/media/windows/tappelhans/uni/marburg/kili/plots/AMiddlePole_GPSData_UTMWGS84.csv')
# all.plots <- read.csv('/media/windows/tappelhans/uni/marburg/kili/plots/plot/Complete_Plots_midPoint_coordinates_db2.csv')
# all.plots.sp <- all.plots
# coordinates(all.plots.sp) <- ~ LON + LAT
# proj4string(all.plots.sp) <- CRS("+proj=longlat")

### set environment variables ####


## plots to cycle through
n <- as.character(unique(bpoles$PlotID))
#n <- n[46:length(n)]
## set area to small to show extent of about +/- 80 m around plot
## set area to wide to show extent of about +/- 300 m around plot
area <- "wide"
offset <- ifelse(area == "detail", 0.0008, 0.01)
zoom <- ifelse(area == "detail", 19, 17)
all.plots.sp <- bpoles.ll
########### GET BING IMAGES ####################################################
#i <- 5
for (i in seq(n)) {
  cat("...running ", n[i])
  plot <- n[i]
  plt <- subset(all.plots.sp, PlotID == plot)
  poles.plt <- subset(bpoles.ll, PlotID == plot)
  poledf <- data.frame(x = poles.plt@coords[, 1], 
                       y = poles.plt@coords[, 2])

  xmin <- bbox(plt)[1, 1] - offset
  ymin <- bbox(plt)[2, 1] - offset
  xmax <- bbox(plt)[1, 2] + offset
  ymax <- bbox(plt)[2, 2] + offset

  ul <- c(ymax, xmin)
  lr <- c(ymin, xmax)

  omap.plt <- openmap(ul, lr, type='bing', zoom = zoom)

  omap.clrk80 <- openproj(omap.plt, "+init=epsg:21037")

  t <- autoplot(omap.clrk80)
  
  poles.plt.clrk80 <- subset(bpoles.clrk80, PlotID == plot)
  poledf.clrk80 <- data.frame(x = poles.plt.clrk80@coords[, 1], 
                              y = poles.plt.clrk80@coords[, 2])
  
  tp <- t + geom_point(data = poledf.clrk80, x = poledf.clrk80$x, y = poledf.clrk80$y, 
                      size = 2, shape = 21, fill = "white", alpha = 0.3) +
    labs(title = plot) +
    ylab("Northing") +
    xlab("Easting")

  filename <- paste(plot, area, "bing_aerial_bpoles_clrk80.png", sep = "_")
  dir.create(area, showWarnings = FALSE)
  png(paste(area, filename, sep = "/"), 
      height = 1024 * 3, width = 1024 * 3, res = 300)

  print(tp)
  
  dev.off()
  
}



########## GET GOOGLE IMAGES ###################################################
n <- c("fed1", "fed2", "fed3", "fed4", "fed5", "fer0", "fer1", "fer2", 
       "fer3", "fer4", "hel1", "hel2", "hel3", "hel4", "hel5", "sav3", "sav4")
for (i in seq(n)) {

  plot <- n[i]
  plt <- subset(all.plots.sp, PlotID == plot)
  poles.plt <- subset(bpoles.ll, PlotID == plot)
  poledf <- data.frame(x = poles.plt@coords[, 1], 
                       y = poles.plt@coords[, 2])

  cntr <- c(mean(plt@bbox[1, ]), mean(plt@bbox[2, ]))
  attributes(cntr) <- NULL
  xysize <- c(omap.plt$tiles[[1]]$xres, omap.plt$tiles[[1]]$yres + 1) 

  s <- get_googlemap(cntr, zoom = zoom, size = xysize,
                     maptype = "satellite")
  sp <- ggmap(s) + geom_point(data = poledf, x = poledf$x, y = poledf$y, 
                      size = 1, shape = 21, fill = "white", alpha = 0.3) +
    labs(title = plot) +
    ylab("Latitude") +
    xlab("Longitude")

  filename <- paste(plot, area, "google_aerial_bpoles_clrk80.png", sep = "_")
  dir.create(area, showWarnings = FALSE)
  png(paste(area, filename, sep = "/"), 
      height = 1024 * 3, width = 1024 * 3, res = 300)

  print(sp)

  dev.off()

}
