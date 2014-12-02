################################################################################
# Calculation of texture measures from grey-level co-occurrence matrices of
# MSG SEVIRI channels
################################################################################
librayr(glcm)

#### Read test data ############################################################
setwd("/media/hanna/ubt_kdata_0005/msg_images/MT9P201210121215_mt09s/cal/")

filelist=list.files(pattern="rst")
r=stack(filelist)

#### For testing: Apply basic cloudmask ########################################
cm=r[[1]]
cm[cm>0.6]=1
cm[cm<=0.6]=NA

rc=r*cm

#### Calculate filters #########################################################
rc=stretch(rc,0,255)

library(doParallel)
registerDoParallel(detectCores())


glcm_filter=foreach(i=1:nlayers(rc),.packages= c("glcm","raster"))%dopar%{
 
  tmp=glcm(rc[[i]], n_grey = 255, window = c(5, 5),
          shift=list(c(0,1), c(1,1), c(1,0), c(1,-1))) #average texture for each shift
}

################################################################################
################################################################################
