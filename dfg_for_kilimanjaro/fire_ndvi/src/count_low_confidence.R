library(doParallel)
registerDoParallel(cl <- makeCluster(3))

# Terra
fls_mod <- list.files("data/md14a1/", pattern = "^CRP_MOD", full.names = TRUE)
rst_mod <- stack(fls_mod)

val_mod <- foreach(i = 1:nlayers(rst_mod), .packages = c("raster", "rgdal"), 
                   .combine = "c") %dopar% {
  nq <- unique(rst_mod[[i]])
  return(7 %in% nq)
}

which(val_mod)

# Aqua
fls_myd <- list.files("data/md14a1/", pattern = "^CRP_MYD", full.names = TRUE)
rst_myd <- stack(fls_myd)

val_myd <- foreach(i = 1:nlayers(rst_myd), .packages = c("raster", "rgdal"), 
                   .combine = "c") %dopar% {
  nq <- unique(rst_myd[[i]])
  return(7 %in% nq)
}

# Visual comparison
rst_low_crp <- stack("data/md14a1/low/CRP_MOD14A1.A2001321.FireMask.tif")[[3]]
rst_low_mrg <- raster("data/md14a1/low/MRG_CRP_MCD14A1.A2001323.FireMask.tif")
rst_low_rcl <- raster("data/md14a1/low/RCL_MRG_CRP_MCD14A1.A2001323.FireMask.tif")
rst_nom <- raster("data/md14a1/RCL_MRG_CRP_MCD14A1.A2001323.FireMask.tif")
