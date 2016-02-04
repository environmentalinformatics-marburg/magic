mstr <- readOGR(dsn = dirpath, layer = "PlotPoles_ARC1960_mod_20140807_final")
mstr <- subset(mstr, PoleType == "AMP")
head(mstr)

# ta/rh
mstr$Ta_200 <- "UNINSTALLED"
plt_ta <- c(paste0("sav", 0:5), paste0("mai", c(0, 2:5)), 
            paste0("gra", c(1:2, 4:6)), paste0("cof", c(1:6)), 
            paste0("hom", 1:5), paste0("flm", c(1:4, 6)), 
            paste0("foc", 1:6), paste0("fod", 1:5), 
            paste0("fpo", 0:5), paste0("fpd", 1:5), 
            paste0("fer", 0:4), paste0("fed", 1:5), 
            paste0("hel", 1:5), "mch0")
mstr$Ta_200[mstr$PlotID %in% plt_ta] <- "INSTALLED"

mstr$P_RT_NRT <- "UNINSTALLED"
plt_prcp <- c("cof3", "cof5", "emg0", "fer0", "foc6", "fod2", "fod3", "fpd5", 
              "gra1", "gra5", "hel1", "hom4", "mai0", "mai3", "mcg0", "mch0", "mwh0", 
              "sav0")
mstr$P_RT_NRT[mstr$PlotID %in% plt_prcp] <- "INSTALLED"

mstr$SWDR_300 <- "UNINSTALLED"
plt_swdr <- c("cof3", "fer0", "foc6", "fod2", "fpo1", "fpo2", "hom4", "mch0")
mstr$SWDR_300[mstr$PlotID %in% plt_swdr] <- "INSTALLED"

# through-fall
mstr$TF <- "UNINSTALLED"
plt_tf <- c("sav5", "hom4", "flm1", "foc6", "foc0", "fpo0", "fpd0", "fer0")
mstr$TF[mstr$PlotID %in% plt_tf] <- "INSTALLED"

# fog
mstr$F_RT_NRT <- "UNINSTALLED"
plt_fg <- c("nkw1", "flm1", "foc6", "foc0", "fpo0", "fpd0", "fer0")
mstr$F_RT_NRT[mstr$PlotID %in% plt_fg] <- "INSTALLED"

# aws
mstr$p_200 <- "UNINSTALLED"
plt_aws <- c("sav0", "mai0", "gra1", "cof3", "hel1", "foc0", "fpo0", "mwh0")
mstr$p_200[mstr$PlotID %in% plt_aws] <- "INSTALLED"


library(dplyr)
mstr@data %>%
  filter(p_200 == "INSTALLED")

writeOGR(subset(mstr, p_200 == "INSTALLED"), dsn = "../../../xchange/chris/", 
         layer = "wind_sensor_locations", driver = "ESRI Shapefile")
head(mstr)

# output storage
ch_fls_out <- paste0("ki_station_master_", format(Sys.Date(), "%Y%m%d"))
writeOGR(mstr, dsn = "/media/permanent/kilimanjaro/coordinates/coords/", 
         layer = ch_fls_out, driver = "ESRI Shapefile", overwrite_layer = TRUE)
