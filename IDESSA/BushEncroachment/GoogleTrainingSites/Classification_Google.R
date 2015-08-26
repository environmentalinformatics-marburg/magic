#####################################
#Classifcation of 500 Google Satellite Images
####################################
setwd(TrainingData)
load("biomeId.RData")

setwd(out)
All_classified.df <- data.frame()

load("results.RData")


imagefiles <- list.files(PredictionImages,pattern=".tif$")

for (i in 1:length(imagefiles)){
  print(paste0(i," in progress..."))
  gmap_hel <- brick(paste(PredictionImages, "google_",i, ".tif" ,sep=""))
  
 # print rgb image
  nam<- paste("images/RGB_", i,  ".jpeg", sep = "")
  jpeg(file=nam)
  plotRGB(gmap_hel)
  dev.off()
  
  ##shadow detection
  # raster_shw <- rgbShadowMask(gmap_hel)
  # modal filter
  # raster_shw  <- focal(raster_shw , w = matrix(1,3,3),
  #                     fun = modal, na.rm = TRUE, pad = TRUE)

  #calculate variables
  google <- VarFromRGB(gmap_hel)
  
  # Add Biome
  biomeId_crop<-crop(biomeId, google)
  if (is.null(biomeId_crop)){next}
  baseraster <- raster(ext=extent(biomeId_crop),res=res(google) ,crs=proj4string(biomeId))
  biomeId_raster <- rasterize(biomeId_crop,baseraster,field=biomeId_crop@data$Id)
  names(biomeId_raster) <- paste0("Biome")
  
  #google <- stack(google,biomeId_raster)
  google <- stack(google, biomeId_raster)
  
  # Assign predicted values to target image
  google.pred <- predict(google, results)
  google.pred.prob <- predict(google, results, type="prob")
  google.pred[google.pred==2]=0
  
  #google.pred[google.pred==2]=1
  
  #Apply Shadow Mask
  #google.pred<- google.pred*raster_shw
  
  #print prediction
  nam2<- paste("images/classified_", i,  ".jpeg", sep = "")
  jpeg(file=nam2)
  plot(google.pred)
  dev.off()
  
  # reliability predicted values
  
  reliability =  (sum(values(google.pred.prob)<0.25)+sum(values(google.pred.prob)>0.75))/ncell(google.pred.prob)
  
  #write classified image as tiff
  writeRaster(gmap_hel, filename=paste("images/rgb_",i,".tif", sep=""), overwrite=TRUE)
  writeRaster(google.pred, filename=paste("images/prediction_",i,".tif", sep=""), overwrite=TRUE)
  writeRaster(google.pred.prob, filename=paste("images/predictionProb_",i,".tif", sep=""), overwrite=TRUE)
  
  #calculate percentage
  df=data.frame(getValues(google.pred))
  woody=sum(df==1)
  nonwoody=sum(df==0)
  All=woody+nonwoody
  
  #add values to dataframe
  All_classified.df <- rbind(All_classified.df,c(i,woody,nonwoody,All,woody*100/All,reliability))
}

#write percentage to file
names(All_classified.df) <- c("Id","woody", "nonwoody", "all", "percentage","reliability")
save(All_classified.df, file = "All_classified.df.RData")
