library(Reot)
#library(ggplot2)
library(reshape)
library(grid)
library(colorspace)
#library(kza)
library(foreach)

tmp.path <- "/media/HDEXTENSION/raster_tmp/"
rasterOptions(tmpdir = tmp.path)

path.local <- "/media/tims_ex/reot_ndvi_dwnsc"

setwd(path.local)

plot <- FALSE
write.rasters <- TRUE

### start processing
load("gimmsKiliNDVI.RData")
load("modisKiliNDVI.RData")
#modisKiliNDVI <- modisKiliNDVI / 10000
#modisKiliNDVI <- modisKiliNDVI / 10000
#modisKiliNDVI[is.na(modisKiliNDVI)] <- -9999
#data(modisKiliNDVI)
#data(gimmsKiliNDVI)
#gimmsKiliNDVI <- gimmsNDVI

### split sets into prediction and validation sets
set.seed(12454)
# pred.ind <- sort(sample.int(nlayers(modisNDVI), 36))
# eval.ind <- seq(nlayers(modisNDVI))[-pred.ind]
# 
# mod.stck.pred <- modisNDVI[[pred.ind]]
# mod.stck.eval <- modisNDVI[[eval.ind]]
# gimms.stck.pred <- gimmsNDVI[[pred.ind]]
# gimms.stck.eval <- gimmsNDVI[[eval.ind]]

layer <-  sample(c(2,3), nlayers(modisKiliNDVI), replace = TRUE)
month <- sort(sample(12, 12, replace = FALSE))

pred.ind1 <- 1:24 #(layer * 12 + month)[1:12]

mod.stck.pred <- modisKiliNDVI[[pred.ind1]]
mod.stck.eval <- modisKiliNDVI[[-pred.ind1]]
gimms.stck.pred <- gimmsKiliNDVI[[pred.ind1]]
gimms.stck.eval <- gimmsKiliNDVI[[-pred.ind1]]

### calculate EOT
modes <- eot(pred = gimms.stck.pred, resp = mod.stck.pred, n = 10, 
             standardised = FALSE, reduce.both = FALSE, 
             print.console = TRUE)

nmodes <- nEot4Var(modes, 0.95)

### evaluate prediction
#ts.mode.eval <- gimms.stck.eval[mode[[1]][[2]]$max.xy]
ts.mode.eval <- sapply(seq(nmodes), function(i) {
  gimms.stck.eval[modes[[i]]$max.xy]
})

# mod.predicted <- stack(lapply(seq(nlayers(mod.stck.eval)), function(i) {
#   mode[[1]][[2]]$int.response + mode[[1]][[2]]$slp.response * ts.mode.eval[i]
# }))
mod.predicted.stck <- lapply(seq(nlayers(mod.stck.eval)), function(i) {
  stack(lapply(seq(ncol(ts.mode.eval)), function(k) {
    modes[[k]]$int.response + modes[[k]]$slp.response * ts.mode.eval[i, k]
  }))
})

mod.predicted <- stack(lapply(seq(nrow(ts.mode.eval)), function(i) {
  calc(mod.predicted.stck[[i]], fun = sum)
}))

mod.observed <- mod.stck.eval

pred.vals <- getValues(mod.predicted)
obs.vals <- getValues(mod.observed)

### error scores
ME <- colMeans(pred.vals - obs.vals, na.rm = TRUE)
MAE <- colMeans(abs(pred.vals - obs.vals), na.rm = TRUE)
RMSE <- sqrt(colMeans((pred.vals - obs.vals)^2, na.rm = TRUE))
R <- diag(cor(pred.vals, obs.vals, use = "complete.obs"))
Rsq <- R * R


### visualise error scores
scores <- data.frame(ME, MAE, RMSE, R, Rsq)
melt.scores <- melt(scores)

if (plot) {
  # boxplots
  library(ggplot2)
  png(paste("scores_boxplots", Sys.Date(), "png", sep = "."), 
      width = 10, height = 6, units = "cm", res = 600)
  p <- ggplot(melt.scores, aes(factor(variable), value)) 
  p <- p + geom_boxplot() + 
    theme_bw() + xlab("") + ylab("")
  print(p)
  dev.off()
}
  
