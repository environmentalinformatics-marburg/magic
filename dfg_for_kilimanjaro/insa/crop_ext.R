library(raster)
library(rgdal)

### Input preparation ########################################################
#inputpath <- "/media/tims_ex/sst_kili_analysis"
#inputpath <- "/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau"
inputpath <- "/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl"
ptrn <- "*Cloud_Optical_Thickness.tif"

### list files in direcotry ##################################################
fnames_tau <- list.files(inputpath, 
                            pattern = glob2rx(ptrn), 
                            recursive = T)

### read into raster format ##################################################
system.time({
  tau.kili <- lapply(seq(fnames_tau), function(i) {
    raster(paste(inputpath, fnames_tau[i], sep = "/"))
  }
  )
})

stck.tau.kili <- stack(tau.kili)

# wolkenbedeckung - cirren
# grenzwert cirren
# durchschnittliche tau pro monat
# trend pro monat C<ber alle Jahre
# calc <- (stck.tau.kili, fun = sd)



##############################################################################
##############################################################################
### get extent for all files #################################################
ext.list <- lapply(seq(tau.kili), function(i) {
  extent(tau.kili[[i]])
})

####### test files #################
# ymax = -2
# xmin = 36.5
# lr_lat = -4
# xmax = 38.5

# ext <- extent(c(36.5, 38.5, -4, -2))
########################################

### get max for x.min #############################################

ext.min <- sapply(seq(ext.list), function(i){
  ext.list[[i]]@xmin
})

x.min <- sapply(seq(ext.list), function(i){
  min(ext.list[[i]]@xmin)
})

max(x.min)

### get max for y.min ############################################
ext.min <- sapply(seq(ext.list), function(i){
  ext.list[[i]]@ymin
})

y.min <- sapply(seq(ext.list), function(i){
  min(ext.list[[i]]@ymin)
})

max(y.min)

### get min for x.max #################################################
ext.min <- sapply(seq(ext.list), function(i){
  ext.list[[i]]@xmax
})

x.max <- sapply(seq(ext.list), function(i){
  min(ext.list[[i]]@xmax)
})

min(x.max)

### get min for y.max ################################################
ext.min <- sapply(seq(ext.list), function(i){
  ext.list[[i]]@ymax
})

y.max <- sapply(seq(ext.list), function(i){
  min(ext.list[[i]]@ymax)
})

min(y.max)

### ausschneiden ##############################################
ext <- extent(c(max(x.min), min(x.max), max(y.min), min(y.max)))

tau.kili.crop <- lapply(seq(tau.kili), function(i){
  crop(tau.kili[[i]], ext)
})

crop(tau.kili[[3]], ext)

raster::crop(tau.kili[[150]], ext)

stck <- stack(tau.kili)


