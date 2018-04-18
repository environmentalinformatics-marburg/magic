#################################################################################
#prepare Exploratories data
#################################################################################
rm(list=ls())
library(sp)
library(rgdal)
library(geosphere)
setwd("/media/hanna/data/Overfitting/Exploratories/")
clim <- read.csv("plots.csv")
terrain <- read.csv("11603.txt",sep="\t")
lui <- read.csv("LUI_glob_sep_02.12.2016+164606.txt",sep="\t")
ids <- read.csv("Kopfdaten_EP_2014.csv")
text <- read.csv("14686_MinSoil_2011_Mineral_Soil_Texture_1.9.6/14686.txt",sep="\t")
bulk <- read.csv("17086_MinSoil_2011_Mineral_Soil_Bulk_Density_CN_stocks_1.1.5/17086.csv")

#prepare spatial locations
loc <- read.csv("/media/hanna/data/Overfitting/Exploratories/be_station_master.csv")
loc <- SpatialPointsDataFrame(cbind("x"=loc$Lon,"y"=loc$Lat), data = loc)
proj4string(loc) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"

#prepare terrain table
terrain$EpPlotID <- ids$EpPlotID[match(terrain$id, ids$GpPlotID)]
terrain <- terrain[complete.cases(terrain),]
terrain <- terrain[,c("EpPlotID","type","rw","hw","elevation","slope",
                      "aspect","Exploratorium")]


#match data tables
ctmerge <- terrain[match(clim$plotID, terrain$EpPlotID),]
clim_proc <- clim[complete.cases(ctmerge),]
ctmerge <- ctmerge[complete.cases(ctmerge),]
dataset <- data.frame(clim_proc,ctmerge)
dataset$bulk <- bulk[match(dataset$plotID,bulk$EP_Plotid),c("BD")]
dataset <- data.frame(dataset,text[match(dataset$plotID,text$EP_Plotid),
                                   c("Clay","Fine_Silt","Coarse_Silt","Fine_Sand","Medium_Sand","Coarse_Sand")])

#create "time" variables
dataset$date <- as.Date(dataset$datetime)
dataset$year <- substr(dataset$date,1,4)
dataset$month <- substr(dataset$date,6,7)
dataset$doy <- as.numeric(format(dataset$date,"%j"))

#replace comma
lui[,which(names(lui)%in%c("G_std","M_std","F_std", "LUI"))] <- 
  apply(lui[,which(names(lui)%in%c("G_std","M_std","F_std", "LUI"))],2,
  function(x){as.numeric(sub(",",".",x ))})



#merge with lui

lui$Std_procedure.year. <- substr(lui$Std_procedure.year.,12,15)
dataset <- merge(dataset, lui,by.x=c("plotID","year"),
                 by.y=c("EP.Plotid","Std_procedure.year."),
                 all.x=TRUE,
                 all.y=FALSE)
#clean up
dataset_clean <- dataset[,-which(names(dataset)%in%c("datetime","timestamp","EpPlotID","SM_10_2","SM_15",
                                                     "SM_20","SM_20_2","SM_30","SM_35","SM_40",
                                                     "SM_50","type","Ts_20","Ts_5",
                                                     "Ts_50","rH_200","P_container_NRT",
                                                     "Std_procedure.exploratory."))]

dataset_clean <- dataset_clean[dataset_clean$year%in%as.character(2012:2015),]
#################################################################################
# #assign prec and temp of nearest station if missing
#################################################################################

for (i in 1:nrow(dataset_clean)){
  if (is.na(dataset_clean$P_RT_NRT[i])|is.na(dataset_clean$Ta_200[i])|
                                             is.na(dataset_clean$evaporation[i])){
    #which other stations produced data at that day?
    timematch <- dataset_clean[which(dataset_clean$date==dataset_clean$date[i]),]
    if (is.na(dataset_clean$P_RT_NRT[i])){
    statNotNa <- timematch[!is.na(timematch$P_RT_NRT),]
    }else{
      statNotNa <- timematch[!is.na(timematch$Ta_200),]
    }
    if (nrow(statNotNa)>0){
      climstat <- unique(statNotNa$plotID)
      climstat <- loc[loc@data$EP_Plotid%in%climstat,]
      clim_near <- c()
      loc_i <- loc[which(as.character(loc@data$EP_Plotid)==as.character(dataset_clean$plotID[i])),]
      clim_near <- as.character(climstat[which.min(distm (loc_i, climstat)),]@data$EP_Plotid) #nearest station without NA
      if(substr(clim_near,1,3)!=substr(dataset_clean$plotID[i],1,3)){next} #if no data from same area
      if (is.na(dataset_clean$P_container_RT[i])){
        dataset_clean$P_container_RT[i]<- statNotNa$P_container_RT[statNotNa$plotID==clim_near]
      }
      if (is.na(dataset_clean$P_RT_NRT[i])){
        dataset_clean$P_RT_NRT[i]<- statNotNa$P_RT_NRT[statNotNa$plotID==clim_near]
      }
      if (is.na(dataset_clean$Ta_200[i])){
        dataset_clean$Ta_200[i]<- statNotNa$Ta_200[statNotNa$plotID==clim_near]
      }
      if (is.na(dataset_clean$Ta_200_max[i])){
        dataset_clean$Ta_200_max[i]<- statNotNa$Ta_200_max[statNotNa$plotID==clim_near]
      }
      if (is.na(dataset_clean$Ta_200_min[i])){
        dataset_clean$Ta_200_min[i]<- statNotNa$Ta_200_min[statNotNa$plotID==clim_near]
      }
      if (is.na(dataset_clean$evaporation[i])){
        dataset_clean$evaporation[i]<- statNotNa$evaporation[statNotNa$plotID==clim_near]
      }
      if (is.na(dataset_clean$SWDR_300[i])){
        dataset_clean$SWDR_300[i]<- statNotNa$SWDR_300[statNotNa$plotID==clim_near]
      }
      if (is.na(dataset_clean$Ts_10[i])){
        dataset_clean$Ts_10[i]<- statNotNa$Ts_10[statNotNa$plotID==clim_near]
      }
    }
  }
}


#################################################################################
# calculate further variables
#################################################################################
# cummulative rainfall (set to 0 if no rain)
#dataset_clean <- get(load("dataset_clean.RData"))
dat_order <- dataset_clean[order(dataset_clean$plotID,dataset_clean$date),]

dat_order$Precip_cum <- NA
for (i in unique(dat_order$plotID)){
  dat_order$Precip_cum[dat_order$plotID==i] <- ave(dat_order$P_RT_NRT[dat_order$plotID==i], 
                              rev(cumsum(rev(dat_order$P_RT_NRT[dat_order$plotID==i])==0)), 
                              FUN=cumsum)
}



# slope of container prec ### STILL NEEDS CHECKING
dat_order$PrecDeriv <- NA
for (i in unique(dat_order$plotID)){
  subs <- dat_order$P_container_RT[dat_order$plotID==i]
  smoothy <- smooth.spline(1:length(subs),subs,spar=0.5)$y
  f_of_x <- splinefun(1:length(subs),smoothy)
  f1 <- f_of_x(1:length(subs), deriv = 1)
  f1[f1>10|f1< -10] <- NA
  dat_order$PrecDeriv[dat_order$plotID==i] <- f1
}

#clean up
dat <- dat_order[complete.cases(dat_order),]



save(dat,file="dataset_exploratories.RData")
#loc <- loc[loc@data$EP_Plotid%in%dataset_clean$plotID,]
