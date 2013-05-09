
## LOAD LIBRARIES
library(raster)
library(latticeExtra)
library(fields)
library(grid)
library(maps) 
library(mapdata)

## DEFINE INPUT FILE PATH 
inpath <- "/media/PRECI/slalom_vergleich/sandbox/slalom_vs_mod06/validation/atlantiv_coefficients_feb/figures/figure_5"

## LIST ALL FILES IN INPUT FILE PATH AND SUBSET LIST TO FIRST 3 ONLY
flist <- list.files(inpath, pattern = "rst", recursive = T)
flist <- flist[1:2]

## CREATE LOWER CASE VERSION OF FILE LIST & RENAME ALL FILES TO LOWER CASE
#newnames <- tolower(flist) 
#file.rename(paste(inpath, flist, sep = "/"), paste(inpath, newnames, sep = "/"))

## USE ONLY FILES ENDING WITH .rst
#flist <- grep(".rst", flist)

## SPECIFY LOCATIONS AND NAMES FOR X AND Y AXIS TICK MARKS
yat = seq(32.5, 47.5, 2.5)
ylabs = paste(yat, "°N", sep = "")
xat = seq(-22.5, -12.5, 2.5)
xlabs = ifelse(xat < 0, paste(xat, "°W", sep = ""), 
               ifelse(xat > 0, paste(xat, "°E", sep = ""), 
                      paste(xat, "°", sep = "")))

## CREATE VECTOR FOR TEXT IN PANEL HEADERS
descr <- c("a)  COT M06", "b)  COT SLALOM SEVIRI")

## CREATE EXTENT OBJECT (FOR CROPPING)
ext <- extent(c(-25, -10, 30, 50))

## READ HI RESOLUTION WORLD MAP BUT DON'T PLOT
mm <- map('worldHires', plot = FALSE)

## CREATE RASTER LAYER FROM FILE, CROP ACCORDING TO EXTENT AND CREATE PLOT
# lm <- raster(paste(inpath, "europe_landsea_mask.rst",
#                    sep = "/"), native = T, crs = "+proj=latlong")
# lm <- crop(lm, ext)
# lmplot <- spplot(lm, mm = mm, maxpixels = 400000, col.regions = "grey40",
#                  colorkey = F, panel = function(..., mm) {
#                    panel.levelplot(...)
#                    panel.lines(mm$x, mm$y, col = "grey90", lwd = 0.8)
#                  })

## SEE ABOVE
cls <- raster(paste(inpath, "x200806111415_CLOUDSAT_TRACK.rst",
                    sep = "/"), native = T, crs = "+proj=latlong")
cls <- crop(cls, ext)
newvals <- values(cls)
newvals <- ifelse(newvals == 0, NA, newvals)
values(cls) <- newvals

clsplot <- spplot(cls, maxpixels = 400000, col.regions = "black",
                  colorkey = F)

## SEE ABOVE
#vis <- raster(paste(inpath, "msg_200806111415_band002_0_08.rst",
#                    sep = "/"), native = T, crs = "+proj=latlong")
#vis <- crop(vis, ext)
#newvals <- values(vis)
#newvals <- ifelse(newvals == 0, NA, newvals)
#values(vis) <- newvals

#visp <- spplot(vis, maxpixels = 400000,
#               col.regions = colorRampPalette(c("black", "white")), 
#               cuts = 200, panel = function(...) {
#                 grid.rect(gp=gpar(col=NA, fill="grey50"))
#                 panel.levelplot(...)
#                 #panel.abline(h = yat, v = xat,
#                 #              col = "grey70", lwd = 0.8, lty = 3)                 
#                 }, scales = list(x = list(at = xat, labels = xlabs), 
#                                y = list(at = yat, labels = ylabs)),
#               colorkey = list(space = "top", width = 1, height = 0.75))

## CREAT MULTIPLE RASTER LAYERS FROM FILES IN FILE LIST, CROP AND CREATE 
## PLOT OBJECT (STORED AS A LIST --> GRIDLIST)
gridlist <- lapply(seq(flist), function(i) { 
  datr <- raster(paste(inpath, flist[i], sep = "/"),
                 native = T, crs = "+proj=latlong")
  datr <- crop(datr, ext)
  #newproj <- "+proj=lcc +lat_1=30 +lat_2=60"
  #datr <- projectRaster(datr, crs=newproj)
  newvals <- values(datr)
  #newvals <- ifelse(newvals > 60, NA, newvals)
  newvals <- ifelse(newvals == 0, NA, newvals)
  values(datr) <- newvals
  
  tau <- spplot(datr, maxpixels = 400000, col.regions = tim.colors(1000), 
                at = seq(0, 40, 0.1), panel = function(...) {
                  grid.rect(gp=gpar(col=NA, fill="grey50"))
                  panel.abline(h = yat, v = xat,
                               col = "grey80", lwd = 0.8, lty = 3)
                  panel.levelplot(...)
                }, scales = list(x = list(at = xat, labels = xlabs), 
                                 y = list(at = yat, labels = ylabs)),
                colorkey = list(space = "top", width = 1, height = 0.75,
                                at = seq(0, 40, 0.1)))
  #plot <- tau +
  #  as.layer(landseamask, under = T)  
  return(tau)
}
                   )

## COMBINE ALL PLOT ELEMENTS FROM GRIDLIST INTO ONE
out <- gridlist[[1]]
for (i in 2:(length(flist)))
  out <- c(out, gridlist[[i]], x.same = T, y.same = T)

## ADDITIONALLY COMBINE VIS PLOT AND OVERLAY CLS AS LAYER
out <- c(out, x.same = T, y.same = T) +
  as.layer(clsplot) 

## ADJUST PLOT SETTINGS AND USE STRIP LABELLING DEFINED EARLIER (DESCR)
out <- update(out, 
              strip = strip.custom(bg = "grey20", 
                                   factor.levels = descr,
                                   par.strip.text = list(
                                     col = "white", font = 2, cex = 0.8)))

## PLOT TO PNG WITH A RESOLUTION OF 300 PXLS PER INCH
#png(paste(inpath, "figure_01.png", sep = "/"), res = 300, width = 768*3, 
#    height = 1024*3)
png(paste(inpath, "figure_05_2.png", sep = "/"), res = 300, width = 1024*3, 
    height = 768*3)
print(out)
dev.off()