if (plot) {
# scatter plots

# lattice-way
  lattice.plots <- lapply(seq(ncol(pred.vals)), function(i) {
    
    panel.name <- strsplit(names(mod.stck.eval)[i], "_")[[1]][4]
    
    eval.dat <- data.frame(pred = obs.vals[, i], resp = pred.vals[, i])
    scatter.lattice <- xyplot(resp ~ pred, aspect = 1,
                              ylim = c(-0.2, 1), xlim = c(-0.2, 1),
                              data = eval.dat, ylab = "Predicted", 
                              xlab = "Observed",
                              panel = function(x, y, ...) {
                                panel.smoothScatter(x, y, nbin = 500, 
                                                    raster = TRUE, ...)
                                lm1 <- lm(y ~ x)
                                lm1sum <- summary(lm1)
                                r2 <- lm1sum$adj.r.squared
                                panel.text(labels = 
                                             bquote(italic(R)^2 == 
                                                      .(format(r2, 
                                                               digits = 3))),
                                           x = 0.75, y = -0.1, cex = 0.7)
                                panel.text(labels = panel.name,
                                           x = 0.75, y = 0.05, cex = 0.7)
                                panel.smoother(x, y, method = "lm", 
                                               col = "black", 
                                               col.se = "black",
                                               alpha.se = 0.3, ...)
                                panel.abline(a = 0, b = 1, 
                                             col = "grey20", lty = 2, ...)
                              },
                              xscale.components = xscale.components.subticks,
                              yscale.components = yscale.components.subticks,
                              as.table = TRUE)
    
    return(scatter.lattice)
    
  })
  
  outLayout <- function(x, y) {
    update(c(x, y, 
             layout = c(4, length(lattice.plots)/4)), 
           between = list(y = 0.3, x = 0.3))
  }
  
  out <- Reduce(outLayout, lattice.plots)
  
  png(paste("scatter_eot", Sys.Date(), "png", sep = "."), 
      width = 19, height = 27, units = "cm", res = 300)
  print(out)
  dev.off()
}

### TODO: calculate residuals using raster calc example on stck!!!!!!!!!

### points of worst fit
clrs.hcl <- function(n) {
  hcl(h = seq(230, 0, length.out = n), 
      c = 60, l = 70, fixup = TRUE)
}

clrs.ndvi <- colorRampPalette(brewer.pal(11, "BrBG"))
#clrs.resids <- colorRampPalette(brewer.pal(9, "PuOr"))
clrs.resids <- colorRampPalette(c(clrs.hcl(2)[2], 
                                  "grey10",
                                  clrs.hcl(2)[1]))

plots <- read.table("kili_plots_64_sub.csv", header = TRUE, sep = ",",
                    stringsAsFactors = FALSE)
plots <- subset(plots, Valid == "Y")
plots$Valid <- as.factor(plots$Valid)
coordinates(plots) <- c("POINT_X", "POINT_Y")

