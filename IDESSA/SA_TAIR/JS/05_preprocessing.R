#author: Johannes S.
setwd("/media/johannes/8F8D-083B/Tair_southAfrica_data")

load("Tair_dataset.RData")

library(rgdal)
library(mapview)
library(caret)
library(lubridate)
library(reshape2)
library(zoo)
library(dplyr)


### geländehöhe (masl) und koordinaten einfügen ###
 # quelle: digital terrain elevation data (usgs), shp erstellt in QGIS



# shapefile laden
weather_stations_masl <- "weather_stations_masl_shp/height_weather_stations.shp"
lyr <- ogrListLayers(dsn = weather_stations_masl)
weather_stations_masl <- readOGR(dsn = weather_stations_masl,
                    layer = lyr)





# Tair dataset mit masl-daten mergen
stations_masl_df <- as.data.frame(weather_stations_masl)
stations_masl_df$plot <- as.character(stations_masl_df$plot)

dataset <- merge(dataset, stations_masl_df, by.x = "Station", by.y = "plot")
colnames(dataset)[17] <- "masl"


# na zeilen löschen (stationen außerhalb von südafrika)
dataset <- na.omit(dataset)



### ndvi-Daten (MODIS) in Tair dataset einfügen ###

# ndvi csv-datei laden
ndvi <- read.csv("WeatherStationsNDVI_csv.csv")


# spaltennamen von ndvi dataframe anpassen (nur noch jahr_tageszahl bleibt übrig)
colnames(ndvi)[3:235] <- sapply(colnames(ndvi)[3:235], function(x) substring(
  x, first=c(10), last=c(16))) 


# datum von Tair dataset in einzelne teile aufspalten bzw neu zusammensetzen für mergen
splitted <- t(sapply(dataset$date, function(x) substring(
  x, first=c(1,1,5,9), last=c(4,8,6,10))))

dataset[,20] <- splitted[,1]
dataset[,21] <- splitted[,2]
dataset[,22] <- splitted[,3]
dataset[,23] <- splitted[,4]

colnames(dataset)[20] <- "year"
colnames(dataset)[21] <- "ymd"
colnames(dataset)[22] <- "month"
colnames(dataset)[23] <- "time"


# spalte year_day_nr in Tair dataset einfügen mit gleicher formatierung wie in ndvi dataset 
dataset[,21] <- as.Date(dataset$ymd, "%Y%m%d")


dataset[,21] <- yday(dataset$ymd)
colnames(dataset)[21] <- "day_nr"
dataset[,21] <- formatC(dataset$day_nr, width = 3, format = "d", flag = "0")
dataset[,24] <- paste0(dataset$year, dataset$day_nr)
colnames(dataset)[24] <- "year_day_nr"


# Tair dataset und ndvi dataset mergen 
#  / ndvi dataset dafür umstrukturieren: year_day_nr als eigene spalte einfügen,
#    damit jedem ndvi Wert eindeutig Station und Datum zugeordnet ist

ndvi[,2] <- NULL


ndvi_melt <- melt(ndvi, id.vars="plot")
ndvi_melt$plot <- as.character(ndvi_melt$plot)
ndvi_melt$variable <- as.character(ndvi_melt$variable)

dataset <- merge(dataset, ndvi_melt, 
                            by.x = c("Station", "year_day_nr"), by.y = c("plot", "variable"), all.x = TRUE)

colnames(dataset)[25] <- "ndvi"


# fehlende ndvi werte auffuellen mit dem zeitlich nächsten ndvi-wert (nach stationen gruppiert)

dataset <- dataset %>%
  group_by(Station) %>% 
  mutate(ndvi = na.locf(ndvi, na.rm = FALSE, fromLast = TRUE))

# NA in ndvi entfernen (Stationen ohne Tair Werte)
dataset <- na.omit(dataset)



### landcover (MODIS) in Tair dataset einfügen, shp in QGIS erstellt 

# shape laden
weather_stations_landcover <- "weather_stations_landcover_shp/weather_stations_landcover_shp.shp"
lyr <- ogrListLayers(dsn = weather_stations_landcover)
weather_stations_landcover <- readOGR(dsn = weather_stations_landcover,
                                 layer = lyr)

landcover_df <- as.data.frame(weather_stations_landcover)
landcover_df[,c(2,4,5)] <- NULL


# Tair dataset und landcover dataset mergen
dataset <- merge(dataset, landcover_df, by.x = "Station", by.y = "plot")
colnames(dataset)[26] <- "landcover"
dataset$landcover <- as.character(dataset$landcover)

dataset$landcover <- sub("5", "Mixed Forests", dataset$landcover)
dataset$landcover <- sub("7", "Open Shrublands", dataset$landcover)
dataset$landcover <- sub("8", "Woody Savannas", dataset$landcover)
dataset$landcover <- sub("9", "Savannas", dataset$landcover)
dataset$landcover <- sub("10", "Grasslands", dataset$landcover)
dataset$landcover <- sub("11", "Permanent Wetland", dataset$landcover)
dataset$landcover <- sub("12", "Croplands", dataset$landcover)
dataset$landcover <- sub("13", "Urban and Built Up", dataset$landcover)
dataset$landcover <- sub("14", "Cropland/Natural Vegetation Mosaic", dataset$landcover)
dataset$landcover <- sub("16", "Barren or Sparsely Vegetated", dataset$landcover)


dataset <- na.omit(dataset)


### spalte tag einfuegen
splitted_day <- t(sapply(dataset$date, function(x) substring(
  x, first=c(7), last=c(8))))

dataset[,27] <- splitted_day[,1]

colnames(dataset)[27] <- "day"


### Tair dataset neu anordnen und unnoetige spalten loeschen
dataset[,c(2,6:11,14,17)] <- NULL
dataset <- subset(dataset, select=c(1,10:11,2,12,18,15,13:14,3:7,9,17,16,8))


### reduzieren auf jahre 2013/2014 und in training set splitten
set.seed(50)

dataset <- subset(dataset, year=="2014" | year=="2013")


rows_training <- createDataPartition(dataset$Station,
                                     p = .30,
                                     list= FALSE)

dataset_training <- dataset[rows_training, ]


### training set speichern
row.names(dataset_training) <- NULL
save(dataset_training, file = "Tair_trainingSet_johannes_2.RData")

