library(latticeExtra)
library(extRemes)
library(vcd)
library(ggplot2)

path <- "/media/HDEXTENSION/kili_precip/"
setwd(path)

kia.prcp <- read.csv("kia_prcp_1975_2014_mnthly.csv",
                     stringsAsFactors = FALSE)
kia.prcp$date <- as.POSIXct(kia.prcp$date)
kia.prcp$year <- substr(kia.prcp$date, 1, 4)

lst <- split(kia.prcp, kia.prcp$year)

kia.prcp.cont <- do.call("rbind", lapply(seq(lst), function(i) {
  n <- nrow(lst[[i]])
  if (n < 12) out <- NULL else out <- lst[[i]]
  return(out)
}))

# start.time <- kia.prcp$date[1]
# end.time <- kia.prcp$date[nrow(kia.prcp)]
# time.step <- "months"
# date.from <- as.POSIXct(start.time)
# date.to <- as.POSIXct(end.time)
# 
# tseries <- data.frame(date = seq(from = date.from, to = date.to, 
#                                  by = time.step))
# 
# kia.prcp.cont <- merge(tseries, kia.prcp, all.x = TRUE)
# 
kia.prcp.cont$year <- substr(kia.prcp.cont$date, 1, 4)
kia.prcp.cont$month <- substr(kia.prcp.cont$date, 6, 7)
kia.prcp.cont$dec <- paste(substr(kia.prcp.cont$date, 1, 3), "0", sep = "")

mnth.ave <- aggregate(kia.prcp.cont$P_RT_NRT, by = list(kia.prcp.cont$month), 
                      FUN = mean, na.rm = TRUE)
names(mnth.ave) <- c("month", "P_RT_NRT_mmean")
kia.prcp.cont <- merge(kia.prcp.cont, mnth.ave, all.x = TRUE)
kia.prcp.cont <- kia.prcp.cont[order(kia.prcp.cont$date), ]
kia.prcp.cont$dev <- kia.prcp.cont$P_RT_NRT - kia.prcp.cont$P_RT_NRT_mmean
kia.prcp.cont$dry <- kia.prcp.cont$dev < 0
kia.prcp.cont$wet <- kia.prcp.cont$dev >= 0


########### PRECIP DISTRIBUTION PER DECADE ################################

kia.prcp.cont.nona <- kia.prcp.cont[complete.cases(kia.prcp.cont$P_RT_NRT), ]
nmonths <- aggregate(kia.prcp.cont.nona$month,
                     by = list(kia.prcp.cont.nona$dec),
                     FUN = length)$x

brks <- quantile(kia.prcp.cont$dev, 
                 probs = c(0, 0.05, 0.25, 0.75, 0.95, 1), 
                 na.rm = TRUE)
kia.prcp.cont$quants <- cut(kia.prcp.cont$dev, breaks = brks)
levels(kia.prcp.cont$quants) <- c("< 5", "5 - 25", "25 - 75",
                                  "75 - 95", "> 95")

### distribution of monthly precip deviation per decade
p <- ggplot(data = kia.prcp.cont, aes(x = dev)) + geom_density() +
  facet_grid(~ dec)

# Extract the data part from the constructed graph 
dfp <- ggplot_build(p)$data[[1]] 
dfp$group <- as.factor(dfp$group)
levels(dfp$group) <- levels(as.factor(kia.prcp.cont$dec))
# Define the x-width of each interval 
delta <- diff(dfp$x)[1] 

vars <- data.frame(expand.grid(levels(dfp$group)))
colnames(vars) <- c("group")
dat <- data.frame(x = rep(700, 5), 
                  y = rep(0.008, 5),
                  vars,
                  labs = paste("n =", nmonths))

# Replot using geom_segment() instead 
png("kia_precip_deviation_per_decade.png", width = 30, height = 15, 
    units = "cm", res = 300)
ggplot(dfp) + 
  geom_vline(xintercept = 0, linetype="dotted") +
  geom_segment(aes(x = x - delta/10, xend = x + delta/10, 
                   y = ymin, yend = ymax, color = x),
               size = 1.05) + 
  scale_color_gradient2(low = "red", mid = "beige", high = "blue",
                        name = "Precip\n [mm]") +
  #coord_flip() +
  #scale_fill_gradient() +
  facet_grid(group ~ .) +
  theme_bw() +
  geom_density(data = kia.prcp.cont, aes(x = dev), col = "grey") +
  ylab("") + 
  xlab("Precipitation deviation from long-term monthly mean [mm]") +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank()) +
  geom_text(aes(x = x, y = y, label = labs, group = NULL), 
            data = dat)
dev.off()


################# RETURN PERIODS ##########################################