if (plot) {
  ### absolute deviances betweemn observed and predicted NDVI
  plotResid <- function(pred.rst,
                        resp.rst,
                        bg = NULL,
                        txt = "",
                        #what = c("lower", "upper"),  
                        n = 5000) {
    
    if (is.null(bg)) bg <- resp.rst
    
    lm1 <- resp.rst - pred.rst
    
    #resids.sq <- sort(values(lm1)^2, na.last = FALSE)
    #lowest <- resids[1:n]
    #highest.sq <- 0.01 #resids.sq[(length(resids.sq) - (n - 1))]
    #highest <- values(lm1)[which(values(lm1)^2 > highest.sq)]
    highest.pix <- pred.rst
    highest.pix[] <- NA
    highest.pix[which(values(lm1) > 0.1)] <- lm1[which(values(lm1) > 0.1)]
    #resids.sq <- sort(values(lm1)^2, na.last = TRUE)
    #lowest.sq <- 0.01 #resids.sq[n]
    #lowest <- values(lm1)[which(values(lm1)^2 <= lowest.sq)]
    lowest.pix <- pred.rst
    lowest.pix[] <- NA
    lowest.pix[which(values(lm1) < -0.1)] <- lm1[which(values(lm1) < -0.1)]
    
    lev <- spplot(bg, col.regions = clrs.ndvi(1200), #rev(terrain.colors(1200)),
                  at = seq(-0.1, 1, 0.01), as.table = TRUE, 
                  main = "Predicted NDVI",
                  colorkey = list(space = "top", width = 1, height = 0.75))
    lowest.lev <- spplot(lowest.pix, col.regions = clrs.resids(1200),
                         at = seq(-1, 1, 0.01), 
                         colorkey = FALSE, as.table = TRUE)
    highest.lev <- spplot(highest.pix, col.regions = clrs.resids(1200),
                          at = seq(-1, 1, 0.01), 
                          colorkey = FALSE, as.table = TRUE,
                          panel = function(...) {
                            panel.levelplot(...)
                            panel.text(labels = txt, col = "grey40",
                                       x = 37.6, y = -2.86, cex = 0.7)})
    res.lev <- spplot(lm1, col.regions = "transparent",
                      at = seq(-0.1, 0.1, 0.01), as.table = TRUE)
    plots.p <- spplot(plots["Valid"], pch = 22, cex = 0.5,
                      col.regions = "white", edge.col = "black")
    
    
    
    #out <- lev + as.layer(lowest.lev) + as.layer(highest.lev)
    out <- lev + as.layer(lowest.lev) + as.layer(highest.lev) + as.layer(plots.p)
    
    return(out)
    
  }
  
  
  resid.plot <- lapply(seq(ncol(pred.vals)), function(i) {
    
    panel.name <- strsplit(names(mod.stck.eval)[i], "_")[[1]][4]
    
    plotResid(pred.rst = mod.observed[[i]],
              resp.rst = mod.predicted[[i]],
              bg = NULL,
              txt = panel.name,
              n = 5000) 
  })
  
  outLayout <- function(x, y) {
    update(c(x, y, 
             layout = c(4, length(resid.plot)/4)), 
           between = list(y = 0.3, x = 0.3))
  }
  
  out.res <- Reduce(outLayout, resid.plot)
  
  png(paste("resids", Sys.Date(), "png", sep = "."), 
      width = 19, height = 27, units = "cm", res = 300)
  print(out.res) 
  downViewport(trellis.vpname(name = "figure"))
  vp1 <- viewport(x = 0.5, y = 0,
                  height = 0.07, width = 0.75,
                  just = c("centre", "top"),
                  name = "key.vp")
  pushViewport(vp1)
  draw.colorkey(key = list(col = clrs.resids(1200), width = 1,
                           at = seq(-1, 1, 0.01),
                           space = "bottom"), draw = TRUE)
  upViewport()
  vp2 <- viewport(x = 0.5, y = 0,
                  height = 0.07, width = 0.075,
                  just = c("centre", "top"),
                  name = "key.vp")
  pushViewport(vp2)
  draw.colorkey(key = list(col = "white", width = 1,
                           at = seq(-0.1, 0.1, 0.1),
                           tick.number = 2,
                           space = "bottom"), draw = TRUE)
  grid.text("Residuals", x = 0.5, y = 0, just = c("centre", "top"))
  dev.off()
}



