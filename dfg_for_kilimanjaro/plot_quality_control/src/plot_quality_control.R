# OS detection
dsn <- switch(Sys.info()[["sysname"]], 
              "Linux" = "/media/permanent/",
              "Windows" = "D:/")

# Libraries
library(rgdal)
library(raster)

# Functions
# The functions are by DavID L Carlson, Texas A&M University,
# https://stat.ethz.ch/pipermail/r-help/2012-August/320764.html
is.letter <- function(x) grepl("[[:alpha:]]", x)
is.number <- function(x) grepl("[[:digit:]]", x)

# Working directory
setwd(paste0(dsn, "active/kilimanjaro_plot_quality_control/data"))

# Plot coordinates from Complete_Plots_mIDPoint_coordinates_update24032014.xlcs
# Subset for Arc 1960 / UTM zone 37S
plt.csv <- read.csv("Complete_Plots_mIDPoint_coordinates_update24032014.csv")
arc1960 <- data.frame(plt.csv$PlotID, plt.csv$Easting, plt.csv$Northing)
colnames(arc1960) <- c("PlotID", "Easting", "Northing")
coordinates(arc1960) <- ~ Easting + Northing
projection(arc1960) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
projection(arc1960)
arc1960.df <- data.frame(PlotID = arc1960$PlotID,
                         arc1960.X = coordinates(arc1960)[, 1],
                         arc1960.Y = coordinates(arc1960)[, 2])

# Subset for GCS_WGS_1984 projected to Arc 1960 / UTM zone 37S
wgs1984 <- data.frame(plt.csv$PlotID, plt.csv$Lon, plt.csv$Lat)
colnames(wgs1984) <- c("PlotID", "Lon", "Lat")
coordinates(wgs1984) <- ~ Lon + Lat
projection(wgs1984) <- CRS("+init=epsg:4326") # GCS_WGS_1984
wgs1984 <- spTransform(wgs1984, CRS("+init=epsg:21037"))
projection(wgs1984)
wgs1984.df <- data.frame(PlotID = wgs1984$PlotID,
                         wgs1984.X = coordinates(wgs1984)[, 1],
                         wgs1984.Y = coordinates(wgs1984)[, 2])

# Plot coordinates from CP2_KiLi Research Plots_Arc1960_UTM, ID 10526 
ogrListLayers(
  "Plot_MIDpoints_2014-03-04_ARC1960_10526/Plots_MIDdlePoint_Arc1960.shp")
ID10526.KRP <- readOGR(
  "Plot_MIDpoints_2014-03-04_ARC1960_10526/Plots_MIDdlePoint_Arc1960.shp", 
  layer = "Plots_MIDdlePoint_Arc1960")
projection(ID10526.KRP)
ID10526.KRP.df <- data.frame(PlotID = ID10526.KRP$PLOTID,
                             ID10526.KRP.X = coordinates(ID10526.KRP)[, 1],
                             ID10526.KRP.Y = coordinates(ID10526.KRP)[, 2])

# Plot middle point coordinates from CP2_Plot detail shapefiles, ID 11140 
ogrListLayers("Plot_Details_2014-03-24_WGS1984_11140/AMIDdlePole.shp")
ID11140.AMP <- readOGR(
  "Plot_Details_2014-03-24_WGS1984_11140/AMIDdlePole.shp",
  layer = "AMIDdlePole")
projection(ID11140.AMP)
ID11140.AMP <- spTransform(ID11140.AMP, CRS("+init=epsg:21037"))
ID11140.AMP.df <- data.frame(PlotID = ID11140.AMP$PlotID,
                             ID11140.AMP.X = coordinates(ID11140.AMP)[, 1],
                             ID11140.AMP.Y = coordinates(ID11140.AMP)[, 2])

