### environment -----

## packages
# devtools::install_github("fdetsch/Orcs")
library(Orcs)
lib = c("parallel", "ncdf4", "caret")
loadPkgs(lib)

## parallelization
n = 0.75 * detectCores()
cl = makePSOCKcluster(n)
jnk = clusterEvalQ(cl, { library(raster); library(velox) })


### data import and value extraction -----

## spatial domains
bmn = extent(c(25, 74, -5, 30)); bmn = ext2spy(bmn)
jro = extent(c(25, 74, -20, 15)); jro = ext2spy(jro)
clusterExport(cl, c("bmn", "jro"))

## chirps rainfall
cps = brick(file.path(rsp, "data/bale/chirps-2.0/chirps-2.0_bale_monthly_1981-2016.tif"))
prc = parSapply(cl, unstack(cps), function(i) sum(i[], na.rm = TRUE))

## reanalysis variables (means per spatial domain)
rsp = "/media/sd19006/data/users/fdetsch/R-Server"
ncp = file.path(rsp, "data/bale/ERA-Interim/east_africa_monthly.nc")
clusterExport(cl, "ncp")

nc = nc_open(ncp)
nms = names(nc$var)
nc_close(nc); rm(nc)

dat = do.call("cbind", parLapply(cl, nms, function(i) {
  rst = stack(ncp, varname = i)
  rst = crop(rst, bmn, snap = "out")
  val = sapply(unstack(rst), function(i) mean(i[], na.rm = TRUE))
}))

dts = seq(as.Date("1979-01-01"), as.Date("2017-06-01"), "month")
ids = which(dts == "1981-01-01"):which(dts == "2016-12-01")
dat = dat[ids, ]

dat = data.frame(dat, prc)
colnames(dat) = c(nms, "PRCP")


### random forest -----

## fit model
rfm = train(PRCP ~ ., data = dat, method = "rf", tuneLength = 3
            , trControl = trainControl("cv"), importance = TRUE)

plot(rfm)
plot(varImp(rfm))