#### extract time series for plots
# plots.pred.ts <- as.data.frame(extract(mod.predicted, plots))
# plots.pred.ts$PlotID <- plots$PlotID
# plots.pred.ts.long <- melt(plots.pred.ts)
# 
# plots.obs.ts <- as.data.frame(extract(mod.observed, plots))
# plots.obs.ts$PlotID <- plots$PlotID
# plots.obs.ts.long <- melt(plots.obs.ts)
# 
# 
# obs.p <- xyplot(value ~ variable | PlotID, data = plots.obs.ts.long, 
#                 type = "l")
# pred.p <- xyplot(value ~ variable | PlotID, data = plots.pred.ts.long, 
#                  type = "l", col = "red")
# 
# obs.p + as.layer(pred.p)
# 
# var(unlist(c(plots.obs.ts[44, -13])))
# var(unlist(c(plots.pred.ts[44, -13])))
# ioa(unlist(c(plots.obs.ts[, -13])), unlist(c(plots.pred.ts[, -13])))
# 
# 
# diff.stck <- mod.predicted - mod.observed
# spplot(diff.stck[[1]], at = seq(-0.1, 0.1, 0.01),
#        col.regions = colorRampPalette(brewer.pal(9, "RdBu"))(1000))


### old version of resid plot
# plotResid <- function(sp.obj, 
#                       pred.vals, 
#                       resp.vals, 
#                       txt = "hallo",
#                       #what = c("lower", "upper"),  
#                       n = 1000) {
#   
#   lm1 <- lm(pred.vals ~ resp.vals)
#   
#   resids <- sort(lm1$residuals)
#   lowest <- resids[1:n]
#   highest <- resids[(length(resids) - (n - 1)):length(resids)]
#   
#   lowest.loc <- xyFromCell(mod.predicted, as.integer(names(lowest)))
#   highest.loc <- xyFromCell(mod.predicted, as.integer(names(highest)))
#   
#   clrs.ndvi <- colorRampPalette(brewer.pal(9, "YlGn"))
#   clrs.resids <- brewer.pal(9, "PuOr")
#   
#   lev <- spplot(sp.obj, col.regions = clrs.ndvi(1200), 
#                 at = seq(-1000, 10000, 10), as.table = TRUE,
#                 colorkey = list(space = "top", width = 1, height = 0.75),
#                 main = "NDVI * 10000")
#   pts.low <- xyplot(lowest.loc[, 2] ~ lowest.loc[, 1], 
#                     pch = ".", col = clrs.resids[1])
#   pts.high <- xyplot(highest.loc[, 2] ~ highest.loc[, 1], 
#                      pch = ".", col = clrs.resids[9],
#                      panel = function(...) {
#                        panel.xyplot(...)
#                        panel.text(labels = txt, 
#                                   x = 37.65, y = -2.86, cex = 0.7)})
#   #ptext <- layer(panel.text(labels = txt, x = 38, y = -2.85, cex = 0.7))
#   
#   out <- lev + as.layer(pts.low) + as.layer(pts.high) #+ ptext
#   
#   
#   return(out)
#   
# }
# 
# resid.plot <- lapply(seq(ncol(pred.vals)), function(i) {
#   
#   panel.name <- strsplit(names(mod.stck.eval)[i], "_")[[1]][4]
#   
#   plotResid(sp.obj = mod.predicted[[i]],
#             pred.vals = pred.vals[, i],
#             resp.vals = obs.vals[, i],
#             txt = panel.name,
#             n = 2500) 
# })
# 
# outLayout <- function(x, y) {
#   update(c(x, y, 
#            layout = c(3, length(resid.plot)/3)), 
#          between = list(y = 0.3, x = 0.3))
# }
# 
# out.res <- Reduce(outLayout, resid.plot)
# 
# #png("resids.png", width = 19, height = 27, units = "cm", res = 300)
# print(out.res) 