# A-Pole coordinates from CP2_Plot detail shapefiles, ID 11140  
ogrListLayers("Plot_Details_2014-03-24_WGS1984_11140/APoles.shp")
ID11140.APC <- readOGR(
  "Plot_Details_2014-03-24_WGS1984_11140/APoles.shp",
  layer = "APoles")
projection(ID11140.APC)
ID11140.APC <- spTransform(ID11140.APC, CRS("+init=epsg:21037"))
ID11140.APS.df <- data.frame(PlotID = ID11140.APC$PlotID,
                                 PoleName = ID11140.APC$PoleName,
                                 Easting = coordinates(ID11140.APC)[, 1],
                                 Northing = coordinates(ID11140.APC)[, 2])
ID11140.APC.split <- split(ID11140.APC, ID11140.APC$PlotID)
ID11140.APC.df <- do.call("rbind", lapply(seq(ID11140.APC.split),function(x){
  data.frame(PlotID = unique(ID11140.APC.split[[x]]$PlotID),
             ID11140.APC.X = mean(ID11140.APC.split[[x]]@bbox[1,]),
             ID11140.APC.Y = mean(ID11140.APC.split[[x]]@bbox[2,]))
}))

# B-Pole coordinates from CP2_Plot detail shapefiles, ID 11140  
ogrListLayers("Plot_Details_2014-03-24_WGS1984_11140/BPoles.shp")
ID11140.BPC <- readOGR(
  "Plot_Details_2014-03-24_WGS1984_11140/BPoles.shp",
  layer = "BPoles")
projection(ID11140.BPC)
ID11140.BPC <- spTransform(ID11140.BPC, CRS("+init=epsg:21037"))
# Correct wrongly named poles (based on visual inspection qualtiy control)
ID11140.BPC@data$PlotID[418] <- "hel3"
ID11140.BPC@data$PlotID[389] <- "gra1"
ID11140.BPC@data$PlotID[16] <- "cof2"
ID11140.BPC@data$PlotID <- factor(ID11140.BPC@data$PlotID)
ID11140.BPS.df <- data.frame(ID11140.PlotID = ID11140.BPC$PlotID,
                             ID11140.PoleName = ID11140.BPC$PoleName,
                             ID11140.Easting = coordinates(ID11140.BPC)[, 1],
                             ID11140.Northing = coordinates(ID11140.BPC)[, 2])
ID11140.BPC.split <- split(ID11140.BPC, ID11140.BPC$PlotID)
ID11140.BPC.df <- do.call("rbind", lapply(seq(ID11140.BPC.split),function(x){
  data.frame(PlotID = unique(ID11140.BPC.split[[x]]$PlotID),
             ID11140.BPC.X = mean(ID11140.BPC.split[[x]]@bbox[1,]),
             ID11140.BPC.Y = mean(ID11140.BPC.split[[x]]@bbox[2,]))
}))

# GPX data from Andi
files <- list.files("Wegpunkte_28-DEZ-10/", pattern = ".gpx", full.names = TRUE,
                    recursive = TRUE)
gpx <- lapply(files, function(x){
  act.data <- readOGR(x, layer = "waypoints")
  converted = FALSE
  prj.org <- projection(act.data)
  coordinates(act.data)
  if(grepl("WGS84", projection(act.data))){
    act.data <- spTransform(act.data, CRS("+init=epsg:21037"))
    converted = TRUE
  } 
  prj.act <- projection(act.data)
  data.frame(GPS.Name = act.data$name,
             GPS.Time = act.data$time,
             GPS.PosX = coordinates(act.data)[, 1],
             GPS.PosY = coordinates(act.data)[, 2],
             GPS.Elev = act.data$ele,
             GPS.File = basename(x),
             GPS.Conv = converted,
             GPS.POrg = prj.org,
             GPS.PAct = prj.act)
})
GPS.df <- do.call("rbind", gpx)

GPS.df$GPS.PlotID <- tolower(substr(GPS.df$GPS.Name, 1, 4))
GPS.df$GPS.Mark <- toupper(gsub("-", "", 
                    substr(GPS.df$GPS.Name, 5, 
                           nchar(as.character(GPS.df$GPS.Name)))))

