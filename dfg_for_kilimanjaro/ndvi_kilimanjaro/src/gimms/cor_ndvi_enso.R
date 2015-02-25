# packages
lib <- c("reshape2", "raster", "remote", "lubridate", "doParallel", "RColorBrewer")
jnk <- sapply(lib, function(i) library(i, character.only = TRUE))

# functions
source("extentEnsoSeason.R")

# parallelization
cl <- makeCluster(4)
registerDoParallel(cl)

# start and end
st <- "1982-01"
nd <- "2011-12"


## oni from otte et al. (submitted)

oni <- read.csv("data/oni/enso_and_iod.csv", skip = 1, stringsAsFactors = FALSE)
oni$Season <- paste0(oni[, 3], oni[, 4], oni[, 5])
oni <- oni[, -(4:5)]
month_num <- formatC(c(7:12, 1:6), width = 2, flag = "0")
names(oni)[4:ncol(oni)] <- month_num
oni_mlt <- melt(oni, id.vars = 1:3, variable.name = "Month", value.name = "ONI")

years <- strsplit(oni_mlt$Season, "-")
oni_mlt$Year1 <- sapply(years, "[[", 1)
oni_mlt$Year2 <- sapply(years, "[[", 2)
oni_mlt$Year <- ifelse(as.numeric(as.character(oni_mlt$Month)) %in% 1:6, 
                       oni_mlt$Year2, oni_mlt$Year1)
dates <- paste(oni_mlt$Year, oni_mlt$Month, "01", sep = "-")
oni_mlt$Date <- as.Date(dates)
oni_mlt <- oni_mlt[order(oni_mlt$Date), ]

id_st <- grep(st, oni_mlt$Date)
id_nd <- grep(nd, oni_mlt$Date)
oni_mlt <- oni_mlt[id_st:id_nd, c("Date", "Season", "ONI", "Type", "IOD")]


## dmi

dat_dmi <- read.table("data/dmi/dmi.dat")
names(dat_dmi) <- c("Year", "Month", "DMI")

dat_dmi[, 2] <- formatC(dat_dmi[, 2], width = 2, flag = "0")
dates <- paste(dat_dmi[, 1], dat_dmi[, 2], "01", sep = "-")
dat_dmi$Date <- as.Date(dates)

id_st <- grep(st, dat_dmi$Date)
dat_dmi <- dat_dmi[id_st:nrow(dat_dmi), c("Date", "DMI")]

# merge oni, dmi
dat_oni_dmi <- merge(oni_mlt, dat_dmi, all = TRUE, by = 1)


## ndvi

fls_ndvi <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_ndvi <- stack(fls_ndvi)
mat_ndvi <- as.matrix(rst_ndvi)

ndvi_date <- seq(as.Date("1982-01-01"), as.Date("2011-12-01"), "month")

# exclusion of areas with low ndvi, cf brown et al. (2006), based on upper quartile
# rst_ndvi_quan75 <- calc(rst_ndvi, fun = function(x) quantile(x, probs = .75), 
#                         filename = "data/rst/cor_ndvi_enso/ndvi_quan75", 
#                         format = "GTiff", overwrite = TRUE)
rst_ndvi_quan75 <- raster("data/rst/cor_ndvi_enso/ndvi_quan75.tif")
val_ndvi_quan75 <- getValues(rst_ndvi_quan75)

id_lndvi <- which(val_ndvi_quan75 <= .3)

rst_ndvi[id_lndvi] <- NA

# areas with low variance, based on 10-90% iqr
# rst_ndvi_quan10 <- calc(rst_ndvi, fun = function(x) quantile(x, probs = .1), 
#                         filename = "data/rst/cor_ndvi_enso/ndvi_quan10", 
#                         format = "GTiff", overwrite = TRUE)
rst_ndvi_quan10 <- raster("data/rst/cor_ndvi_enso/ndvi_quan10.tif")
val_ndvi_quan10 <- getValues(rst_ndvi_quan10)

# rst_ndvi_quan90 <- calc(rst_ndvi, fun = function(x) quantile(x, probs = .9), 
#                         filename = "data/rst/cor_ndvi_enso/ndvi_quan90", 
#                         format = "GTiff", overwrite = TRUE)
rst_ndvi_quan90 <- raster("data/rst/cor_ndvi_enso/ndvi_quan90.tif")
val_ndvi_quan90 <- getValues(rst_ndvi_quan90)

