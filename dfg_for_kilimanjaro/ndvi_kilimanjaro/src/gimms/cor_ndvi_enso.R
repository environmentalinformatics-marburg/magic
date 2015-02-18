# packages
library(reshape2)
library(raster)
library(doParallel)

# parallelization
cl <- makeCluster(4)
registerDoParallel(cl)

# start and end
st <- "1982-01"
nd <- "2011-12"

# oni
oni <- read.csv("data/oni/oni__1950_2014.csv")
month_num <- formatC(1:12, width = 2, flag = "0")
names(oni) <- c("Year", month_num)
oni_mlt <- melt(oni, id.vars = 1, variable.name = "Month", value.name = "ONI")

dates <- paste(oni_mlt$Year, oni_mlt$Month, "01", sep = "-")
oni_mlt$Date <- as.Date(dates)
oni_mlt <- oni_mlt[order(oni_mlt$Date), ]

id_st <- grep(st, oni_mlt$Date)
id_nd <- grep(nd, oni_mlt$Date)
oni_mlt <- oni_mlt[id_st:id_nd, c("Date", "ONI")]

# dmi
dat_dmi <- read.table("data/dmi/dmi.dat")
names(dat_dmi) <- c("Year", "Month", "DMI")

dat_dmi[, 2] <- formatC(dat_dmi[, 2], width = 2, flag = "0")
dates <- paste(dat_dmi[, 1], dat_dmi[, 2], "01", sep = "-")
dat_dmi$Date <- as.Date(dates)

id_st <- grep(st, dat_dmi$Date)
dat_dmi <- dat_dmi[id_st:nrow(dat_dmi), c("Date", "DMI")]

# merge oni, dmi
dat_oni_dmi <- merge(oni_mlt, dat_dmi, all = TRUE, by = 1)

# ndvi
fls_ndvi <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_ndvi <- stack(fls_ndvi)
mat_ndvi <- as.matrix(rst_ndvi)


## correlation

# lag with maximum correlation
Find_Max_CCF <- function(a, b, lag.max = NULL) {
  d <- ccf(a, b, plot = FALSE, lag.max = lag.max)
  cor = d$acf[,,1]
  lag = d$lag[,,1]
  res = data.frame(cor,lag)
  res_max = res[which.max(res$cor),]
  return(res_max)
} 

# ccf
ls_ccf <- foreach(id = c("ONI", "DMI")) %do% {
  dat_ccf <- foreach(i = 1:nrow(mat_ndvi), .combine = "rbind") %dopar% {
    dat <- cbind(dat_oni_dmi[, id], mat_ndvi[i, ])
    dat <- na.omit(dat)
    Find_Max_CCF(dat[, 1], dat[, 2], lag.max = 8)
  }
  
  rst_ccf <- rst_lag <- rst_ndvi[[1]]
  rst_ccf[] <- dat_ccf[, 1]
  rst_lag[] <- dat_ccf[, 2]
  rst_ccf_lag <- stack(rst_ccf, rst_lag)
  
  return(rst_ccf_lag)
}

library(RColorBrewer)
cols_div <- colorRampPalette(rev(brewer.pal(11, "PuOr")))
spplot(rst_lag, col.regions = cols_div(100), at = -6.5:6.5)
spplot(rst_ccf^2, col.regions = colorRampPalette(brewer.pal(9, "PuBu")), at = seq(-.5, .5, .05))

dat_ccf_oni <- foreach(i = 1:nrow(mat_ndvi), .combine = "rbind") %dopar% {
  Find_Max_CCF(oni_mlt$ONI, mat_ndvi[i, ], lag.max = 8)
}
