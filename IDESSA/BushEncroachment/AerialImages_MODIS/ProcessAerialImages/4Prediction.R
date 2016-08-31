####################################################
#Prediction
####################################################
library(raster)
library(rgdal)
library(caret)
library(randomForest)
library(cluster)
library(fuerHanna) # for fortran implementation of vvi, hsi, simpletexture
require(vegan)


raster <- "F:/Training_Data/clusterResult/Clip"
predicted <- "F:/Predicted"
Biome <- "F:/GIS"


fname <- list.files(raster,pattern=".tif$") # file to be clustered

for(i in 1:length(fname)) {
  
  print(paste0(fname[i]," in progress..."))
  
  setwd(raster)
  rgb_img <- brick(fname[i])
  
  sizeOfImage <- 10 # in m
  
  center <- c((extent(rgb_img)@xmin+extent(rgb_img)@xmax)/2,
              (extent(rgb_img)@ymin+extent(rgb_img)@ymax)/2)
  rgb_img <- crop(rgb_img,c(center[1]-sizeOfImage/2,center[1]+sizeOfImage/2,
                            center[2]-sizeOfImage/2,center[2]+sizeOfImage/2))

    names(rgb_img) <- c("R","G","B")
  
  newproj="+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
  rgb_img <- projectRaster(rgb_img, crs=newproj,method="ngb")
  
  ################################################################################
  ### Calculate further variables
  ################################################################################
  rgb_hsi <- hsi(red = raster(rgb_img, layer = 1),
                  green = raster(rgb_img, layer = 2),
                 blue = raster(rgb_img, layer = 3))
  names(rgb_hsi) <- c("H","S","I")
  vvindex <- vvi(red = raster(rgb_img, layer = 1),
                green = raster(rgb_img, layer = 2),
               blue = raster(rgb_img, layer = 3))
  
          names(vvindex) <- "VVI"
          result <- brick(c(rgb_img,rgb_hsi,vvindex))
  
  setwd(Biome)
  Biome<-readOGR(dsn="biomeId.shp",layer="biomeId")

  
  Biome_Shape <- crop(Biome, rgb_img)
  Biome_Raster <-rasterize(Biome_Shape, rgb_img)
  
  result <- stack(result, Biome_Raster)
  names(result) <- c("R", "G", "B", "H", "S", "I", "VVI", "Biome")
          
  print(paste0(fname[i]," predicted..."))        
  Predicted_Raster<-predict(result, rfeModel)
  
  setwd(predicted)
  print(paste0(fname[i]," write..."))
  writeRaster(Predicted_Raster,paste0(predicted,"/predicted_",fname[i],".tif"))
  }
