### chirps vs. gsod -----

library(GSODTools)
# dat <- getGSOD("634740", dsn = "../../programming/r/GSODTools/data", 
#                unzip = TRUE, rm_gz = TRUE)

df <- read.fwf("../../data/bale/precip/CDO5696887341688.txt", 
               widths = gsodColWidth(), header = FALSE, skip = 1, 
               fill = TRUE, na.strings = c("999.9", "9999.9", "99.99"),
               stringsAsFactors = FALSE)

sbs <- df[, c(5, 41)]
sbs <- sbs[complete.cases(sbs), ]

sbs$V5 <- as.Date(as.character(sbs$V5), format = "%Y%m%d")
tb1 <- table(strftime(sbs$V5, format = "%Y%m"))

dys <- seq(as.Date("1963-01-01"), Sys.Date(), "day")
mts <- strftime(dys, format = "%Y%m")
vld <- unique(mts)[which(unique(mts) %in% unique(strftime(sbs$V5, format = "%Y%m")))]
dys <- dys[mts %in% vld]
tb2 <- table(strftime(dys, format = "%Y%m"))

nms <- names(which((tb1 / tb2) >= 2/3))
ids <- gsub("\\.", "", substr(basename(tfs), 13, 19)) %in% nms
tmp <- crp[[which(ids)]]

ids_gsd <- nms %in% gsub("\\.", "", substr(basename(tfs), 13, 19))
sbs2 <- sbs[strftime(sbs$V5, format = "%Y%m") %in% nms[ids_gsd], ]

sbs2$month <- strftime(sbs2$V5, format = "%Y%m")
sbs2 %>%
  group_by(month) %>%
  summarise(GSOD = inch2Millimeter(sum(V41))) -> out

crd <- subset(gsodstations, USAF == "634740")
coordinates(crd) <- ~ LON + LAT
proj4string(crd) <- "+init=epsg:4326"

cll <- cellFromXY(ltm, crd)
val_cps <- as.numeric(tmp[cll])

library(latticeExtra)
p <- xyplot(val_cps ~ out$GSOD, aspect = 1,
       main = list("In situ vs. remotely sensed monthly rainfall at Robe, Ethiopia", cex = .9, vjust = 2),
       xlab = "In situ (GSOD)", ylab = "Remotely sensed (CHIRPS)", 
       panel = function(x, y, ...) {
         panel.xyplot(x, y, pch = 20, cex = 1, col = "grey75", ...)
         panel.abline(coef = c(0, 1), lwd = 1.5, lty = 2)
         panel.ablineq(lm(y ~ x), r.squared = TRUE, rotate = FALSE, lwd = 1.5,
                       pos = 3, x = 120, y = 2, col.line = "red")
       })

setEPS()
postscript("vis/chirps_vs_gsod.eps", width = 12 * .3937, height = 12 * .3937, 
           fonts = "serif")
print(p)
dev.off()


### trmm vs. gsod -----

library(raster)
# trm <- stack("../../data/bale/precip/3B42_Daily.tif")
# dts <- readRDS("../../data/bale/precip/3B42_Daily_Dates.rds")
# 
# mts <- sapply(strsplit(dts, "\\."), "[[", 2)
# mts <- as.Date(mts, format = "%Y%m%d")
# mts <- format(mts, "%Y%m")
# agg <- stackApply(trm, mts, fun = sum)

trm_agg <- stack("../../data/bale/precip/3B42_Monthly.tif")

dts_agg <- seq(as.Date("1998-01-01"), as.Date("2017-02-01"), "month")
dts_agg <- format(dts_agg, "%Y%m")
trm_ids <- dts_agg %in% nms
trm_tmp <- trm_agg[[which(trm_ids)]]

ids_gsd <- nms %in% dts_agg
sbs2 <- sbs[strftime(sbs$V5, format = "%Y%m") %in% nms[ids_gsd], ]

sbs2$month <- strftime(sbs2$V5, format = "%Y%m")
sbs2 %>%
  group_by(month) %>%
  summarise(GSOD = inch2Millimeter(sum(V41))) -> out

crd <- subset(gsodstations, USAF == "634740")
coordinates(crd) <- ~ LON + LAT
proj4string(crd) <- "+init=epsg:4326"

trm_cll <- cellFromXY(trm_agg, crd)
trm_val <- as.numeric(trm_tmp[trm_cll])

xyplot(trm_val ~ out$GSOD, aspect = 1,
       main = list("In situ vs. remotely sensed monthly rainfall at Robe, Ethiopia", cex = .9, vjust = 2),
       xlab = "In situ (GSOD)", ylab = "Remotely sensed (TRMM)", 
       panel = function(x, y, ...) {
         panel.xyplot(x, y, pch = 20, cex = 1, col = "grey75", ...)
         panel.abline(coef = c(0, 1), lwd = 1.5, lty = 2)
         panel.ablineq(lm(y ~ x), r.squared = TRUE, rotate = FALSE, lwd = 1.5,
                       pos = 3, x = 120, y = 2, col.line = "red")
       })
