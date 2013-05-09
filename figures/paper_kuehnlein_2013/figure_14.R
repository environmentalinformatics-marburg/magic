library(raster)
library(latticeExtra)
library(fields)

inpath <- "C:/tappelhans/uni/marburg/colleagues/meike/article/figure_processing/figure_14/new"
#flist <- list.files(inpath, pattern = "2", recursive = T)
#
#newnames <- tolower(flist)
#file.rename(paste(inpath, flist, sep = "/"), paste(inpath, newnames, sep = "/"))


aef75 <- raster(paste(inpath, "200806280945_py75_mask_tau_gt_05.rst", sep = "/"),
                native = T, crs = "+proj=latlong")
aef81 <- raster(paste(inpath, "200806280945_py81_mask_tau_gt_05.rst", sep = "/"),
                native = T, crs = "+proj=latlong")
tau72 <- raster(paste(inpath, "200806280945_py72_mask_tau_gt_05.rst", sep = "/"),
                native = T, crs = "+proj=latlong")
tau82 <- raster(paste(inpath, "200806280945_py82_mask_tau_gt_05.rst", sep = "/"),
                native = T, crs = "+proj=latlong")

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

aef75 <- crop(aef75, ext)
aef81 <- crop(aef81, ext)
tau72 <- crop(tau72, ext)
tau82 <- crop(tau82, ext)

diffaef <- (aef81-aef75)/((aef81+aef75)/2)*100
values(diffaef) <- ifelse(values(diffaef) < -100 | values(diffaef) > 100, 
                          NA, values(diffaef))
difftau <- (tau82-tau72)/((tau82+tau72)/2)*100
values(difftau) <- ifelse(values(difftau) < -100 | values(difftau) > 100, 
                          NA, values(difftau))

yat = seq(40, 70, 2.5)
ylabs = paste(yat, "°N", sep = "")
xat = seq(0, 100, 2.5)
xlabs = ifelse(xat < 0, paste(xat, "°W", sep = ""), 
               ifelse(xat > 0, paste(xat, "°E", sep = ""), 
                      paste(xat, "°", sep = "")))

descr <- c("a)  COT", "b)  AEF")

aef <- spplot(diffaef, maxpixels = 400000, 
              col.regions = colorRampPalette(c("darkblue", "aquamarine", 
                                               "white", "orange", "darkred")),
              at = seq(-100, 100, 0.1), panel = function(...) {
                  panel.abline(h = yat, v = xat,
                               col = "grey80", lwd = 0.8, lty = 3)
                  panel.levelplot(...)
                }, scales = list(x = list(at = xat, labels = xlabs), 
                                 y = list(at = yat, labels = ylabs)),
                colorkey = list(space = "top", width = 1, height = 0.75,
                                at = seq(-100, 100, 0.1)))

tau <- spplot(difftau, maxpixels = 400000, 
              col.regions = colorRampPalette(c("darkblue", "aquamarine", 
                                               "white", "orange", "darkred")),
              at = seq(-100, 100, 0.1), panel = function(...) {
                panel.abline(h = yat, v = xat,
                             col = "grey80", lwd = 0.8, lty = 3)
                panel.levelplot(...)
              }, scales = list(x = list(at = xat, labels = xlabs), 
                               y = list(at = yat, labels = ylabs)),
              colorkey = list(space = "top", width = 1, height = 0.75,
                              at = seq(-100, 100, 0.1)))

out <- c(tau, aef, x.same = T, y.same = T) +
  as.layer(lmplot, under = T)

#out <- c(out, visp, x.same = T, y.same = T)
out <- update(out, layout = c(2, 1),
              strip = strip.custom(bg = "grey20", 
                                   factor.levels = descr,
                                   par.strip.text = list(
                                     col = "white", font = 2, cex = 0.8)))

png(paste(inpath, "figure_14.png", sep = "/"), res = 300, width = 1024*3, 
    height = 768*3)
print(out)
dev.off()