lib <- c("raster", "rgdal", "MODIS", "remote", "doParallel", "reshape2", 
         "ggplot2", "dplyr", "scales", "Rsenal", "Kendall", "RColorBrewer", 
         "latticeExtra", "zoo")
sapply(lib, function(x) library(x, character.only = TRUE))

source("sortByElevation.R")
source("kendallStats.R")

setwd("/media/envin/XChange/kilimanjaro/gimms3g/gimms3g/")

# Temporal range
st <- "200301"
nd <- "201112"

## DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

## GIMMS NDVI3G
fls_gimms <- list.files("data/rst/whittaker", pattern = "_wht_aggmax.tif$", 
                        full.names = TRUE)
fls_gimms <- fls_gimms[grep(st, fls_gimms):grep(nd, fls_gimms)]
rst_gimms <- stack(fls_gimms)
rst_gimms_crp <- crop(rst_gimms, rasterToPolygons(rst_gimms[[1]]))


## MODIS

fls_modis_myd13 <- list.files("data/modis", pattern = "^SCL_AGGMAX.*.tif$", 
                              full.names = TRUE)
fls_modis_myd13 <- fls_modis_myd13[grep(st, fls_modis_myd13):grep(nd, fls_modis_myd13)]
rst_modis_myd13 <- stack(fls_modis_myd13)


### define index for training data
pred_ind <- 1:60

gimms_stck_pred <- rst_gimms_crp[[pred_ind]]
gimms_stck_eval <- rst_gimms_crp[[-pred_ind]]

# ndvi_modes <- foreach(i = c(rst_modis_myd13, rst_modis_max, rst_modis_med, 
#               rst_modis_tmpmax, rst_modis_tmpmed), .packages = lib) %dopar% { 

### create training (pred) and evaluation (eval) sets
mod_stck_pred <- rst_modis_myd13[[pred_ind]]                  # MODIS [[1:60]]
mod_stck_eval <- rst_modis_myd13[[-pred_ind]] # MODIS [[61:120]]






library(caret)

val_pred <- getValues(mod_stck_pred)
val_pred_gimms <- t(getValues(gimms_stck_pred))

val_eval_gimms <- as.data.frame(t(getValues(gimms_stck_eval)))
names(val_eval_gimms) <- paste("Var", 1:63, sep = "")

template <- mod_stck_pred[[1]]
template[] <- NA

registerDoParallel(cl <- makeCluster(3))

val_fit <- foreach(i = 1:nrow(val_pred), .packages = c("raster", "rgdal", "caret"), 
                   .combine = "rbind") %dopar% {
  data_train <- as.data.frame(cbind(val_pred[i, ], val_pred_gimms))
  names(data_train)[2:64] <- paste("Var", 1:63, sep = "")
  
  model <- train(V1 ~ ., data_train, method = "cubist")
  
  fit <- predict(model, newdata = val_eval_gimms)
  return(fit)
}