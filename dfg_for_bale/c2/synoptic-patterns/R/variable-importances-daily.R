### environment -----

## packages
# devtools::install_github("fdetsch/Orcs")
library(Orcs)
lib = c("parallel", "ncdf4", "caret", "velox")
loadPkgs(lib)

## parallelization
n = 0.75 * detectCores()
cl = makePSOCKcluster(n)
jnk = clusterEvalQ(cl, { library(raster); library(velox); library(rworldmap) })


### data import and value extraction -----

## spatial domains
bmn = extent(c(25, 74, -5, 30)); bmn = ext2spy(bmn)
jro = extent(c(25, 74, -20, 15)); jro = ext2spy(jro)
clusterExport(cl, c("bmn", "jro"))

## chirps rainfall
rsp = "/media/sd19006/data/users/fdetsch/R-Server"
cps = brick(file.path(rsp, "data/bale/chirps-2.0/chirps-2.0_bale_daily.tif"))
prc = parSapply(cl, unstack(cps), function(i) sum(i[], na.rm = TRUE))

## reanalysis variables (means per spatial domain)
p250 = "../../../../../casestudies/bale/era-interim/daily/2001_2016/pressure_250.nc"
p500 = "../../../../../casestudies/bale/era-interim/daily/2001_2016/pressure_500.nc"
nc = nc_open(p250)
nms_p = names(nc$var)
nc_close(nc); rm(nc)

surface = "../../../../../casestudies/bale/era-interim/daily/2001_2016/surface.nc"
nc = nc_open(surface)
nms_s = names(nc$var)
nc_close(nc); rm(nc)

clusterExport(cl, c("p250", "p500", "surface"))


### bale mountains -----

## pressure levels
dat_p = do.call("cbind", parLapply(cl, nms_p, function(i) {
  rst250 = suppressWarnings(stack(p250, varname = i))
  
  ids = grep("2014.01.01", names(rst250))
  ids = seq(ids, ids + 364)
  rst250 = rst250[[ids]]
  
  rst250 = crop(rst250, bmn, snap = "out")
  val250 = sapply(unstack(rst250), function(i) mean(i[], na.rm = TRUE))
  
  rst500 = suppressWarnings(stack(p500, varname = i))
  rst500 = rst500[[ids]]
  rst500 = crop(rst500, bmn, snap = "out")
  val500 = sapply(unstack(rst500), function(i) mean(i[], na.rm = TRUE))
  
  cbind(val250, val500)
}))

## surface
dat_s = do.call("cbind", parLapply(cl, nms_s, function(i) {
  rst = stack(surface, varname = i)

  ids = grep("2014.01.01", names(rst))
  ids = seq(ids, ids + 364)
  rst = rst[[ids]]

  rst = crop(rst, bmn, snap = "out")
  
  if (i == "sst") {
    rst = mask(rst, countriesCoarse, inverse = TRUE)
  }
  
  sapply(unstack(rst), function(i) mean(i[], na.rm = TRUE))
}))

dat = data.frame(cbind(dat_p, dat_s))
names(dat) = c(paste0("p250_", nms_p)
               , paste0("p500_", nms_p)
               , nms_s)

dat = data.frame(dat, "precip" = prc)


## random forest
rfm = train(precip ~ ., data = dat, method = "rf", tuneLength = 3
            , trControl = trainControl("cv"), importance = TRUE)

plot(rfm)
plot(varImp(rfm))

## fit model (4-day delay)
dat_lag4 = data.frame(dat[1:(nrow(dat)-4), -ncol(dat)]
                      , "precip" = dat[5:nrow(dat), ncol(dat)])

rfm_lag4 = train(precip ~ ., data = dat_lag4, method = "rf", tuneLength = 3
                 , trControl = trainControl("cv"), importance = TRUE)

plot(rfm_lag4)
plot(varImp(rfm_lag4))


### kilimanjaro -----

## pressure levels
dat_p = do.call("cbind", parLapply(cl, nms_p, function(i) {
  rst250 = stack(p250, varname = i)
  rst250 = crop(rst250, jro, snap = "out")
  val250 = sapply(unstack(rst250), function(i) mean(i[], na.rm = TRUE))
  
  rst500 = stack(p500, varname = i)
  rst500 = crop(rst500, jro, snap = "out")
  val500 = sapply(unstack(rst500), function(i) mean(i[], na.rm = TRUE))
  
  cbind(val250, val500)
}))

## surface
dat_s = do.call("cbind", parLapply(cl, nms_s, function(i) {
  rst = stack(surface, varname = i)
  rst = crop(rst, jro, snap = "out")
  sapply(unstack(rst), function(i) mean(i[], na.rm = TRUE))
}))

dat = data.frame(cbind(dat_p, dat_s))
names(dat) = c(paste0("p250_", nms_p)
               , paste0("p500_", nms_p)
               , nms_s)

dat = data.frame(dat, "precip" = prc)


## random forest 
rfm = train(precip ~ ., data = dat, method = "rf", tuneLength = 3
            , trControl = trainControl("cv"), importance = TRUE)

plot(rfm)
plot(varImp(rfm))

## fit model (1-month delay)
dat_lag1 = data.frame(dat[1:(nrow(dat)-1), -ncol(dat)]
                      , "precip" = dat[2:nrow(dat), ncol(dat)])

rfm_lag1 = train(precip ~ ., data = dat_lag1, method = "rf", tuneLength = 3
                 , trControl = trainControl("cv"), importance = TRUE)

plot(rfm_lag1)
plot(varImp(rfm_lag1))

## close parallel backend
stopCluster(cl)
