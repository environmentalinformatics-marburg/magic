#plots sample comparisons of MSG based retrieval and GPM.
#A color composite is printed as well and must currently manually be inserted into
#the overall plot
library(rgdal)
library(raster)
library(viridis)
library(Rsenal)

dates <- c("2014042410","2014040701","2014041301")
saturationpoint <- 10

mainpath <- "/media/memory01/data/IDESSA/"

auxdatpath <- paste0(mainpath,"auxiliarydata/")
stationpath <- paste0(mainpath,"statdat/")
IMERGpath <- paste0(mainpath,"Results/IMERG/")
evaluationpath <- paste0(mainpath,"Results/Evaluation/")
MSGpredpath <- paste0(mainpath,"Results/Predictions/2014/")
figurepath <- paste0(mainpath,"Results/Figures/sampleimages/")
dir.create(figurepath)

base <- readOGR(paste0(auxdatpath,"TM_WORLD_BORDERS-0.3.shp"),
                "TM_WORLD_BORDERS-0.3")
stations <- readOGR(paste0(stationpath,"allStations.shp"),
                    "allStations")

for (date in dates){
  IMERG <- raster(list.files(IMERGpath,pattern=paste0(date,".tif$"),full.names = TRUE))
  rate <- raster(list.files(paste0(MSGpredpath,"/Rate"),pattern=paste0(date,".tif$"),full.names = TRUE))
  area <- raster(list.files(paste0(MSGpredpath,"/Area"),pattern=paste0(date,".tif$"),full.names = TRUE))
  MSG <- stack(list.files(paste0(MSGpredpath,"/MSG/"),pattern=paste0(date,".tif$"),full.names = TRUE))
  
  rate[area==2] <- 0
  IMERG <- mask(IMERG,area)
  stck <- stack(rate,IMERG)
  stck <- projectRaster(stck, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  MSG <- projectRaster(MSG, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  
  stck <- mask(stck,base)
  base <- crop(base,c(11.4,36.2,-35.4,-17))
  MSG <- crop(MSG, c(11.4,36.2,-35.4,-17))
  stck <- crop(stck, c(11.4,36.2,-35.4,-17))
  stck <- stack(stck[[1]],stck)
  values(stck[[1]]) <- NA
  
  names(stck)<- c("RGB","MSG","IMERG")
  stck$IMERG[stck$IMERG>saturationpoint] <- saturationpoint
  
  #########################################
  #observed rainfall rasterize
  comp <- get(load(paste0(evaluationpath,"IMERGComparison.RData")))
  comp <- comp[comp$Date.x=="201404241000",]
  
  stations$Obs <- merge(stations,comp,by.x="Name",by.y="Station")$RR_obs
  stations <- stations[!is.na(stations$Obs),]
  
  statrstr <- rasterize(stations,stck[[1]],field="Obs")
  statrstragg <- aggregate(statrstr,18,fun=max)
  statrstragg <- resample(statrstragg,stck[[1]])
  stck$Observed <- statrstragg
  #########################################
  #plot
  ########################################
  spp <- spplot(stck,col.regions = c("grey",rev(viridis(100))),
                scales=list(draw=FALSE,x=list(rot=90)),
                at=seq(0.0,saturationpoint,by=0.2),
                ncol=2,nrow=2,
                maxpixels=ncell(stck)*0.6,
                par.settings = list(strip.background=list(col="lightgrey")),
                sp.layout=list("sp.polygons", base, col = "black", first = FALSE))
  
  png(paste0(figurepath,"rgb_",date,".png"),
      width=8,height=8,units="cm",res = 600,type="cairo")
  plotRGB(MSG,r=2,g=4,b=9,stretch="lin")
  plot(base,add=T,lwd=1.4)
  dev.off()
  
  png(paste0(figurepath,"spp_",date,".png"),
      width=17,height=16,units="cm",res = 600,type="cairo")
  spp
  dev.off()
  
  ###summary statistics
  results_area <- rbind(classificationStats(comp$RA_pred,comp$RA_obs),
                        classificationStats(comp$RA_IMERG,comp$RA_obs))
  results_rate <- rbind(regressionStats(comp$RR_pred,comp$RR_obs,adj.rsq = FALSE,method="spearman"),
                        regressionStats(comp$IMERG,comp$RR_obs,adj.rsq = FALSE,method="spearman"))
  stats <- cbind(results_area,results_rate)
  write.csv(stats,paste0(figurepath,"/stats_",date,".csv"))
  
}