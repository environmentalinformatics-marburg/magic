library(raster)
library(latticeExtra)
library(fields)
library(grid)

inpath <- "C:/tappelhans/uni/marburg/colleagues/meike/article/figure_processing/figure_02"

flist <- list.files(inpath, pattern = "rst", recursive = T, ignore.case = T)
flist <- flist[1:3]
#newnames <- tolower(flist)
#file.rename(paste(inpath, flist, sep = "/"), paste(inpath, newnames, sep = "/"))
#flist <- grep(".rst", flist)

yat = seq(32.5, 47.5, 2.5)
ylabs = paste(yat, "°N", sep = "")
xat = seq(-22.5, -12.5, 2.5)
xlabs = ifelse(xat < 0, paste(xat, "°W", sep = ""), 
               ifelse(xat > 0, paste(xat, "°E", sep = ""), 
                      paste(xat, "°", sep = "")))

descr <- c("a)  AEF SLALOM MODIS", "b)  AEF MYD06", 
           "c)  AEF SLALOM SEVIRI")

ext <- extent(c(-25, -10, 30, 50))

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
                at = seq(0, 30, 0.1), panel = function(...) {
                  grid.rect(gp=gpar(col=NA, fill="grey50"))
                  panel.abline(h = yat, v = xat,
                               col = "grey80", lwd = 0.8, lty = 3)
                  panel.levelplot(...)
                }, scales = list(x = list(at = xat, labels = xlabs), 
                                 y = list(at = yat, labels = ylabs)),
                colorkey = list(space = "top", width = 1, height = 0.75,
                                at = seq(0, 30, 0.1)))
  #plot <- tau +
  #  as.layer(landseamask, under = T)  
  return(tau)
}
                   )

# vis <- raster(paste(inpath, "MSG_200806111415_BAND002_0_08_MASK_TAU_GT_05.RST",
#                     sep = "/"), native = T, crs = "+proj=latlong")
# vis <- crop(vis, ext)
# newvals <- values(vis)
# newvals <- ifelse(newvals == 0, NA, newvals)
# values(vis) <- newvals
# 
# visp <- spplot(vis, maxpixels = 400000, col.regions = colorRampPalette(c("black", "white")), 
#                cuts = 200, panel = function(...) {
#                  panel.abline(h = yat, v = xat,
#                               col = "grey30", lwd = 0.5)
#                  panel.levelplot(...)
#                }, scales = list(x = list(at = xat, labels = xlabs), 
#                                 y = list(at = yat, labels = ylabs)),
#                colorkey = list(space = "top", width = 1, height = 0.75))

out <- gridlist[[1]]
for (i in 2:(length(flist)))
  out <- c(out, gridlist[[i]], x.same = T, y.same = T)

#out <- c(out, visp, x.same = T, y.same = T)
out <- update(out, layout = c(3, 1),
              strip = strip.custom(bg = "grey20", 
                                   factor.levels = descr,
                                   par.strip.text = list(
                                     col = "white", font = 2, cex = 0.8)))

png(paste(inpath, "figure_02.png", sep = "/"), res = 300, width = 1024*3, 
    height = 768*3)
print(out)
dev.off()