id_lvar <- which((val_ndvi_quan90 - val_ndvi_quan10) <= .1)

# tmp <- rst_ndvi[[1]]
# tmp[id_lvar] <- NA
# plot(tmp)

# deseason
rst_ndvi_dsn <- deseason(rst_ndvi)
mat_ndvi_dsn <- as.matrix(rst_ndvi_dsn)

# long-term means, cf. anyamba et al. (2002)
indices <- rep(1:12, nlayers(rst_ndvi)/12)
# rst_ndvi_ltm <- stackApply(rst_ndvi, indices, fun = mean, 
#                            filename = "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211_ltm.tif", 
#                            bylayer = FALSE, format = "GTiff", overwrite = TRUE)
rst_ndvi_ltm <- stack("data/rst/whittaker/gimms_ndvi3g_dwnscl_8211_ltm.tif")
mat_ndvi_ltm <- as.matrix(rst_ndvi_ltm)
med_ndvi_ltm <- apply(mat_ndvi_ltm, 2, function(...) median(..., na.rm = TRUE))
# df_med_ndvi_ltm <- data.frame(x = as.factor(1:12), y = med_ndvi_ltm)
df_med_ndvi_ltm <- data.frame(x = 1:12, y = med_ndvi_ltm[c(7:12, 1:6)])

rst_ndvi_anom <- (rst_ndvi/rst_ndvi_ltm - 1) * 100

# exclusion of areas with low ndvi, cf brown et al. (2006)
rst_ndvi[id_lndvi] <- NA
# rst_ndvi <- writeRaster(rst_ndvi, "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211_wolndvi.tif", 
#                         bylayer = FALSE, format = "GTiff", overwrite = TRUE)
rst_ndvi_dsn[id_lndvi] <- NA
rst_ndvi_anom[id_lndvi] <- NA

# rst_ndvi[id_lvar] <- NA
# rst_ndvi_dsn[id_lvar] <- NA
# rst_ndvi_anom[id_lvar] <- NA

mat_ndvi_dsn <- as.matrix(rst_ndvi_dsn)
mat_ndvi_anom <- as.matrix(rst_ndvi_anom)

# remove all np pixels
np <- readOGR("data/shp/", 
              layer = "fdetsch-kilimanjaro-new_np-1420532792846_epsg21037")

rst_ndvi_anom_rmnp <- rst_ndvi_anom
rst_ndvi_anom_rmnp <- mask(rst_ndvi_anom_rmnp, np, inverse = TRUE)
mat_ndvi_anom_rmnp <- as.matrix(rst_ndvi_anom_rmnp)


### correlation

## oni ~ ndvi

# el nino
groups <- list("all El Ninos", "pure El Ninos", "pure m/s El Ninos", 
               "El Ninos w IOD+", "m/s El Ninos w IOD+", "purest IOD+")

groups_nino <- list(c("WE", "ME", "SE"),
                    c("WE", "ME", "SE"),
                    c("ME", "SE"), 
                    c("WE", "ME", "SE"), 
                    c("ME", "SE"), 
                    "WE")

groups_iod <- list(c("M", "", "P"), 
                   "", 
                   "", 
                   "P", 
                   "P", 
                   "P")

ndvi_sp <- foreach(nino = groups_nino, iod = groups_iod, group = groups, 
                   span = rep(8, length(groups)), .packages = lib, 
                   .combine = "rbind") %dopar% {
  oni_mlt_sub <- subset(oni_mlt, (Type %in% nino) & (IOD %in% iod))

  # remove incomplete data (e.g. late 2011)
  seasons <- split(oni_mlt_sub, as.factor(oni_mlt_sub$Season))
  seasons_len <- sapply(seasons, nrow)
  seasons <- seasons[seasons_len == 12]
  
  oni_mlt_sub <- lapply(seasons, function(i) extentEnsoSeason(i, span = span))
  oni_mlt_sub <- do.call("rbind", oni_mlt_sub)
  
  sp <- smooth.spline(oni_mlt_sub$Month, oni_mlt_sub$NDVI, spar = .01)
  sp_pred <- predict(sp, seq(1, nlevels(oni_mlt_sub$Month), .01))
  
  mat_sp_pred <- do.call("cbind", sp_pred)
  df_sp_pred <- data.frame(group = group, mat_sp_pred)
#   df_sp_pred$x <- unique(oni_mlt_sub$Month)
  
  return(df_sp_pred)
}

