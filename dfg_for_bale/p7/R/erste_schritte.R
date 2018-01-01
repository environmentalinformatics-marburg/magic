rm(list=ls()) 

# setwd("E:/daten")
setwd("dfg_for_bale/p7")

############################################################################
####### Merge hand written plot info with data from handheld GPS ###########

## load environmental plot data
# plot_info<- read.csv("Plot_info.csv", sep = ",", dec = ".", header = TRUE)
plot_info<- read.csv("inst/extdata/Plot_info.csv")

library(rgdal)
library(rgeos)
library(raster)
library(plotKML)
 

## load GPS tracked waypoints
#??readOGR
#shp_waypoints<- readOGR(dsn="C:/Users/Doro/Desktop/GPS/DL_FIRE_V1_10850",layer = "fire_nrt_V1_10850")
#ogrInfo(dsn="C:/Users/Doro/Desktop/GPS/DL_FIRE_V1_10850")
#waypoints<- readOGR(dsn="gps60.gpx")

#??readGPX
# waypoints1<- readGPX("gps60.gpx")
waypoints1<- readGPX("inst/extdata/gps60.gpx")

#waypoints1$waypoints$name

###what is the diffenence in loading gpx-data with "readOGR" and "readGPX"?

## Merge environmental plot and GPS-data according to "waypoint"
table <- merge(plot_info,waypoints1$waypoints,by.x = "Waypoint", by.y = "name", all.x=T)

##create data.frame for new/missing waypoints
#ab <- data.frame(table$Plot.No.[98:103], X=table$Coord_N[98:103], Y=table$Coord_E[98:103])# in UTM-projection; no numeric so it can not be transformed
#per hand umrechnung im internet "https://www.deine-berge.de/Rechner/Koordinaten/Dezimal/51,10"
xy <- data.frame(table$Plot.No.[98:103], lon = c(39.923116,39.922898, 39.922699, 39.922364, 39.923187, 39.922853), lat = c(6.932417, 6.932056, 6.932355, 6.932111, 6.932037, 6.93249))
coordinates(xy) <- c("lon", "lat")
proj4string(xy) = "+init=epsg:4326"
coordinates(xy)

table$lat[98:103]<-xy$lat
table$lon[98:103]<-xy$lon
table<-subset(table, table$lon>=0)
table$Coord_E<-NULL #delete unnecessary columns
table$Coord_N<-NULL
drops <- c(76:80, 86:94, 101:104) #delete unnecessary rows
table <- table[-drops,]
coordinates(table) <- c("lon","lat")
proj4string(table) = "+init=epsg:4326"


### #1: display waypoints -----

library(OpenStreetMap)

if (!require(Rsenal)) {
  devtools::install_github("environmentalinformatics-marburg/Rsenal")
  library(Rsenal)
}

ext = extent(table)
ext = extend(ext, 0.02)

ofl = "inst/extdata/rgb.tif"

rst = if (file.exists(ofl)) {
  brick(ofl)
} else {
  osm = openmap(upperLeft = c(ymax(ext), xmin(ext))
                , lowerRight = c(ymin(ext), xmax(ext))
                , type = "bing", minNumTiles = 12)
  
  trim(projectRaster(raster(osm), crs = proj4string(table), method = "ngb")
       , filename = ofl, datatype = "INT1U")
}

## see ?points for point symbol passed to 'pch'
p1 = spplot(rst[[1]], colorkey = FALSE, col.regions = "transparent"
            , sp.layout = list(
              rgb2spLayout(rst, alpha = .4)
              , list("sp.points", table, pch = 4, cex = 1.2, col = "black")
            ), scales = list(draw = TRUE), maxpixels = ncell(rst))

# tiff("inst/extdata/wp_topo.tiff", width = 18, height = 16, units = "cm"
#      , res = 500, compression = "lzw")
print(p1)
# dev.off()


############################################################################
####### Date of (last) fire incident from MODIS data of waypoints ##########

#run skript "DisplayDataR" until row 38 until line 61, then continue in 
#erste_schritte.R at line 121
##wanted:date of fire, last and all

#extract burning dates from spdf and add to table
#spy.last.fire<-extract(spy_agg,table)# as df
rst.last.fire<-extract(rst_agg,table)#as value
table<-cbind(table, rst.last.fire)
names(table)
names(table)[names(table)=="c.2015..2008..2015..2015..2015..2015..2015..2015..2015..2015.."] <- "last.fire"
#write.table(table, file="table.txt")
# 'Problem: die erste Spalte der Tabelle (Waypoints) wird mit den Zeilennummern beim
# Speichern ?berschrieben. Wie verhindere ich das? Beim Einlesen verschwindet das.'
#tab<-read.csv("table.csv",sep="")

all.fire<-extract(rst,table)

##Auslesen der relevanten Ergebnisse. 
fire.only<-subset(all.fire,"active_fires_2006">0)
fire.only1<-subset(all.fire, all.fire > 0)
print(all.fire==0)
'Klappt noch nicht'

#add burning dates to df "burning"
# burning<-read.csv("Burning.csv")
burning = read.csv("inst/extdata/Burning.csv")
# burning = merge(burning, table, by = "Plot.No.", all = TRUE)
burning = merge(table, burning, by = "Plot.No.", all = TRUE)

# table1<-cbind(burning, burning$Plot.No., burning$people, burning$ring_anatomy,burning$last.fire.y)
# 'auch nicht gew?nschtes Ergebnis, zu un?bersichtlich und Doppelspalten. Lieber neue Tabelle'

## identify 1-km MODIS grid cell covering each plot and extract latest burn date 
## as reported by interviewees
grd = raster("inst/extdata/MODISgrid.tif")
cls = cellFromXY(grd, burning)

mxv = sapply(unique(cls), function(i) {
  cdt = burning@data$people[cls == i]
  return(max(cdt))
})

grd[unique(cls)] = mxv

breaks = seq(1999.5, 2016.5, 1)

p2.2 <- spplot(grd
               , scales = list(draw = TRUE, y = list(rot = 90))
               , sp.layout = list(
                 rgb2spLayout(rgb, quantiles = c(0, 1), alpha = .6)
                 , list("sp.points", table, pch = 4, cex = 1.2, col = "black")
               ), at = breaks
               , main = "Year of Last Fire\nas reported by interviewees" 
               , col.regions = envinmrPalette(length(breaks))
               , alpha.regions = .6, colorkey = list(width = .8, height = .6)
               , maxpixels = ncell(grd))

## (write image to file)