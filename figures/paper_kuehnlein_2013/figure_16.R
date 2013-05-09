library(raster)
library(latticeExtra)
library(fields)
library(mapdata)

inpath <- "C:/tappelhans/uni/marburg/colleagues/meike/article/figure_processing/figure_16"

flist <- list.files(inpath, pattern = "rst", recursive = T, ignore.case = T)
flist <- flist[1:6]
clslist <- list.files(inpath, pattern = "rst", recursive = T, ignore.case = T)
clslist <- clslist[8:13]
#newnames <- tolower(flist)
#file.rename(paste(inpath, flist, sep = "/"), paste(inpath, newnames, sep = "/"))
#flist <- grep(".rst", flist)

yat = seq(40, 60, 10)
ylabs = paste(yat, "°N", sep = "")
xat = seq(-10, 30, 10)
xlabs = ifelse(xat < 0, paste(xat, "°W", sep = ""), 
               ifelse(xat > 0, paste(xat, "°E", sep = ""), 
                      paste(xat, "°", sep = "")))

descr <- c("a) 2008-06-13 12:45:00", "b) 2008-06-25 13:00:00", 
           "c) 2008-06-27 12:45:00", "d) 2008-07-06 12:45:00", 
           "e) 2008-07-11 13:00:00", "f) 2008-07-13 12:45:00")

#ext <- extent(c(4, 17, 45.75, 56))
mm <- map('worldHires', plot = F, fill = T, col = "grey40")

lm <- raster(paste(inpath, "europe_landsea_mask.rst",
                   sep = "/"), native = T, crs = "+proj=latlong")
#lm <- crop(lm, ext)
lmplot <- spplot(lm, mm = mm, maxpixels = 400000, col.regions = "grey50",
                 colorkey = F, panel = function(..., mm) {
                   panel.levelplot(...)
                   panel.polygon(mm$x, mm$y, col = "grey40", lwd = 0.8)
                 })

#lm <- raster(paste(inpath, "000000000000_00000_ml04clnb1_na001_1000_rg01ei_003000.rst",
#                    sep = "/"), native = T, crs = "+proj=latlong")
#lm <- crop(lm, ext)
#newvals <- values(cls)
#newvals <- ifelse(newvals == 0, NA, newvals)
#values(cls) <- newvals

#lmplot <- spplot(lm, maxpixels = 400000, col.regions = "grey",
#                  colorkey = F)

#vis <- raster(paste(inpath, "msg_200806280945_band02.rst",
#                    sep = "/"), native = T, crs = "+proj=latlong")
#vis <- crop(vis, ext)
#newvals <- values(vis)
#newvals <- ifelse(newvals == 0, NA, newvals)
#values(vis) <- newvals

#visp <- spplot(vis, maxpixels = 400000, 
#               col.regions = colorRampPalette(c("grey10", "white")), 
#               cuts = 200, panel = function(...) {
#                 panel.levelplot(...)
#                 #panel.abline(h = yat, v = xat,
                  #            col = "grey70", lwd = 0.5, lty = 2)
                 
#                 }, scales = list(x = list(at = xat, labels = xlabs), 
#                                y = list(at = yat, labels = ylabs)),
#               colorkey = list(space = "top", width = 1, height = 0.75))

gridlist <- lapply(seq(flist), function(i) { 
  datr <- raster(paste(inpath, flist[i], sep = "/"),
                 native = T, crs = "+proj=latlong")
  clsr <- raster(paste(inpath, clslist[i], sep = "/"),
                 native = T, crs = "+proj=latlong")
  #datr <- crop(datr, ext)
  #newproj <- "+proj=lcc +lat_1=30 +lat_2=60"
  #datr <- projectRaster(datr, crs=newproj)
  newvals <- values(datr)
  #newvals <- ifelse(newvals > 60, NA, newvals)
  newvals <- ifelse(newvals == 0, NA, newvals)
  values(datr) <- newvals
  newvals <- values(clsr)
  newvals <- ifelse(newvals == 0, NA, newvals)
  values(clsr) <- newvals
  
  
  tau <- spplot(datr, maxpixels = 400000, col.regions = tim.colors(1000), 
                at = seq(0, 80, 0.1), panel = function(...) {
                  panel.abline(h = yat, v = xat,
                               col = "grey80", lwd = 0.8, lty = 3)
                  panel.levelplot(...)
                }, scales = list(x = list(at = xat, labels = xlabs), 
                                 y = list(at = yat, labels = ylabs)),
                colorkey = list(space = "top", width = 1, height = 0.75,
                                at = seq(0, 80, 0.1)))
  
  cls <- spplot(clsr, maxpixels = 400000, col.regions = "black",
                colorkey = F)
  #plot <- tau +
  #  as.layer(landseamask, under = T)  
  return(tau + as.layer(cls))
}
                   )


out <- gridlist[[1]]
for (i in 2:(length(flist)))
  out <- c(out, gridlist[[i]], x.same = T, y.same = T)

out <- out +
  as.layer(lmplot, under = T)

out <- update(out, layout = c(2, 3),
              strip = strip.custom(bg = "grey20", 
                                   factor.levels = descr,
                                   par.strip.text = list(
                                     col = "white", font = 2, cex = 0.8)))

png(paste(inpath, "figure_16.png", sep = "/"), res = 300, width = 1024*3, 
    height = 1024*3)
print(out)
dev.off()