### leave-one out !! takes a while !!
# ind <- seq(nlayers(modisKiliNDVI))
# 
# eval <- lapply(ind, function(i) {
#   mod.stck.pred <- modisKiliNDVI[[-i]]
#   mod.stck.eval <- modisKiliNDVI[[i]]
#   gimms.stck.pred <- gimmsKiliNDVI[[-i]]
#   gimms.stck.eval <- gimmsKiliNDVI[[i]]
#   
#   ### calculate EOT
#   mode <- eot(pred = gimms.stck.pred,
#               resp = mod.stck.pred, n = 2)
#   
#   
#   ### evaluate prediction
#   ts.mode.eval <- gimms.stck.eval[mode[[1]][[1]]$max.xy]
#   
#   mod.predicted <- stack(lapply(seq(nlayers(mod.stck.eval)), function(i) {
#     mode[[1]][[1]]$int.response + mode[[1]][[1]]$slp.response * ts.mode.eval[i]
#   }))
#   mod.observed <- mod.stck.eval
#   
#   pred.vals <- getValues(mod.predicted) / 10000
#   obs.vals <- getValues(mod.observed) / 10000
#   
#   mnth <- substr(strsplit(names(mod.observed), "_")[[1]][5], 5, 6)
#   ### error scores
#   ME <- colMeans(pred.vals - obs.vals, na.rm = TRUE)
#   MAE <- colMeans(abs(pred.vals - obs.vals), na.rm = TRUE)
#   RMSE <- sqrt(colMeans((pred.vals - obs.vals)^2, na.rm = TRUE))
#   R <- diag(cor(pred.vals, obs.vals, use = "complete.obs"))
#   Rsq <- R * R
#   
#   df <- data.frame(ME, MAE, RMSE, R, Rsq, mnth)
#   
#   return(df)
#   
# })
# 
# eval.df <- do.call("rbind", eval)
# 
# p <- ggplot(data = eval.df, aes(x = as.factor(mnth), y = Rsq))
# 
# png("rsq_by_month.png", width = 19, height = 10, units = "cm", res = 300)
# p + geom_boxplot() + theme_bw() + xlab("Month")
# dev.off()


#ggplot-way
# clrs.hcl <- function(n) {
#   hcl(h = seq(230, 0, length.out = n), 
#       c = 60, l = seq(10, 90, length.out = n), 
#       fixup = TRUE)
# }

# sc.plots <- lapply(seq(ncol(pred.vals)), function(i) {
#   
#   eval.dat <- data.frame(pred = pred.vals[, i], obs = obs.vals[, i])
#   scatter.ggplot <- ggplot(aes(x = obs, y = pred), data = eval.dat)
#   g.sc <- scatter.ggplot + 
#     geom_tile() +
#     #geom_point(colour = "grey60") +
#     #facet_wrap(~ cut, nrow = 3, ncol = 2) +
#     theme_bw() +
#     stat_density2d(aes(fill = ..density..), n = 100,
#                    geom = "tile", contour = FALSE) +
#     scale_fill_gradientn(colours = c("white",
#                                      rev(clrs.hcl(100)))) +
#     stat_smooth(method = "lm", se = TRUE, colour = "black") +
#     coord_fixed(ratio = 1)
#   
#   return(g.sc)
# 
# })
# 
# 
# grid.arrange(sc.plots[[1]], sc.plots[[2]],
#              heights = 1, ncol = 3)
# 


### downscaling 82 to 06
gimms.files <- list.files("whit_gimms_monthly/all", 
                          pattern = glob2rx("*.tif"), full.names = TRUE)

#gimms.files <- gimms.files[-(1:6)]

# gimms.stck <- stack(lapply(seq(gimms.files), function(i) {
#   raster(gimms.files[i])
# }))

gimms.stck <- stack(gimms.files)

# gimms.stck <- crop(gimms.stck, extent(gimmsKiliNDVI))
# timeInfo <- orgTime(paste(substr(gimms.files, 48, 53), "01", sep = ""), 
#                     pos1 = 1, pos2 = 8, format = "%Y%m%d")
# whittaker.raster(gimms.stck, timeInfo = timeInfo, lambda = 500,
#                  removeOutlier = TRUE, nIter = 5, threshold = 0.2,
#                  outDirPath = "whit_gimms_monthly", overwrite = TRUE)


eot.cell <- sapply(seq(nmodes), function(i) {
  cellFromXY(gimms.stck[[1]], modes[[i]]$loc.eot)
})

ts.gimms.modeloc <- extract(gimms.stck, eot.cell)

