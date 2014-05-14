library(raster)
library(rgdal)
library(Kendall)


### Input preparation ########################################################
#inputpath <- "/media/tims_ex/sst_kili_analysis"
#inputpath <- "/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau"
# inputpath <- "/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl"
inputpath <- "D:/modiscdata_myd06/test/tifs/prj_scl"
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
stck.tau.kili.clc <- calc(stck.tau.kili, fun = mean)

spplot(stck.tau.kili.clc)

time <- 1:nlayers(stck.tau.kili)
fun <- function(x) { lm(x ~ time)$coefficients[2] }
x2 <- calc(stck.tau.kili, fun)


# wolkenbedeckung - cirren
# grenzwert cirren
# durchschnittliche tau pro monat
# trend pro monat C<ber alle Jahre
# calc <- (stck.tau.kili, fun = sd)
