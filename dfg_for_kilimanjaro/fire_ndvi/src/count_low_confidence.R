library(raster)
library(doParallel)
registerDoParallel(cl <- makeCluster(2))

setwd("/media/envin/XChange/kilimanjaro/ndvi/")

# Terra
fls_mod <- list.files("data/md14a1/low/", pattern = "^CRP_MOD", full.names = TRUE)
rst_mod <- stack(fls_mod)

val_mod <- foreach(i = 1:nlayers(rst_mod), .packages = c("raster", "rgdal"), 
                   .combine = "c") %dopar% {
  nq <- unique(rst_mod[[i]])
  return(7 %in% nq)
}

which(val_mod)

# Aqua
fls_myd <- list.files("data/md14a1/", pattern = "^CRP_MYD.*.tif$", full.names = TRUE)
rst_myd <- stack(fls_myd)

val_myd <- foreach(i = 1:nlayers(rst_myd), .packages = c("raster", "rgdal"), 
                   .combine = "c") %dopar% {
  nq <- unique(rst_myd[[i]])
  return(7 %in% nq)
}

which(val_myd)

# Visual comparison
rst_low_crp <- stack("data/md14a1/low/CRP_MOD14A1.A2001321.FireMask.tif")[[3]] # identical to plot(rst_mod[[600]])
rst_low_mrg <- raster("data/md14a1/low/MRG_CRP_MCD14A1.A2001323.FireMask.tif")
rst_low_rcl <- raster("data/md14a1/low/RCL_MRG_CRP_MCD14A1.A2001323.FireMask.tif")
rst_nom_rcl <- raster("data/md14a1/nominal/RCL_MRG_CRP_MCD14A1.A2001323.FireMask.tif")


### Amount of low confident, medium confident and high confident fires in 
### merged (MRG*) layers

fls_mrg <- list.files("data/md14a1/low", pattern = "^MRG.*.tif$", full.names = TRUE)
st <- grep("2001", fls_mrg)[1]
nd <- grep("2013", fls_mrg)[length(grep("2013", fls_mrg))]
fls_mrg <- fls_mrg[st:nd]
rst_mrg <- stack(fls_mrg)

tbl_cfd <- foreach(i = 1:nlayers(rst_mrg), .packages = c("raster", "rgdal"), 
                   .combine = "rbind") %dopar% {
  val <- getValues(rst_mrg[[i]])
  lo <- sum(val %in% c(7, 17, 27, 37, 47, 57, 67, 70:77))
  no <- sum(val %in% c(8, 18, 28, 38, 48, 58, 68, 78, 80:88))
  hi <- sum(val %in% c(9, 19, 29, 39, 49, 59, 69, 79, 89, 90:99))
  data.frame(lo = lo, no = no, hi = hi)
}