red <- brewer.pal(4, "Reds")
blue <- brewer.pal(4, "Blues")

plot.colors <- c("black", blue[3], blue[4], red[3], red[4], "darkgreen")
names(plot.colors) <- groups

# extend ltm
# df_med_ndvi_ltm$x <- factor(df_med_ndvi_ltm$x)
ltm_ext <- merge(data.frame(x = 1:19), df_med_ndvi_ltm, by = "x", 
                 all = TRUE)
ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
# ltm_ext$x <- as.numeric(as.character(ltm_ext[, 1]))

# x-axis labels
lbl <- rep(c(7:12, 1:6, 7:12, 1:2))
names(lbl) <- 1:(12+span-1)

# df_med_ndvi_ltm$x <- factor(df_med_ndvi_ltm$x)
ltm_ext <- merge(data.frame(x = 1:20), df_med_ndvi_ltm, by = "x", 
                 all = TRUE)
ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
# ltm_ext$x <- as.numeric(as.character(ltm_ext[, 1]))

plot.colors <- c("black", blue[3], blue[4], red[3], red[4], "darkgreen")
names(plot.colors) <- groups

p_nino <- ggplot(aes(x, y, group = group, colour = group), data = ndvi_sp) + 
  geom_line() +
  geom_line(aes(x, y), data = ltm_ext, colour = "grey65", linetype = 2) + 
  scale_colour_manual("", values = plot.colors) + 
#   scale_x_discrete("\nMonth", labels = lbl) + 
  scale_x_continuous("\nMonth", breaks = 1:(12+span-1), labels = lbl) + 
  labs(x = "\nMonth", y = expression(atop(NDVI[median], "\n"))) + 
  theme_bw()

png("vis/cor_ndvi_oni/ts_nino_ndvi.png", width = 30, height = 12, units = "cm", 
    pointsize = 18, res = 300)
print(p_nino)
dev.off()

# occurrence of each group
ssn_cnt_nino <- foreach(nino = groups_nino, iod = groups_iod, group = groups, 
                        span = rep(8, length(groups)), .combine = "rbind") %do% {
  oni_mlt_sub <- subset(oni_mlt, (Type %in% nino) & (IOD %in% iod))
  ssn_cnt <- length(unique(oni_mlt_sub$Season))
  df_ssn_cnt <- data.frame(Group = group, Count = ssn_cnt)
  return(df_ssn_cnt)
}

# la nina
groups <- list("all La Ninas", "pure La Ninas", "pure m/s La Ninas", 
               "La Ninas w IOD+", "m/s La Ninas w IOD+", "purest IOD+")

groups_nina <- list(c("WL", "ML", "SL"),
                    c("WL", "ML", "SL"),
                    c("ML", "SL"), 
                    c("WL", "ML", "SL"), 
                    c("ML", "SL"), 
                    "WL")

groups_iod <- list(c("M", "", "P"), 
                   "", 
                   "", 
                   "P", 
                   "P", 
                   "P")

nina <- groups_nina[[6]]
iod <- groups_iod[[6]]
group <- groups[[6]]
span <- 8

