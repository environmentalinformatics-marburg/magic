setwd(TrainingData)

# Load Training Data
Training<-readOGR(dsn="Trainingsgebiete.shp", layer="Trainingsgebiete")
proj4string(Training) <- CRS("+init=epsg:3857")
Training=spTransform(Training, CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" ))

valuetable.df <- data.frame()
for (i in 1:50) {
  print(paste0(i," in progress..."))
  # Load tif
  gmap_hel <- brick(paste(TrainingData, "google",i, ".tif" ,sep=""))
  
  ##calculate variables
  google_all <- VarFromRGB(gmap_hel)
  
  ## extract raster values of the training sites
  Training_dissolved<-gUnionCascaded(Training,id=Training@data$class)
  valuetable <- extract(google_all, Training_dissolved,df=TRUE)
  
  ## restructure data frame
  valuetable$ID[valuetable$ID==1]=0 
  valuetable$ID[valuetable$ID==2]=1 
  valuetable$ID <- as.factor(valuetable$ID)
#  valuetable$ID  <- revalue(valuetable$ID, c("1"="nonWoody", "2"="woody"))
  valuetable=valuetable[complete.cases(valuetable),] #make sure that there are no NA values
  valuetable.df<-rbind(valuetable.df, valuetable)
}
names(valuetable.df)[1]="class"
setwd(out)
save(valuetable.df, file = "valuetable.df.RData")