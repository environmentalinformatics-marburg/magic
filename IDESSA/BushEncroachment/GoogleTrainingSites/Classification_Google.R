#####################################
#Classifcation of 500 Google Satellite Images
####################################
setwd(out)
All_classified.df <- data.frame()

load("results.RData")

for (i in 1:513){
  gmap_hel <- brick(paste(PredictionImages, "google_",i, ".tif" ,sep=""))
  
  #print rgb image
  nam<- paste("images/RGB_", i,  ".jpeg", sep = "")
  jpeg(file=nam)
  plotRGB(gmap_hel)
  dev.off()
  
  ## shadow detection
  raster_shw <- rgbShadowMask(gmap_hel)
  ## modal filter
  raster_shw  <- focal(raster_shw , w = matrix(1,3,3),
                       fun = modal, na.rm = TRUE, pad = TRUE)
  #calculate variables
  google <- VarFromRGB(gmap_hel)
  
  # Assign predicted values to target image
  google.pred <- predict(google, results)
  
  #Apply Shadow Mask
  google.pred<- google.pred*raster_shw
  
  #print prediction
  nam2<- paste("images/classified_", i,  ".jpeg", sep = "")
  jpeg(file=nam2)
  plot(google.pred)
  dev.off()
  
  #write classified image as tiff
  writeRaster(google.pred, filename=paste("images/prediction_",i,".tif", sep=""))
  
  #calculate percentage
  df=data.frame(getValues(google.pred))
  woody=sum(df==1)
  nonwoody=sum(df==0)
  all=sum(woody+nonwoody)
  
  #add values to dataframe
  All_classified.df <- rbind(All_classified.df,c(woody,nonwoody,all,woody*100/all))
}
#write percentage to file
names(All_classified.df) <- c("woody", "nonwoody", "all", "percentage")
save(All_classified.df, file = "All_classified.df.RData")
