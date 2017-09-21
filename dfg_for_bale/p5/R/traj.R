### environment -----

## workspace clearance
rm(list = ls(all = TRUE)); closeAllConnections()

## packages
lib = c("opentraj", "doParallel", "reshape2", "Rsenal", "grid", "latticeExtra")
jnk = sapply(lib, function(x) library(x, character.only = TRUE))

## parallelization
cl <- makeCluster(.75 * detectCores())
registerDoParallel(cl)


### processing -----

# ## year and elevation
# kYear <- 2013
# kHeight <- 3000

## path to meteorological reanalysis data
rsv <- "/media/sd19006/data/users/fdetsch/R-Server" 
hsp = file.path(rsv, "data/bale/HYSPLIT")

KMetFiles <- file.path(hsp, "ncep/")
KOutFiles <- file.path(hsp, "results/")

## hysplit installation path
KHySplitPath <- file.path(rsv, "apps/hysplit-886/")

## load and reformat point file
dat <- read.csv(file.path(hsp, "p1/Master data sheet for Climate Station Data.csv"), 
                skip = 3L, header = FALSE, stringsAsFactors = FALSE)
nms <- read.csv(file.path(hsp, "p1/Master data sheet for Climate Station Data.csv"), 
                skip = 2L, nrows = 1L, header = FALSE, stringsAsFactors = FALSE)
nms[grep("Longitude", nms)] <- "Longitude"
nms[1, 8:ncol(nms)] <- gsub("\\.", "/", nms[1, 8:ncol(nms)])
names(dat) <- nms

mlt <- melt(dat, id.vars = 1:7, variable.name = "date", value.name = "prcp")
mlt$date <- as.Date(mlt$date, "%d/%m/%Y")

## auxilliary plot elements
rgb <- brick(file.path(hsp, "rgb.tif"))

coordinates(dat) <- ~ Longitude + Latitude 
proj4string(dat) <- "+init=epsg:4326"

## loop over weather stations
iso <- lapply(dat@data[, "Station Code"], function(h) {
  sbs <- subset(mlt, mlt[, "Station Code"] == h)
  sbs <- sbs[complete.cases(sbs), ]

  stp <- sbs$`Date of Rain Collectors Installed`[1]
  stp <- as.Date(stp, "%d/%m/%Y")

  msr <- sbs$date
  
  # coordinates
  lat <- sbs$Latitude[1]; lon <- sbs$Longitude[1]
  
  lst <- foreach(i = 1:nrow(sbs), .packages = lib) %dopar% {
      
      dts <- if (i == 1) {
        seq(stp, msr[i], "day")
      } else {
        seq(msr[i-1] + 1, msr[i], "day")
      }
      lbl <- paste(format(dts[1], "%m/%d/%Y"), "to", 
                   format(dts[length(dts)], "%m/%d/%Y"))
      
      ofl <- paste("iso", h, formatC(i-1, width = 2, flag = "0"), "", sep = "_")
      
      trj <- ProcTraj(lat = lat, lon = lon, name = ofl,
                      hour.interval = 1,#96
                      met = KMetFiles, out = KOutFiles,
                      hours = -24, height = 3000L, hy.path = KHySplitPath, ID = i, #96
                      dates = dts,
                      start.hour = "00:00", end.hour = "00:00") # 24:00

      sln <- Df2SpLines(trj, crs = "+init=epsg:4326")
      
      spplot(sln, scales = list(draw = TRUE, cex = .7), 
             xlim = c(35, 50), ylim = c(2, 14),
             colorkey = FALSE, col.regions = "black", lwd = 2, 
             sp.layout = list(rgb2spLayout(rgb, alpha = .5))) + 
        layer(sp.points(spt[spt$`Station Code` == h, ], col = "black", pch = 24, 
                        cex = 1.2, fill = "white"), data = list(spt = spt)) + 
        layer(sp.text(c(42.5, 2.5), lbl, font = 1, cex = .7), 
              data = list(lbl = lbl))
  }
  
  img <- suppressWarnings(latticeCombineGrid(lst, layout = c(1, 3)))
  ofl <- paste0(rsv, "/data/bale/HYSPLIT/results/vis/iso_", h, ".png")
  
  png(ofl, width = 10, height = 15, units = "cm", res = 500)
  grid.newpage()
  print(img, newpage = FALSE)
  dev.off()
})
  
# ## determine HYSPLIT frequency
# raster.lines <- RasterizeTraj(air.traj.lines, resolution = 10000, reduce = TRUE, parallel = FALSE)
# 
# r.max.value <- maxValue(raster.lines)
# v <- getValues(raster.lines)
# v <- v/r.max.value
# r <- setValues(spGridDF, v)
# 
# r1 <- as(r, "SpatialGridDataFrame")
# 
# spGridFreq <- PlotTrajFreq(r1, background = T, overlay = NA,
#                            overlay.color = "white", pdf = FALSE, file.name = "output")

## close parallel backend
stopCluster(cl)