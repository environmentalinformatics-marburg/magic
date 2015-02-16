calculatePredictors<-function (scenerasters,sunzenith,variables,xderivTexture){
  
  T0.6_1.6 <- scenerasters$VIS0.6-scenerasters$NIR1.6
  T6.2_10.8 <- scenerasters$WV6.2-scenerasters$IR10.8
  T7.3_12.0 <- scenerasters$WV7.3-scenerasters$IR12.0
  T8.7_10.8 <- scenerasters$IR8.7-scenerasters$IR10.8
  T10.8_12.0 <- scenerasters$IR10.8-scenerasters$IR12.0
  T3.9_7.3 <- scenerasters$IR3.9-scenerasters$WV7.3
  T3.9_10.8 <- scenerasters$IR3.9-scenerasters$IR10.8
  scenerasters<-stack(scenerasters,T0.6_1.6,T6.2_10.8,T7.3_12.0,T8.7_10.8,
                    T10.8_12.0,T3.9_7.3,T3.9_10.8,sunzenith)
  names(scenerasters)=c("VIS0.6","VIS0.8","NIR1.6","IR3.9","WV6.2","WV7.3",
                      "IR8.7","IR9.7","IR10.8","IR12.0","IR13.4",
                      "T0.6_1.6","T6.2_10.8","T7.3_12.0","T8.7_10.8",
                      "T10.8_12.0","T3.9_7.3","T3.9_10.8","sunzenith")
  scenerasters<-scenerasters[[c(variables,derivVariables)]]
  names(scenerasters)<- c(variables,derivVariables)

### Texture parameters #########################################################
  glcm_filter <- texture.variables (x=scenerasters[[xderivTexture]],
                                  n_grey = 32,filter=c(3),    
                                  var=c("mean", "variance", "homogeneity", 
                                        "contrast", "dissimilarity", 
                                        "entropy","second_moment"))
  names(glcm_filter$size_3)<-paste0("f3_",names(glcm_filter$size_3))

### Geometry parameters #########################################################
  cloud_geometry <- geometry.variables (x=scenerasters[[4]])

### Texture per Patch ##########################################################
  glcmPatches<-glcmPerPatch(x=scenerasters[[xderivTexture]],cloud_geometry$cloudPatches)
  glcmPerPatchRaster<-foreach(i=2:ncol(glcmPatches),.combine=stack,
                            .packages=c("raster","doParallel"))%dopar%{
                              reclassify(cloud_geometry$cloudPatches,matrix(c(
                                glcmPatches[,1],glcmPatches[,i]),ncol=2))}
  reclasstable=cbind(1:max(values(cloud_geometry$cloudPatches),na.rm=TRUE),
                   1:max(values(cloud_geometry$cloudPatches),
                         na.rm=TRUE)%in%glcmPatches[,1])
  reclasstable[reclasstable[,2]==0,2]=NA
  reclasstable[!is.na(reclasstable[,2]),2]=reclasstable[!is.na(reclasstable[,2]),1]
  reclasstable=reclasstable[is.na(reclasstable[,2]),]
  if (nrow(glcmPatches)==1){
    glcmPerPatchRaster=reclassify(glcmPerPatchRaster,matrix(reclasstable,ncol=2))
  } else{
    glcmPerPatchRaster=reclassify(glcmPerPatchRaster,reclasstable)
  }
  names(glcmPerPatchRaster)<-colnames(glcmPatches)[-1]
  names(glcmPerPatchRaster)=paste0("pp_",names(glcmPerPatchRaster))
### zonal stat: Mean,sd,min,max per Pacth ######################################
  ZonalStats=cloud_geometry$cloudPatches
###mean
  tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
               cloud_geometry$cloudPatches,fun="mean")
  MeanPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                     .packages=c("raster","doParallel"))%dopar%{
                       reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 
  names(MeanPerPatch)=paste0("mean_",names(scenerasters)[
    1:(nlayers(scenerasters)-1)])
###sd
  tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
               cloud_geometry$cloudPatches,fun="sd")
  SdPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                   .packages=c("raster","doParallel"))%dopar%{
                     reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 

  names(SdPerPatch)=paste0("sd_",names(scenerasters)[
    1:(nlayers(scenerasters)-1)])
###min
  tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
               cloud_geometry$cloudPatches,fun="min")
  MinPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                    .packages=c("raster","doParallel"))%dopar%{
                      reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 
  names(MinPerPatch)=paste0("min_",names(scenerasters)[
    1:(nlayers(scenerasters)-1)])
###max
  tmpStats=zonal(scenerasters[[1:(nlayers(scenerasters)-1)]],
               cloud_geometry$cloudPatches,fun="max")
  MaxPerPatch=foreach(i=2:ncol(tmpStats),.combine=stack,
                    .packages=c("raster","doParallel"))%dopar%{
                      reclassify(ZonalStats,matrix(tmpStats[,c(1,i)],ncol=2))} 
  names(MaxPerPatch)=paste0("max_",names(scenerasters)[
    1:(nlayers(scenerasters)-1)])

################################################################################
###             Compile data table
################################################################################

  dayOfYear<-scenerasters[[1]]
  values(dayOfYear)=rep(strptime(date, "%Y%m%d")$yday+1,ncell(dayOfYear))


  result=list(dayOfYear,scenerasters,MeanPerPatch,SdPerPatch,MinPerPatch,MaxPerPatch,
            glcmPerPatchRaster,cloud_geometry,glcm_filter)
  names(result)=c("dayOfYear","scenerasters","MeanPerPatch","SdPerPatch","MinPerPatch","MaxPerPatch",
            "glcmPerPatchRaster","cloud_geometry","glcm_filter")
  return(result)

}