ndvi_sp <- foreach(nina = groups_nina, iod = groups_iod, group = groups, 
                   span = rep(8, length(groups)), .packages = lib, 
                   .combine = "rbind") %dopar% {
  oni_mlt_sub <- subset(oni_mlt, (Type %in% nina) & (IOD %in% iod))
  
  # remove incomplete data (e.g. late 2011)
  seasons <- split(oni_mlt_sub, as.factor(oni_mlt_sub$Season))
  seasons_len <- sapply(seasons, nrow)
  seasons <- seasons[seasons_len == 12]
  
#   if (span > 0) {
#     dates_wspan <- lapply(seasons, function(i, span = span) {
#       dates <- i$Date
#       
#       dates_st <- dates[1]
#       dates_nd <- dates[length(dates)]
#       month(dates_nd) <- month(dates_nd) + span
#       
#       dates <- seq(dates_st, dates_nd, "month")
#       
#       return(dates)
#     })
#     dates_wspan <- do.call("c", dates_wspan)
#     dates_wspan <- dates_wspan[-which(duplicated(dates_wspan))]
#     
#     oni_mlt_sub <- oni_mlt[oni_mlt$Date %in% dates_wspan, ]
#   }
#   
#   dates_sub <- oni_mlt_sub$Date
#   ndvi_id <- which(ndvi_date %in% dates_sub)
#   rst_ndvi_sub <- rst_ndvi[[ndvi_id]]
#   mat_ndvi_sub <- as.matrix(rst_ndvi_sub)
#   
#   num_ndvi_sub_median <- apply(mat_ndvi_sub, 2, 
#                                function(...) median(..., na.rm = TRUE))
#   
#   oni_mlt_sub$NDVI <- num_ndvi_sub_median
#   oni_mlt_sub$Month <- as.numeric(substr(oni_mlt_sub$Date, 6, 7))

oni_mlt_sub <- lapply(seasons, function(i) extentEnsoSeason(i, span = span))
oni_mlt_sub <- do.call("rbind", oni_mlt_sub)

  sp <- smooth.spline(oni_mlt_sub$Month, oni_mlt_sub$NDVI, spar = .01)
  sp_pred <- predict(sp, seq(1, nlevels(oni_mlt_sub$Month), .01))
  
  mat_sp_pred <- do.call("cbind", sp_pred)
  df_sp_pred <- data.frame(group = group, mat_sp_pred)
#   df_sp_pred$x <- unique(oni_mlt_sub$Month)
  return(df_sp_pred)
}

red <- brewer.pal(4, "Reds")
blue <- brewer.pal(4, "Blues")

plot.colors <- c("black", blue[3], blue[4], red[3], red[4], "darkgreen")
names(plot.colors) <- groups

# extend ltm
# df_med_ndvi_ltm$x <- factor(df_med_ndvi_ltm$x)
ltm_ext <- merge(data.frame(x = 1:20), df_med_ndvi_ltm, by = "x", 
                 all = TRUE)
ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
# ltm_ext$x <- as.numeric(as.character(ltm_ext[, 1]))

# x-axis labels
lbl <- rep(c(7:12, 1:6, 7:12, 1:2))
names(lbl) <- 1:(12+span-1)

p_nina <- ggplot(aes(x, y, group = group, colour = group), data = ndvi_sp) + 
  geom_line() +
  geom_line(aes(x, y), data = ltm_ext, colour = "grey65", 
            linetype = 2) + 
  scale_colour_manual("", values = plot.colors) + 
#   scale_x_discrete("\nMonth", labels = lbl) + 
  scale_x_continuous("\nMonth", breaks = 1:(12+span-1), labels = lbl) + 
  labs(x = "\nMonth", y = expression(atop(NDVI[median], "\n"))) + 
  theme_bw()

png("vis/cor_ndvi_oni/ts_nina_ndvi.png", width = 30, height = 12, units = "cm", 
    pointsize = 18, res = 300)
print(p_nina)
dev.off()

# occurrence of each group
ssn_cnt_nina <- foreach(nina = groups_nina, iod = groups_iod, group = groups, 
                        span = rep(8, length(groups)), .combine = "rbind") %do% {
  oni_mlt_sub <- subset(oni_mlt, (Type %in% nina) & (IOD %in% iod))
  ssn_cnt <- length(unique(oni_mlt_sub$Season))
  df_ssn_cnt <- data.frame(Group = group, Count = ssn_cnt)
  return(df_ssn_cnt)
}
                     

## ccf