mod8206.predicted <- lapply(seq(nlayers(gimms.stck)), function(i) {
  stack(lapply(seq(eot.cell), function(k) {
    modes[[k]]$int.response + modes[[k]]$slp.response * ts.gimms.modeloc[k, i]
  }))
})

mod8206.predicted <- stack(lapply(seq(nlayers(gimms.stck)), function(i) {
  calc(mod8206.predicted[[i]], fun = sum)
}))

names(mod8206.predicted) <- names(gimms.stck)

if (write.rasters) {
  writeRaster(mod8206.predicted, overwrite = TRUE,
              "gimms_dwnscld_ndvi_82_06_250m/gimms_dwnscld_ndvi_82_06_250m",
              bylayer = TRUE, suffix = 'names', format = "GTiff")
}

### create ndvi time series for valid plots
resid.stck <- mod.predicted - mod.observed

resids.plots <- extract(resid.stck, plots)

fun <- function(x) !any(abs(x) > 0.1)

ind.valid.plots <- apply(resids.plots, 1, FUN = fun)
valid.plots <- plots#[ind.valid.plots, ]
valid.plot.names <- plots$PlotID#[ind.valid.plots]
time <- seq.Date(as.Date("1982-01-01"), as.Date("2006-12-31"), by = "months")

gimms.vals.valid <- as.data.frame(extract(mod8206.predicted, valid.plots))
names(gimms.vals.valid) <- time
gimms.vals.valid$PlotID <- valid.plot.names
#gimms.vals.valid <- subset(gimms.vals.valid, PlotID != "sun3")

gimms.vals.valid.long <- melt(gimms.vals.valid)

mod.files <- list.files("whit_monthly/all", 
                        pattern = glob2rx("*.tif"), full.names = TRUE)

mod.stck <- stack(lapply(seq(mod.files), function(i) {
  raster(mod.files[i])
}))

#mod.stck <- mod.stck / 10000
mod.stck <- projectRaster(mod.stck, crs = proj4string(gimmsKiliNDVI))

mod.vals.valid <- as.data.frame(extract(mod.stck, valid.plots))
time.mod <- seq.Date(as.Date("2002-07-01"), as.Date("2013-08-31"), by = "months")
names(mod.vals.valid) <- time.mod
mod.vals.valid$PlotID <- valid.plot.names
#mod.vals.valid <- subset(mod.vals.valid, PlotID != "sun3")

mod.vals.valid.long <- melt(mod.vals.valid)

gimms.p <- xyplot(value ~ as.Date(variable) | PlotID, data = gimms.vals.valid.long, 
                  type = "l", as.table = TRUE, layout = c(5, 10),
                  par.settings = list(layout.heights = list(strip = 0.75)),
                  between = list(y = 0.2, x = 0.2), col = "black",
                  ylab = "NDVI", xlab = "",
                  panel = function(x, y, ...) {
                    panel.xyplot(x, y, ...)
                    panel.abline(h = mean(y), lty = 2)
                  },
                  strip = strip.custom(
                    bg = "grey20", par.strip.text = list(col = "white", 
                                                        font = 2, cex = 0.8)),
                  xlim = c(as.Date(gimms.vals.valid.long$variable[1]), 
                           as.Date(mod.vals.valid.long$variable[nrow(mod.vals.valid.long)])))

mod.p <- xyplot(value ~ as.Date(variable) | PlotID, data = mod.vals.valid.long, 
                  type = "l", as.table = TRUE, col = "grey60",
                panel = function(x, y, ...) {
                  panel.xyplot(x, y, ...)
                  panel.abline(h = mean(y), lty = 2, col = "grey60")
                })

png(paste("dnsc_vs_mod", Sys.Date(), "png", sep = "."), 
    width = 19, height = 27, units = "cm", res = 300)
gimms.p + as.layer(mod.p)
dev.off()

gimms.0306 <- subset(gimms.vals.valid.long, 
                     as.Date(variable) > as.Date("2002-12-31") &
                       as.Date(variable) < as.Date("2007-01-01"))