# A middle poles based on GPS data
GPS.df.AMP <- subset(GPS.df, GPS.df$GPS.Mark == "A")
GPS.df.AMP$GPS.PlotID[!is.number(substr(GPS.df.AMP$GPS.PlotID, 4, 4))]

GPS.df.AMP$GPS.PoleID <- paste(GPS.df.AMP$GPS.PlotID, 
                               GPS.df.AMP$GPS.Mark, sep = "-")

# B poles based on GPS data
GPS.df.Poles <- subset(GPS.df, 
                       nchar(GPS.df$GPS.Mark) == 2 & 
                         is.letter(substr(GPS.df$GPS.Mark, 1, 1)) & 
                         is.number(substr(GPS.df$GPS.Mark, 2, 2)))
GPS.df.Poles$GPS.PlotID[!is.number(substr(GPS.df.Poles$GPS.PlotID, 4, 4))]
GPS.df.Poles$GPS.PoleID <- paste(GPS.df.Poles$GPS.PlotID, 
                               GPS.df.Poles$GPS.Mark, sep = "-")

# Comparison of GPS vs. A mIDdle poles
gps.vs.ID11140.AMP <- Reduce(function(...){merge(..., by.x = "GPS.PlotID",
                                                 by.y = "PlotID")}, 
                             list(GPS.df.AMP, ID11140.AMP.df))
gps.vs.ID11140.AMP <- gps.vs.ID11140.AMP[, c(1, 4, 5, 13, 14)]
gps.vs.ID11140.AMP$DeltaX <- abs(gps.vs.ID11140.AMP$GPS.PosX - gps.vs.ID11140.AMP$ID11140.AMP.X)
gps.vs.ID11140.AMP$DeltaY <- abs(gps.vs.ID11140.AMP$GPS.PosY - gps.vs.ID11140.AMP$ID11140.AMP.Y)
thv <- 5
critical <- (gps.vs.ID11140.AMP$DeltaX > thv | gps.vs.ID11140.AMP$DeltaY > thv)
gps.vs.ID11140.AMP[critical,]

# Comparison of GPS vs. computed centre based on A poles
gps.vs.ID11140.APC <- Reduce(function(...){merge(..., by.x = "GPS.PlotID",
                                                 by.y = "PlotID")}, 
                             list(GPS.df.AMP, ID11140.APC.df))
gps.vs.ID11140.APC <- gps.vs.ID11140.APC[, c(1, 4, 5, 13, 14)]
gps.vs.ID11140.APC$DeltaX <- abs(gps.vs.ID11140.APC$GPS.PosX - gps.vs.ID11140.APC$ID11140.APC.X)
gps.vs.ID11140.APC$DeltaY <- abs(gps.vs.ID11140.APC$GPS.PosY - gps.vs.ID11140.APC$ID11140.APC.Y)
critical <- (gps.vs.ID11140.APC$DeltaX > thv | gps.vs.ID11140.APC$DeltaY > thv)
gps.vs.ID11140.APC[critical,]

# Comparison of GPS vs. computed centre based on B poles
gps.vs.ID11140.BPC <- Reduce(function(...){merge(..., by.x = "GPS.PlotID",
                                                 by.y = "PlotID")}, 
                             list(GPS.df.AMP, ID11140.BPC.df))
gps.vs.ID11140.BPC <- gps.vs.ID11140.BPC[, c(1, 4, 5, 13, 14)]
gps.vs.ID11140.BPC$DeltaX <- abs(gps.vs.ID11140.BPC$GPS.PosX - gps.vs.ID11140.BPC$ID11140.BPC.X)
gps.vs.ID11140.BPC$DeltaY <- abs(gps.vs.ID11140.BPC$GPS.PosY - gps.vs.ID11140.BPC$ID11140.BPC.Y)
critical <- (gps.vs.ID11140.BPC$DeltaX > thv | gps.vs.ID11140.BPC$DeltaY > thv)
gps.vs.ID11140.BPC[critical,]



