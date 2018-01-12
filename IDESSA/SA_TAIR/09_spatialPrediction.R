rm(list=ls())
library(raster)
library(rgdal)
library(caret)
mainpath <-"/media/memory02/users/hmeyer/IDESSA_TAIR/"
auxpath <- paste0(mainpath,"auxiliary/")
MSGpath <-  paste0(mainpath,"MSG/")
modelpath <- paste0(mainpath,"modeldat/")
outpath <-paste0(mainpath,"sppredictions/")
tempdir <-paste0(mainpath,"tmpdir/")

rasterOptions(tmpdir=tempdir)

MSGscenes <- list.files(MSGpath,pattern=".tif$",full.names = TRUE)
template <- raster(MSGscenes[1])
predictors <- stack(paste0(auxpath,"predictors.tif"))
predictors <- projectRaster(predictors,template)

model <- get(load(paste0(modelpath,"model_final.RData")))

for (i in 1:length(MSGscenes)){
  MSGscene <- stack(MSGscenes[i],predictors)
  names(MSGscene) <- c("VIS0.6", "VIS0.8", 
                        "NIR1.6", "IR3.9", "WV6.2", "WV7.3", "IR8.7", "IR9.7", "IR10.8", 
                        "IR12.0", "IR13.4","sunzenith",
                        "Continentality","Biome","Prec",
                        "Tmean","Dem","Biome_agg","Precseason")
  prediction <- predict(MSGscene,model)
  writeRaster(prediction,
              paste0(outpath,"prediction_",substr(MSGscenes[i],nchar(MSGscenes[i])-13,nchar(MSGscenes[i]))),
              overwrite=TRUE)
  
}


