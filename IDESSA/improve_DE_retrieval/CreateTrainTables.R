#nicht sommer/winter trennen
#day,night,inb auch nicht trennen -> 0 für NA? test ob das geht...
rm(list=ls())

library(raster)
source("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/functions/geometryParameters.R")
source("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/functions/TextureParameters.R")


msgpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/"
radarpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/"

setwd(msgpath)
datatable=data.frame()

### Go through all months, days, hours and scenes ##############################
months=list.files()
for (i in months){
  setwd(paste0(msgpath,i)) 
  days=list.files()
  for (k in days){
    setwd(paste0(msgpath,i,"/",k))
    hours=list.files()
    for (l in hours){
      print (paste0("month: ", i, " day:", k, " hour: ", l, " in progress.."))
      setwd(paste0(msgpath,i,"/",k,"/",l))
### Get date ###################################################################
      scenes=Sys.glob("*.rst")
      date = substr(scenes[1],1,12)
### get radar information ######################################################
      date = substr(scenes[1],1,12)
      radarpathtmp= paste0(radarpath,i,"/",k)
      tmp=list.files(radarpathtmp,pattern=glob2rx("*.rst"))
      radardata=raster(paste0(radarpathtmp,"/",tmp[substr(tmp,1,12)==date]))
      radardata[values(radardata)==-99]=NA
### only process data if they include at least 2000 rainy pixels (rainy=>0.06mm)
      if (sum(values(radardata)>0.06,na.rm=TRUE)<2000) next
### Load MSG data ##############################################################
      x=c("ca02p0001","ca02p0002","ca02p0003","ct01dk004","ct01dk005","ct01dk006",
            "ct01dk007","ct01dk008","ct01dk009","ct01dk010","ct01dk011")
      scenerasters=stack(scenes[substr(scenes,20,28)%in%x])
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
    
      glcm_3=as.data.frame(lapply(glcm_filter$size_3,values))
      names(glcm_3)<-paste0("filter3_",names(glcm_3))
 
      glcm_5=as.data.frame(lapply(glcm_filter$size_5,values))
      names(glcm_5)<-paste0("filter5_",names(glcm_5))

      datatable <- rbind(datatable,cbind(rep(date,nrow(glcm_3)),cbind(values(scenerasters)),cbind(values(cloud_geometry)),glcm_3,glcm_5,values(radardata)))
 
      rm(scenerasters,cloud_geometry,glcm_3,glcm_5,glcm_filter,T6.2_10.8,T7.3_12.0,
         T8.7_10.8,T10.8_12.0,T3.9_7.3,T3.9_10.8,sunzenith,radardata,scenes,radarpathtmp,tmp,date)
      gc()      

### finish the script ##########################################################     
    }
  }
}

write.table(datatable,"/media/hanna/ubt_kdata_0005/improve_DE_retrieval/datatable.csv")

