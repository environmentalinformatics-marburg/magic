setwd(TrainingData)

# Create Biome Raster
#biomeId<-readOGR(dsn="biomeId.shp", layer="biomeId")
#biomeId <- spTransform(biomeId, CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" ))
#save(biomeId, file = "biomeId.RData")
load("biomeId.RData")

# Load Training Data
Training<-readOGR(dsn="Trainingsgebiete.shp", layer="Trainingsgebiete")
proj4string(Training) <- CRS("+init=epsg:3857")
Training=spTransform(Training, CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" ))

valuetable.df <- data.frame()

imagefiles <- list.files(TrainingData,pattern=".tif$")

for (i in 1:length(imagefiles)) {
  
  print(paste0(i," in progress..."))
  # Load tif
  gmap_hel <- brick(paste(TrainingData, "google",i, ".tif" ,sep=""))
  
  ##calculate variables
  google_all <- VarFromRGB(gmap_hel)
  
  # Add Biome
  biomeId_crop<-crop(biomeId, gmap_hel)
  baseraster <- raster(ext=extent(biomeId_crop),res=res(google_all),crs=proj4string(biomeId))
  biomeId_raster <- rasterize(biomeId_crop,baseraster,field=biomeId_crop@data$Id)
  names(biomeId_raster) <- paste0("Biome")
  google_all <- stack(google_all,biomeId_raster)
  
  ## extract raster values of the training sites
  Training_dissolved<-gUnionCascaded(Training,id=Training@data$class)
  valuetable <- extract(google_all, Training_dissolved,df=TRUE)

  ## restructure data frame
  valuetable$ID[valuetable$ID==1]="nonwoody"#0 
  valuetable$ID[valuetable$ID==2]="woody"#1 
  valuetable$ID <- as.factor(valuetable$ID)
 #valuetable$ID  <- revalue(valuetable$ID, c("1"="nonWoody", "2"="woody"))
  valuetable=valuetable[complete.cases(valuetable),] #make sure that there are no NA values
  valuetable.df<-rbind(valuetable.df, valuetable)
}
names(valuetable.df)[1]="class"
valuetable.df$class=factor(valuetable.df$class,levels=c("woody","nonwoody"))
setwd(out)
save(valuetable.df, file = "valuetable.df.RData")