# remove low-variace areas (evergreen forest)
rst_ndvi_anom_rmf <- rst_ndvi_anom
rst_ndvi_anom_rmf[id_lvar] <- NA
mat_ndvi_anom_rmf <- as.matrix(rst_ndvi_anom_rmf)

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
  dat_ccf <- foreach(i = 1:nrow(mat_ndvi_anom_rmnp), .combine = "rbind") %dopar% {
    
    # pixel ts
    val <- mat_ndvi_anom_rmnp[i, ]

    # skip current iteration if pixel was previously masked 
    if (all(is.na(val))) {
      return(NA)
    }
    
    dat <- cbind(dat_oni_dmi[, id], val)
    dat <- na.omit(dat)
    
    cor_lag <- Find_Max_CCF(dat[, 1], dat[, 2], lag.max = 8)
    
    if (cor_lag$lag >= 0) {
      mod <- lm(dat[, 1] ~ lag(dat[, 2], cor_lag$lag))
    } else {
      mod <- lm(lag(dat[, 1], abs(cor_lag$lag)) ~ dat[, 2])
    }
    
    p <- summary(mod)$coefficients[2, 4]
    cor_lag_p <- cbind(cor_lag, p)
    
    return(cor_lag_p)
  }
  
  rst_ccf <- rst_lag <- rst_ndvi[[1]]
  rst_ccf[] <- dat_ccf[, 1]
  rst_lag[] <- dat_ccf[, 2]
  rst_ccf_lag <- stack(rst_ccf, rst_lag)
  
  rst_ccf_lag[dat_ccf$p >= .01] <- NA
  
  return(rst_ccf_lag)
}

reds <- colorRampPalette(brewer.pal(7, "OrRd"))
blues <- brewer.pal(7, "YlGnBu")
cols_div <- colorRampPalette(rev(brewer.pal(5, "PuOr")))

# dem contours
source("kiliContours.R")
p_dem <- kiliContours()

# oni
p_ndvi_oni_lag <- spplot(ls_ccf[[1]][[2]], col.regions = cols_div(100), at = -6.5:6.5, 
                         main = list("Lag (months)", cex = 1.5))
p_ndvi_oni_lag_dem <- p_ndvi_oni_lag + as.layer(p_dem)
p_ndvi_oni_lag_dem_env <- envinmrRasterPlot(p_ndvi_oni_lag_dem)
p_ndvi_oni_r <- spplot(ls_ccf[[1]][[1]], col.regions = reds(100), at = seq(.025, .525, .05))
p_ndvi_oni_r_dem <- p_ndvi_oni_r + as.layer(p_dem)
p_ndvi_oni_r_dem_env <- envinmrRasterPlot(p_ndvi_oni_r_dem)

# dmi
p_ndvi_dmi_lag <- spplot(ls_ccf[[2]][[2]], col.regions = cols_div(100), at = -6.5:6.5)
p_ndvi_dmi_lag_dem <- p_ndvi_dmi_lag + as.layer(p_dem)
p_ndvi_dmi_lag_dem_env <- envinmrRasterPlot(p_ndvi_dmi_lag_dem)
p_ndvi_dmi_r <- spplot(ls_ccf[[2]][[1]], col.regions = reds(100), at = seq(.025, .525, .05))
p_ndvi_dmi_r_dem <- p_ndvi_dmi_r + as.layer(p_dem)
p_ndvi_dmi_r_dem_env <- envinmrRasterPlot(p_ndvi_dmi_r_dem)

p_comb <- latticeCombineGrid(list(p_ndvi_oni_lag_dem_env, p_ndvi_dmi_lag_dem_env, 
                                  p_ndvi_oni_r_dem_env, p_ndvi_dmi_r_dem_env))

library(grid)

png("vis/cor_ndvi_oni/comb_ccf_lag.png", width = 30, height = 30, units = "cm", 
    pointsize = 18, res = 600)
plot.new()
print(p_comb)

downViewport(trellis.vpname(name = "figure"))
vp1 <- viewport(x = 0.5, y = -.05,
                height = 0.07, width = 1,
                just = c("centre", "top"),
                name = "key.vp")
pushViewport(vp1)
draw.colorkey(key = list(col = reds(100), width = 1, height = .5,
                         #                          at = -1:1, labels = c("-", "0", "+"), 
                         at = seq(.025, .525, .05), 
                         space = "bottom"), draw = TRUE)
grid.text("r", x = 0.5, y = -.05, just = c("centre", "top"), 
          gp = gpar(font = "bold", cex = 1.5))

dev.off()
