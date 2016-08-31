####################################################
# Create Dataframe for Random Forest (MODIS)
####################################################
rm(list=ls())

clustered <- "/home/annika/Schreibtisch/Clip/clusterResult"

clustered.tif <- list.files(clustered,pattern=".tif$") 

####################################################
# script calculates predictor variables from aerial images 
################################################################################

#library(Rsenal)
library(rgdal)
library(cluster)
library(fuerHanna) # for fortran implementation of vvi, hsi, simpletexture
require(vegan)
################################################################################
### Do adjustments here
################################################################################

pathToSampleImages <- "/home/annika/Schreibtisch/Clip"
tmpdir <- "/home/annika/Schreibtisch/tmpdir"
outdir <- "/home/annika/Schreibtisch/clusterResults/"

fname <- list.files(pathToSampleImages,pattern=".tif$") # file to be clustered
sizeOfImage <- 500 # in m
################################################################################
### Load and crop
################################################################################

pdir <- paste0(tmpdir,"/001")
dir.create(tmpdir)

setwd(pathToSampleImages)
Dataframe<-data.frame()
Biome<-readOGR(dsn="biomeId.shp",layer="biomeId")


for (j in 1:10) {

  remove(Extract.df)
  remove(Result_Variables)
  remove(Result_Biome)

  Extract.df<-data.frame()


  print (paste0(j," processed..."))
  
  setwd(pathToSampleImages)
  rasterOptions(tmpdir=tmpdir)
  rgb_img <- brick(fname[j])
  rgb_img <- brick(raster(rgb_img,1),raster(rgb_img,2),raster(rgb_img,3))
  
  center <- c((extent(rgb_img)@xmin+extent(rgb_img)@xmax)/2,
              (extent(rgb_img)@ymin+extent(rgb_img)@ymax)/2)
  rgb_img <- crop(rgb_img,c(center[1]-sizeOfImage/2,center[1]+sizeOfImage/2,
                            center[2]-sizeOfImage/2,center[2]+sizeOfImage/2))
  names(rgb_img) <- c("R","G","B")
  
  newproj="+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
  rgb_img2 <- projectRaster(rgb_img, crs=newproj,method="ngb")
  
  Biome_Raster <- crop(Biome, rgb_img2)
  
  ################################################################################
  ### Calculate further variables
  ################################################################################
  rgb_hsi <- hsi(red = raster(rgb_img, layer = 1),
                 green = raster(rgb_img, layer = 2),
                 blue = raster(rgb_img, layer = 3))
  vvindex <- vvi(red = raster(rgb_img, layer = 1),
                 green = raster(rgb_img, layer = 2),
                 blue = raster(rgb_img, layer = 3))
  names(vvindex) <- "VVI"
  
  variables <- brick(c(rgb_img,rgb_hsi,vvindex))
  
  variables <- crop(variables,rgb_img)
  
  Result_Variables <-data.frame( rasterToPoints( variables ) )
  Result_Biome<-as.data.frame(Biome_Raster)
  
  setwd(clustered)
  Class<-raster(clustered.tif[j]) 
  
  
  Class_crop <- crop(Class,variables)
  variables <- crop(variables,Class_crop)
  
  df <-data.frame( rasterToPoints( Class_crop ) )
  
  Result_Variables <-data.frame( rasterToPoints( variables ) )
  Result_Biome<-as.data.frame(Biome_Raster)

  
  # 1 = Dry Grasland, 2 = Less Vegetation, 3= No Vegetation, 4 = Bush, 
  # 5 = Wet Grasland, NA = No good class
  

  if (j==1){
    df[df=="1"]<-4
    df[df=="2"]<-2
    df[df=="3"]<-1
    df[df=="4"]<-3
    df[df=="5"]<-4
    df[df=="6"]<-1
    df[df=="7"]<-1
  }
  
  if (j==2){
    df[df=="1"]<-1
    df[df=="2"]<-1
    df[df=="3"]<-3
    df[df=="4"]<-1
    df[df=="5"]<-4
    df[df=="6"]<-4
    df[df=="7"]<-1
  }
  
  if (j==3){
    df[df=="1"]<-2
    df[df=="2"]<-2
    df[df=="3"]<-3
    df[df=="4"]<-2
    df[df=="5"]<-2
    df[df=="6"]<-2
    df[df=="7"]<-4
  }
  
  if (j==4){
    df[df=="1"]<-2
    df[df=="2"]<-1
    df[df=="3"]<-1
    df[df=="4"]<-4
    df[df=="5"]<-4
    df[df=="6"]<-3
    df[df=="7"]<-1
  }
  
  if (j==5){
  df[df=="1"]<-1
  df[df=="2"]<-NA
  df[df=="3"]<-1
  df[df=="4"]<-3
  df[df=="5"]<-4
  df[df=="6"]<-4
  df[df=="7"]<-1
  }
  
  if (j==6){
    df[df=="1"]<-5
    df[df=="2"]<-3
    df[df=="3"]<-5
    df[df=="4"]<-4
    df[df=="5"]<-5
    df[df=="6"]<-2
    df[df=="7"]<-4
  }
  
  if (j==7){
    df[df=="1"]<-4
    df[df=="2"]<-4
    df[df=="3"]<-5
    df[df=="4"]<-5
    df[df=="5"]<-2
    df[df=="6"]<-3
    df[df=="7"]<-2
  }
  
  if (j==8){
    df[df=="1"]<-NA
    df[df=="2"]<-5
    df[df=="3"]<-5
    df[df=="4"]<-4
    df[df=="5"]<-4
    df[df=="6"]<-2
    df[df=="7"]<-3
  }
  
  if (j==9){
    df[df=="1"]<-3
    df[df=="2"]<-5
    df[df=="3"]<-4
    df[df=="4"]<-4
    df[df=="5"]<-5
    df[df=="6"]<-2
    df[df=="7"]<-2
  }
  
  if (j==10){
    df[df=="1"]<-NA
    df[df=="2"]<-2
    df[df=="3"]<-4
    df[df=="4"]<-3
    df[df=="5"]<-2
    df[df=="6"]<-4
    df[df=="7"]<-4
  }
  
  if (j==11){
    df[df=="1"]<-2
    df[df=="2"]<-NA
    df[df=="3"]<-2
    df[df=="4"]<-NA
    df[df=="5"]<-2
    df[df=="6"]<-NA
    df[df=="7"]<-3
  }
  
  df[df=="1"]<-c("Dry")
  df[df=="2"]<-c("Less")
  df[df=="3"]<-c("No")
  df[df=="4"]<-c("Bush")
  df[df=="5"]<-c("Wet")
  
 Extract.df<-cbind(Result_Variables[,3:9],Result_Biome[,1],df[,3])
 names(Extract.df) <- c("R", "G", "B", "H", "S", "I", "VVI", "Biome","class")
 
 Dataframe <- rbind(Extract.df, Dataframe)
 
} 
  

