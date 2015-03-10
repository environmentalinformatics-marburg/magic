#Statistische Auswertungen
full <- read.csv("E:/IDESSA/data/stichprobe/gesamt/gesamt.csv")

#NA entfernen
full <- na.omit(full)

# Korrelation
cor(full$TempMD, full$TempAWS, use = "pairwise.complete.obs")

#Korrelation gefiltert
cor(full$TempMD7x, full$TempAWS, use = "pairwise.complete.obs")

#Korrelation gefiltert
cor(full$TempMD9x, full$TempAWS, use = "pairwise.complete.obs")

#Korrelation gefiltert
cor(full$TempMD15, full$TempAWS, use = "pairwise.complete.obs")


xyplot(TempAWS ~ TempMD7x, data = full)

min(full$TempAWS)
min(full$TempMD)
max(full$TempAWS)
max(full$TempMD)

######################
####Plots & Korrelationen


########################################
#### Plot mit Klassifikation nach Uhrzeit
# nach Uhrzeit sortieren
full$uhrzeit <- as.numeric(substr(full$time, 12, 13))
full <- full[order(full$uhrzeit),]


#Uhrzeitklassen einfuegen

str(full)

full$timeclass <- NA
for(i in seq(1:nrow(full))){
  if(full$uhrzeit[i] >= 0 & full$uhrzeit[i] <= 7)
    full$timeclass[i] <- "a"
  else if(full$uhrzeit[i] >= 8 & full$uhrzeit[i] <= 11)
    full$timeclass[i] <- "b"
  else if(full$uhrzeit[i] >= 12 & full$uhrzeit[i] <= 17)
    full$timeclass[i] <- "c"
  else if(full$uhrzeit[i] >= 18 & full$uhrzeit[i] <= 24)
    full$timeclass[i] <- "d" 
}


obj <- classPlot(full, "TempMD", "TempAWS", "timeclass", ret = T)

latticeCombineLayer(obj)

obj[[1]]
obj[[2]]
obj[[3]]
obj[[4]]

#######
## nach Aufnahmemonat

full$month <- months(full$time, abbreviate = T)

obj <- classPlot(full, "TempAWS", "TempMD", "month", ret = T)

spplot(obj)

latticeCombineLayer(obj)

obj[[1]]
obj[[2]]
obj[[3]]
obj[[4]]
obj[[5]]
obj[[6]]
          
#######
## nach Terra/Aqua

product <- classPlot(full, "TempAWS", "TempMD", "product", ret = T)

product[[1]]
product[[2]]
latticeCombineLayer(product)
