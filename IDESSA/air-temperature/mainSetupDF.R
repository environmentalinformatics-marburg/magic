#main

#Verarbeitung der MODIS-Daten und der Klimastationen
remove(list=ls(all = T))

libraries <- c("latticeExtra", "reshape2", "beepr", "maptools", "raster", "sp",
               "insol", "xts", "Rsenal")

# Install CRAN packages (if not already installed)
inst <- libraries %in% installed.packages()
if(length(libraries[!inst]) > 0) install.packages(libraries[!inst])

# Load packages into session 
lapply(libraries, require, character.only=TRUE)

#Speicherpfad der Skripte
path <- "D:/IDESSA/Skripte"

# bestimmte Funktionen sourcen
source(file.path(path, "modisTime.R"))
source(file.path(path, "LST_to_LT.R"))
source(file.path(path, "sampleDaysAWS.R"))
source(file.path(path, "extractTData.R"))
source(file.path(path, "cleanTData.R"))
source(file.path(path, "classPlot.R"))
#source(file.path(path, ".R"))


setwd("F:/IDESSA/data/stichprobe/")


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
fpath <- "F:/IDESSA/data/roh/SAWS/"
opath <- "F:/IDESSA/data/stichprobe/SAWS"

sampleDaysAWS(days, fpath, opath)

############
####MODIS

modinpath <- "D:/IDESSA/MODIS/"
modoutpath <- "F:/IDESSA/data/stichprobe/MODIS"

for (i in list.files(modinpath, pattern = ".tif$")){
  if(substr(i, 9, 18) %in% days){
    file.copy(file.path(modinpath, i), file.path(modoutpath, i))
  }
}


############
### Meteosat

# fehlt noch



###############################################################################
# 2. MODIS-Routine
#    - Koordinaten der Klimastationen einlesen

setwd("F:/IDESSA/data/stichprobe/MODIS")
#positionen der klimastationen einlesen
clim <- readShapePoints("F:/IDESSA/data/roh/shapes/AWS.shp")
#Projektion zuweisen
proj4string(clim) <- "+proj=longlat +datum=WGS84 +no_defs"
# zusätzlich als data.frame
climdf <- as.data.frame(clim)


#    - View time-Daten auswerten & initialen data.frame anlegen
ipath <- "F:/IDESSA/data/stichprobe/MODIS"
gesamt <- modisTime(ipath, clim, LT = T)


#    - Stacks mit den anderen Daten bilden, auswerten & an data.frame anfügen

gesamt <- cbind(gesamt, extractTData("F:/IDESSA/data/stichprobe/MODIS", 
                                     clim, 
                                     "TempMD", 
                                     "_1km.tif$"))
i <- list.files("F:/IDESSA/data/stichprobe", pattern = "MODIS.")
for(i in list.files("F:/IDESSA/data/stichprobe", pattern = "MODIS.")){
  gesamt <- cbind(gesamt, extractTData(file.path("F:/IDESSA/data/stichprobe", i), 
                                       clim, 
                                       paste0("TempMD", substr(i, 6, 7)), 
                                       ".tif$"))
  
}


###############################################################################
# 3. mit den Klimadaten zusammenfügen

#Klimastationen einlesen
aws <- read.csv("F:/IDESSA/data/stichprobe/SAWS/stichprobe_aws.csv")
aws$time <- as.POSIXct(aws$time)


# Klimastationen und MODIS zusammenfügen
#full <- merge(aws, comb, by = "time")
full <- merge(aws, gesamt, by = c("station", "time"))
View(full)

###############################################################################
# 4. am Ende als .csv-Datei abspeichern

#Ergebnis ausschreiben
write.csv(full, "F:/IDESSA/data/stichprobe/gesamt/gesamt.csv", row.names = F)
