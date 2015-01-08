#nicht sommer/winter trennen
#day,night,inb auch nicht trennen -> 0 für NA? test ob das geht...
rm(list=ls())

library(raster)
library(doParallel)
library(glcm) #for texture parameters
library(SDMTools) # for pacth shape parameters

registerDoParallel(detectCores())

msgpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"

setwd(msgpath)

### Go through all months, days, hours and scenes ##############################
months=list.files()
for (i in 1:length(months)){
  setwd(months[i])
  days=list.files()
  for (k in 1:length(days)){
    setwd(days[k])
    hours=list.files()
    for (l in 1:length(hours)){
      setwd(hours[l])
### Load MSG data ##############################################################
      scenes=Sys.glob("*.rst")
      x=c("ca02p0001","ca02p0002","ca02p0003","ct01dk004","ct01dk005","ct01dk006",
            "ct01dk007","ct01dk008","ct01dk009","ct01dk010","ct01dk011")
      scenerasters=stack(scenes[substr(scenes,20,28)%in%x]) # die substr(scenes,27,28) = 1:11, substr(scenes,20,23) =="ma11"
      scenerasters[values(scenerasters)==-99]=NA
      names(scenerasters)<-c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                       "IR9.7","IR10.8","IR12.0","IR13.4")
################################################################################
### caluclate derivated variables 
################################################################################

### Meikes predictor variables #################################################
      T6.2_10.8 <- scenerasters$WV6.2-scenerasters$IR10.8
      T7.3_12.0 <- scenerasters$WV7.3-scenerasters$IR12.0
      T8.7_10.8 <- scenerasters$IR8.7-scenerasters$IR10.8
      T10.8_12.0 <- scenerasters$IR10.8-scenerasters$IR12.0
      T3.9_7.3 <- scenerasters$IR3.9-scenerasters$WV7.3
      T3.9_10.8 <- scenerasters$IR3.9-scenerasters$IR10.8
      sunzenith<-raster(scenes[substr(scenes,20,23) =="ma11"])
      scenerasters<-stack(scenerasters,T6.2_10.8,T7.3_12.0,T8.7_10.8,T10.8_12.0,T3.9_7.3,T3.9_10.8,sunzenith)
      names(scenerasters)<-c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3","IR8.7",
                       "IR9.7","IR10.8","IR12.0","IR13.4","T6.2_10.8",
                       "T7.3_12.0","T8.7_10.8","T10.8_12.0","T3.9_7.3","T3.9_10.8","SunZenith")

### Texture parameters #########################################################
glcm_filter <- texture.variables (x=scenerasters, nrasters=1:(nlayers(scenerasters)-1),
                                  filter=c(3,5),var=c("mean", "variance", "homogeneity", 
                                                      "contrast", "dissimilarity", 
                                                      "entropy","second_moment"))
### Geometry parameters #########################################################
cloud_geometry <- geometry.variables (x=scenerasters[[1]])
### append variables to train table ############################################
      #date = substr(scenerasters[1],2,13)
      #rm rst
### add radar information ######################################################
      
      
      setwd(paste0(msgpath,months[i],"/",days[k]))
    }
  setwd(paste0(msgpath,months[i]))
  }
  setwd(msgpath) 
}



