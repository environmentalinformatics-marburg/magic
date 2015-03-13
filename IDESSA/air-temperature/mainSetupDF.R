#main

#Verarbeitung der MODIS-Daten und der Klimastationen
remove(list=ls(all = T))

libraries <- c("latticeExtra", "reshape2", "beepr", "maptools", "raster", "sp",
               "insol", "xts", "Rsenal", "stringr", "Rainfall")

# Install CRAN packages (if not already installed)
inst <- libraries %in% installed.packages()
if(length(libraries[!inst]) > 0) install.packages(libraries[!inst])

# Load packages into session 
lapply(libraries, require, character.only=TRUE)

#Speicherpfad der Skripte
path <- "D:/IDESSA/Skripte/magic/IDESSA/air-temperature"

# bestimmte Funktionen sourcen
source(file.path(path, "modisTime.R"))
source(file.path(path, "LST_to_LT.R"))
source(file.path(path, "sampleDaysAWS.R"))
source(file.path(path, "extractData.R"))
source(file.path(path, "cleanTData.R"))
source(file.path(path, "classPlot.R"))
source(file.path(path, "cleanModisData.R"))


#source(file.path(path, ".R"))

setwd("D:/IDESSA/data/stichprobe/")

sample = F

if(sample == T){
  ###############################################################################
  # 1. benotigte Daten fuer Stichprobentage aus den Rohdaten ziehen & in passende 
  #    Ordner ablegen (MODIS, MSG & SAWS)
  
  # Stichprobentage
  days <- c("2012-01-10",
            "2012-02-23",
            "2012-03-10",
            "2012-04-14", 
            "2012-05-06",
            "2012-06-01",
            "2012-07-13",
            "2012-08-04",
            "2012-09-01",
            "2012-10-12",
            "2012-11-23",
            "2012-12-06")
  
  ###########
  ####SAWS
  
  ##Klimastationen einlesen
  fpath <- "D:/IDESSA/data/roh/SAWS/"
  opath <- "D:/IDESSA/data/stichprobe/SAWS"
  
  sampleDaysAWS(days, fpath, opath)
  
  ############
  ####MODIS
  
  modinpath <- "D:/IDESSA/MODIS/"
  modoutpath <- "D:/IDESSA/data/stichprobe/MODIS"
  
  # Download & Verarbeitung
  setwd("D:/IDESSA/MODIS/")
  source("ModisDownload.R")
  
  #Datumsformat umwandeln
  daysdt <- c()
  for(i in days){
    daysdt <- c(daysdt, str_replace_all(i, "-", "."))
  }
  
  x <- proc.time()
  ModisDownload(x="MYD11A1",
                h=c(19,20),
                v=c(11,12),
                dates=daysdt,
                MRTpath='d:/IDESSA/MRT_RUN/bin', 
                UL=c(16.28, -22.04),LR=c(33.2, -34.96),
                bands_subset="1 1 1 1 1 1 1 0 0 0 0",
                mosaic=T,
                proj=T,
                proj_type="GEO",
                proj_params = '0 0 0 0 0 0 0 0 0 0 0 0',
                datum="WGS84",
                pixel_size=0.009)
  y = proc.time()
  print(y-x)
  beep()
  
  
  for (i in list.files(modinpath, pattern = ".tif$")){
    if(substr(i, 9, 18) %in% days){
      file.copy(file.path(modinpath, i), file.path(modoutpath, i))
    }
  }
  
  #### Daten filtern
  
  
  
  ############
  ### Meteosat
  
  # fehlt noch
}

###############################################################################
# 2. MODIS-Routine
# Koordinaten der Klimastationen einlesen

setwd("D:/IDESSA/data/stichprobe/MODIS")
#positionen der klimastationen einlesen
clim <- readShapePoints("D:/IDESSA/data/roh/shapes/AWS.shp")
#Projektion zuweisen
proj4string(clim) <- "+proj=longlat +datum=WGS84 +no_defs"
# zus?tzlich als data.frame
climdf <- as.data.frame(clim)


# View time-Daten auswerten & initialen data.frame anlegen
ipath <- "D:/IDESSA/data/stichprobe/MODIS"
gesamt <- modisTime(ipath, clim, LT = T)

# QC-Daten auswerten und an data.frame anfuegen
gesamt <- cbind(gesamt, extractData("D:/IDESSA/data/stichprobe/MODIS", 
                                    clim, 
                                    "QC", 
                                    "QC",
                                    "QC"))

# View angle auswerten und an data.frame anfuegen
gesamt <- cbind(gesamt, extractData("D:/IDESSA/data/stichprobe/MODIS", 
                                    clim, 
                                    "ViewAngle", 
                                    "VA",
                                    "view_angl.tif$"))


# Temperatur ausweren & an data.frame anfuegen
gesamt <- cbind(gesamt, extractData("D:/IDESSA/data/stichprobe/MODIS", 
                                     clim, 
                                     "TempMD", 
                                     "LST",
                                     "_1km.tif$"))


## gefilterte Daten anfuegen

i <- list.files("D:/IDESSA/data/stichprobe", pattern = "MODIS.")[1]

for(i in list.files("D:/IDESSA/data/stichprobe", pattern = "MODIS.")){
  gesamt <- cbind(gesamt, extractData(file.path("D:/IDESSA/data/stichprobe", i), 
                                       clim, 
                                       paste0("TempMD", substr(i, 6, 7)), 
                                       ".tif$"))
  
}


###############################################################################
# 3. mit den Klimadaten zusammenf?gen

#Klimastationen einlesen
aws <- read.csv("D:/IDESSA/data/stichprobe/SAWS/stichprobe_aws.csv")
aws$time <- as.POSIXct(aws$time)


# Klimastationen und MODIS zusammenfuegen
full <- merge(aws, gesamt, by = c("station", "time"))
View(full)

###############################################################################
# 4. am Ende als .csv-Datei abspeichern

#Ergebnis ausschreiben
write.csv(full, "D:/IDESSA/data/stichprobe/gesamt/gesamt.csv", row.names = F)