mod.0306 <- subset(mod.vals.valid.long, 
                   as.Date(variable) > as.Date("2002-12-31") &
                     as.Date(variable) < as.Date("2007-01-01"))

gimms.p.0306 <- xyplot(value ~ as.Date(variable) | PlotID, data = gimms.0306, 
                       type = "l", as.table = TRUE, layout = c(5, 10),
                       between = list(y = 0.2, x = 0.2), col = "black",
                       ylab = "NDVI", xlab = "",
                       panel = function(x, y, ...) {
                         panel.xyplot(x, y, ...)
                         panel.abline(h = mean(y), lty = 2)
                       },
                       strip = strip.custom(
                         bg = "grey20", par.strip.text = list(col = "white", 
                                                             font = 2, cex = 0.8)))

mod.p.0306 <- xyplot(value ~ as.Date(variable) | PlotID, data = mod.0306, 
                     type = "l", as.table = TRUE, col = "grey60",
                     panel = function(x, y, ...) {
                       panel.xyplot(x, y, ...)
                       panel.abline(h = mean(y), lty = 2, col = "grey60")
                     })

png(paste("dnsc_vs_mod_0306", Sys.Date(), "png", sep = "."),
    width = 19, height = 27, units = "cm", res = 300)
gimms.p.0306 + as.layer(mod.p.0306)
dev.off()


# merged.vals.valid <- merge(gimms.vals.valid, mod.vals.valid, by = "PlotID")
# merged.vals.valid.long <- melt(merged.vals.valid)
# 
# xyplot(value ~ as.Date(variable) | PlotID, data = merged.vals.valid.long, 
#        type = "l", as.table = TRUE)
# 
# kza.vals.valid <- t(sapply(seq(nrow(merged.vals.valid)), function(i) {
#   kza(merged.vals.valid[i, 2:ncol(merged.vals.valid)], 
#       m = 13, k = 3, impute_tails = TRUE)$kz
# }))
# kza.vals.valid <- as.data.frame(kza.vals.valid)
# names(kza.vals.valid) <- names(merged.vals.valid)[-1]
# kza.vals.valid$PlotID <- valid.plot.names[-10]
# kza.vals.valid.long <- melt(kza.vals.valid)
# 
# xyplot(value ~ as.Date(variable) | PlotID, data = kza.vals.valid.long, 
#        type = "l", as.table = TRUE)




### MODIS creation
# data(gimmsKiliNDVI)
# mod.files <- list.files("myd13_kalahari", pattern = glob2rx("*.tif"), 
#                         full.names = TRUE)
# 
# mod.files.parts <- strsplit(mod.files, "_")
# mod.files.parts <- unlist(lapply(seq(mod.files.parts), function(i) {
#   tmp <- mod.files.parts[[i]][2]
#   year <- substr(tmp, 19, 22)
#   jul <- substr(tmp, 23, 25)
#   format(as.Date(paste(year, jul, sep = ""), format = "%Y%j"), "%Y%m")
# }))
# 
# ind <- vector("numeric", length(mod.files.parts))
# 
# for (i in 2:length(mod.files.parts)) {
#   ind[1] <- 1
#   if (identical(mod.files.parts[i], mod.files.parts[i - 1])) {
#     ind[i] <- ind[i - 1]} else ind[i] <- ind[i - 1] + 1
# }
# 
# mod.ls.st <- stack(lapply(mod.files, function(x) {
#   raster(x)
# }))
# 
# ext <- extent(c(25, 26, -24, -23))
# mod.ls <- crop(mod.ls, ext)
# 
# mod.months <- stackApply(mod.ls, indices = ind, 
#                          fun = max, na.rm = TRUE)
# 
# mod.months.ll <- projectRaster(mod.months, crs = proj4string(gimmsKiliNDVI))
# names(mod.months) <- paste("MYD_NDVI_max", unique(mod.files.parts),
#                               sep = "_")
# 
# writeRaster(mod.months, "myd13_months_kalahari/MODIS", 
#             bylayer = TRUE, suffix = "names")
# 

