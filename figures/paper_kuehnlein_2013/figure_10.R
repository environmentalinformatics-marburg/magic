library(raster)
library(mapdata)
library(latticeExtra)
library(fields)

inpath <- "C:/tappelhans/uni/marburg/colleagues/meike/article/figure_processing/figure_10/new"

flist <- list.files(inpath, pattern = "rst", recursive = T)
flist <- flist[1:2]
#newnames <- tolower(flist)
#file.rename(paste(inpath, flist, sep = "/"), paste(inpath, newnames, sep = "/"))
#flist <- grep(".rst", flist)

yat <- seq(40, 70, 2.5)
ylabs <- paste(yat, "°N", sep = "")
xat <- seq(0, 100, 2.5)
xlabs <- ifelse(xat < 0, paste(xat, "°W", sep = ""), 
               ifelse(xat > 0, paste(xat, "°E", sep = ""), 
                      paste(xat, "°", sep = "")))

descr <- c("a)  COT SLALOM MODIS", "b)  COT MOD06", 
           "c)  VIS BAND 02")

ext <- extent(c(4, 17, 45.75, 56))
mm <- map('worldHires', plot = F, fill = T, col = "grey40")

lm <- raster(paste(inpath, "europe_landsea_mask.rst",
                   sep = "/"), native = T, crs = "+proj=latlong")
lm <- crop(lm, ext)
lmplot <- spplot(lm, mm = mm, maxpixels = 400000, col.regions = "grey50",
                 colorkey = F, panel = function(..., mm) {
                   panel.levelplot(...)
                   panel.polygon(mm$x, mm$y, col = "grey40", lwd = 0.8)
                   
                   })

vis <- raster(paste(inpath, "msg_200806280945_band02.rst",
                    sep = "/"), native = T, crs = "+proj=latlong")
vis <- crop(vis, ext)
newvals <- values(vis)
newvals <- ifelse(newvals == 0, NA, newvals)
values(vis) <- newvals

visp <- spplot(vis, maxpixels = 400000, 
               col.regions = colorRampPalette(c("black", "white")), 
               cuts = 200, panel = function(...) {
                 panel.levelplot(...)
                 panel.lines(mm$x, mm$y, col = "black", alpha = 1, lwd = 0.8)                 
                 }, scales = list(x = list(at = xat, labels = xlabs), 
                                y = list(at = yat, labels = ylabs)),
               colorkey = list(space = "top", width = 1, height = 0.75))

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
                at = seq(0, 100, 0.1), panel = function(...) {
                  panel.abline(h = yat, v = xat,
                               col = "grey80", lwd = 0.8, lty = 3)
                  panel.levelplot(...)
                }, scales = list(x = list(at = xat, labels = xlabs), 
                                 y = list(at = yat, labels = ylabs)),
                colorkey = list(space = "top", width = 1, height = 0.75,
                                at = seq(0, 100, 0.1)))
  #plot <- tau +
  #  as.layer(landseamask, under = T)  
  return(tau)
}
                   )


out <- gridlist[[1]]
for (i in 2:(length(flist)))
  out <- c(out, gridlist[[i]], x.same = T, y.same = T)

out <- c(out, visp, x.same = T, y.same = T) +
  as.layer(lmplot, under = T)

out <- update(out, layout = c(3, 1),
              strip = strip.custom(bg = "grey20", 
                                   factor.levels = descr,
                                   par.strip.text = list(
                                     col = "white", font = 2, cex = 0.8)))

png(paste(inpath, "figure_10.png", sep = "/"), res = 300, width = 1024*3, 
    height = 1024/2*3)
print(out)
dev.off()