# kia.prcp.dec <- split(kia.prcp.cont, kia.prcp.cont$dec)
# kia.prcp.dec <- list(rbind(kia.prcp.dec[[1]], kia.prcp.dec[[2]]),
#             kia.prcp.dec[[3]],
#             rbind(kia.prcp.dec[[4]], kia.prcp.dec[[5]]))

ind <- as.integer(seq(1, nrow(kia.prcp.cont), length.out = 4))

kia.prcp.dec <- list(kia.prcp.cont[1:ind[2], ],
                     kia.prcp.cont[ind[2]:ind[3], ],
                     kia.prcp.cont[ind[3]:ind[4], ])

labs <- do.call("c", lapply(seq(kia.prcp.dec), function(i) {
  st <- substr(kia.prcp.dec[[i]]$date[1], 1, 4)
  nd <- substr(kia.prcp.dec[[i]]$date[nrow(kia.prcp.dec[[i]])], 1, 4)
  yrs <- paste(st, nd, sep = " - ")
  nmonths <- nrow(kia.prcp.dec[[i]])
  paste(yrs, " (n = ", nmonths, ")", sep = "")
}))

fit <- lapply(seq(kia.prcp.dec), function(j) {
  t <- fevd(kia.prcp.dec[[j]]$dev, time.units = "month", period = "month", 
            units = "mm")
  return(t)
})

rperiods <- c(2, 5, 10, 20, 50, 80, 100, 120, 200, 250, 300, 500, 800)

yrl <- lapply(seq(fit), function(i) {
  bds <- ci(fit[[i]], return.period = rperiods)
  bds[, 2]
})

xrl <- -1/(log(1 - 1/rperiods))

clrs <- brewer.pal(9, "Blues")

p <- lapply(seq(fit), function(i) {
  xyplot(yrl[[i]] ~ xrl, type = "l", log = "x", ylim = c(-100, 700), 
         col = clrs[i*3], lwd = 3, scales = list(x = list(log = 10)),
         xscale.components = xscale.components.log10ticks,
         yscale.components = yscale.components.subticks,
         ylab = "Return level [mm]", xlab = "Return time [months]")
})

outLayout <- function(x, y) {
  x + as.layer(y)
}

out2 <- Reduce(outLayout, p)

png("kia_extremes_return_periods.png", width = 20, height = 20, 
    units = "cm", res = 300)
grid.newpage()
print(out2, newpage = FALSE)
downViewport(trellis.vpname(name = "figure"))
#grid.rect()
vp1 <- viewport(x = 0.2, y = 0.95, 
                height = 0.2, width = 0.2,
                just = c("left", "top"),
                name = "legend.vp")

pushViewport(vp1)

draw.key(key = list(col = clrs[c(3, 6, 9)],
                    lines = TRUE, lwd = 3,
                    text = list(labs, col = "black")), draw = TRUE)
upViewport(0)
dev.off()












# plot(xrl, yrl[[1]], type = "l", log = "x", ylim = c(-100, 700), 
#      col = clrs[2], lwd = 5, main = "")
# par(new = TRUE)
# plot(xrl, yrl[[2]], type = "l", log = "x", ylim = c(-100, 700), 
#      col = clrs[4], lwd = 5, main = "")
# par(new = TRUE)
# plot(xrl, yrl[[3]], type = "l", log = "x", ylim = c(-100, 700), 
#      col = clrs[6], lwd = 5, main = "")
# 
# 
# clr <- brewer.pal(5, "RdBu")
# png("kia_xtremes_per_decade.png", width = 25, height = 25, 
#     units = "cm", res = 300)
# mosaic(quants ~ dec, data = kia.prcp.cont, gp = gpar(fill = clr,
#                                                       col = "transparent"),
#              margins = c(2, 1, 1, 5), pop = FALSE, direction = "h",
#              #labeling = labeling_values,
#              labeling_args = list(dep_varname = FALSE,
#                                   rot_labels = 0,
#                                   varnames = FALSE,
#                                   labels = c(TRUE, TRUE),
#                                   boxes = FALSE,
#                                   just_labels = c("center", "right"),
#                                   pos_labels = c("center")))
# dev.off()
# 
# kia.drought <- aggregate(kia.prcp.cont$dry, by = list(kia.prcp.cont$year),
#                          FUN = sum, na.rm = TRUE)
# 
# kia.wetness <- aggregate(kia.prcp.cont$wet, by = list(kia.prcp.cont$year),
#                          FUN = sum, na.rm = TRUE)
# 
# lm1 <- lm(kia.drought$x ~ as.Date(paste(kia.drought$Group.1, 
#                                         "01", "01", sep = "-")))
# summary(lm1)
# barplot(kia.drought$x)
# 
# lm2 <- lm(kia.wetness$x ~ as.Date(paste(kia.wetness$Group.1, 
#                                         "01", "01", sep = "-")))
# 
# summary(lm2)
# barplot(kia.wetness$x)