# Save as gis data set
gps.vs.ID11140.AMP.gxp <- gps.vs.ID11140.AMP
coordinates(gps.vs.ID11140.AMP.gxp) <- c("GPS.PosX", "GPS.PosY")
projection(gps.vs.ID11140.AMP.gxp) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(gps.vs.ID11140.AMP.gxp, "comparison/GPS_AMP", layer = "GPS_AMP",
         driver="ESRI Shapefile")

gps.vs.ID11140.APC.gxp <- gps.vs.ID11140.APC
coordinates(gps.vs.ID11140.APC.gxp) <- c("GPS.PosX", "GPS.PosY")
projection(gps.vs.ID11140.APC.gxp) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(gps.vs.ID11140.APC.gxp, "comparison/GPS_APC", layer = "GPS_APC",
         driver="ESRI Shapefile")

GPS.df.Poles.gxp <- GPS.df.Poles
coordinates(GPS.df.Poles.gxp) <- c("GPS.PosX", "GPS.PosY")
projection(GPS.df.Poles.gxp) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(GPS.df.Poles.gxp, "comparison/GPS_POLES", layer = "GPS_POLES",
         driver="ESRI Shapefile")


# ID11140.andi <- Reduce(function(...){merge(..., by.x = "ID11140.PlotID",
#                                            by.y = "PlotID")}, 
#                        list(ID11140.BPS.df, ID11140.AMP.df))
# ID11140.andi$ID11140.PoleID <- paste(tolower(ID11140.andi$ID11140.PlotID), 
#                              toupper(ID11140.andi$ID11140.PoleName), sep = "-")
# andi <- merge(GPS.df.Poles, ID11140.andi, by.x = "GPS.PoleID",
#               by.y = "ID11140.PoleID")
# andi$DeltaX <- abs(andi$GPS.PosX - andi$ID11140.Easting)
# andi$DeltaY <- abs(andi$GPS.PosY - andi$ID11140.Northing)
# summary(andi$DeltaX)
# # summary(andi$DeltaY)
# # thv <- 35
# andi.chritical <- data.frame(PoleIDe <- 
#                                subset(andi, andi$DeltaX > thv |andi$DeltaY > thv)$GPS.PoleID
# andi.chritical$DeltaX <- as.data.frame(subset(andi, andi$DeltaX > thv |andi$DeltaY > thv)$DeltaX
# unique(subset(andi, andi$DeltaX > thv |andi$DeltaY > thv)$GPS.PlotID)
# write.table(andi, "APoles.csv", sep = ",", row.names = FALSE)

# Combine everything for comparison of x/y values
plt <- Reduce(function(...){merge(..., by = "PlotID")}, 
              list(arc1960.df, wgs1984.df, 
                   ID10526.KRP.df, ID11140.AMP.df, 
                   ID11140.APC.df, ID11140.BPC.df))

# VS XLCS
# XLCS lat/lon vs. UTM 37 S
wgs1984.vs.arc1960 <- abs(as.data.frame(coordinates(wgs1984) - 
                                          coordinates(arc1960)))
subset(wgs1984$PlotID, wgs1984.vs.arc1960$Lon > 1 | 
         wgs1984.vs.arc1960$Lat > 1)

# KRP 10526 vs. XLCS UTM 37 S
subset(plt$PlotID, abs(plt$ID10526.KRP.X - plt$arc1960.X) > thv | 
         abs(plt$ID10526.KRP.Y - plt$arc1960.Y) > thv)

# AMP 11140 vs. XLCS UTM 37 S
subset(plt$PlotID, abs(plt$ID11140.AMP.X - plt$arc1960.X) > thv | 
         abs(plt$ID11140.AMP.Y - plt$arc1960.Y) > thv)

# BPoles 11140 vs. XLCS UTM 37s
subset(plt$PlotID, abs(plt$ID11140.BPC.X - plt$arc1960.X) > thv | 
         abs(plt$ID11140.BPC.Y - plt$arc1960.Y) > thv)

# APoles 11140 vs. XLCS UTM 37s
subset(plt$PlotID, abs(plt$ID11140.APC.X - plt$arc1960.X) > thv | 
         abs(plt$ID11140.APC.Y - plt$arc1960.Y) > thv)

# VS 10526
# AMP 11140 vs. KRP 10526
subset(plt$PlotID, abs(plt$ID11140.AMP.X - plt$ID10526.KRP.X) > thv | 
         abs(plt$ID11140.AMP.Y - plt$ID10526.KRP.Y) > thv)

# BPoles 11140 vs. KRP 10526
subset(plt$PlotID, abs(plt$ID11140.BPC.X - plt$ID10526.KRP.X) > thv | 
         abs(plt$ID11140.BPC.Y - plt$ID10526.KRP.Y) > thv)

# APoles 11140 vs. KRP 10526
subset(plt$PlotID, abs(plt$ID11140.APC.X - plt$ID10526.KRP.X) > thv | 
         abs(plt$ID11140.APC.Y - plt$ID10526.KRP.Y) > thv)

# VS 11140
# BPoles 11140 vs. AMP 11140
subset(plt$PlotID, abs(plt$ID11140.BPC.X - plt$ID11140.AMP.X) > thv | 
         abs(plt$ID11140.BPC.Y - plt$ID11140.AMP.Y) > thv)

# APoles 11140 vs. AMP 11140
subset(plt$PlotID, abs(plt$ID11140.APC.X - plt$ID11140.AMP.X) > thv | 
         abs(plt$ID11140.APC.Y - plt$ID11140.AMP.Y) > thv)

# Write data as GIS data sets
coordinates(arc1960.df) <- ~ arc1960.X + arc1960.Y
projection(arc1960.df) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(arc1960.df, "comparison/arc1960", layer = "arc1960", driver="ESRI Shapefile")

coordinates(wgs1984.df) <- ~ wgs1984.X + wgs1984.Y
projection(wgs1984.df) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(wgs1984.df, "comparison/wgs1984", layer = "wgs1984", driver="ESRI Shapefile")

coordinates(ID10526.KRP.df) <- ~ ID10526.KRP.X + ID10526.KRP.Y
projection(ID10526.KRP.df) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(ID10526.KRP.df, "comparison/ID10526.KRP", layer = "ID10526.KRP",
         driver="ESRI Shapefile")

coordinates(ID11140.AMP.df) <- ~ ID11140.AMP.X + ID11140.AMP.Y
projection(ID11140.AMP.df) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(ID11140.AMP.df, "comparison/ID11140.AMP", layer = "ID11140.AMP",
         driver="ESRI Shapefile")

coordinates(ID11140.APC.df) <- ~ ID11140.APC.X + ID11140.APC.Y
projection(ID11140.APC.df) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(ID11140.APC.df, "comparison/ID11140.APC", layer = "ID11140.APC",
         driver="ESRI Shapefile")

coordinates(ID11140.BPC.df) <- ~ ID11140.BPC.X + ID11140.BPC.Y
projection(ID11140.BPC.df) <- CRS("+init=epsg:21037") # Arc 1960 / UTM zone 37S
writeOGR(ID11140.BPC.df, "comparison/ID11140.BPC", layer = "ID11140.BPC",
         driver="ESRI Shapefile")


ogrListLayers("Plot_Details_2014-03-24_11140_ARC1960/BPoles_ARC1960.shp")
test <- readOGR(
  "Plot_Details_2014-03-24_11140_ARC1960/BPoles_ARC1960.shp",
  layer = "BPoles_ARC1960")
projection(test)
projection(gps.vs.ID11140.AMP.gxp)
