library(latticeExtra)
library(mgcv)
#library(caret)
library(gridExtra)
library(stargazer)

path <- "/media/tims_ex/kilimanjaro_precip_sp1_vs_hemp"
setwd(path)

sp1 <- read.csv("sp01_plot_annual_mean_precipitation_tfi.csv",
                stringsAsFactors = FALSE)
sp1 <- sp1[-c(3, 6), ]
hmp <- read.table("11301.txt", header = TRUE,
                  stringsAsFactors = FALSE)
hmp$PlotID <- tolower(hmp$PlotID)
ele <- read.csv("kili_plots_64.csv",
                stringsAsFactors = FALSE)
ele <- ele[complete.cases(ele), ]
ele <- ele[!ele$PlotID == "gra0", ]
ele <- ele[!ele$PlotID == "fer5", ]
sp1.mnthly <- read.csv("sp01_plot_monthly_mean_precipitation.csv",
                       stringsAsFactors = FALSE)
len <- apply(sp1.mnthly, 2, function(x) { length(na.exclude(x)) })
len <- len[-c(1, 5, 9)]

sp1.hmp.train <- Reduce(function(...) merge(..., all = F), 
                        list(sp1, hmp, ele))
sp1.hmp.eval <- Reduce(function(...) merge(..., all = T), 
                       list(sp1, hmp, ele))

# sp1.prec <- ifelse(is.na(sp1.hmp.train$P_RT_NRT), sp1.hmp.train$TFI,
#               sp1.hmp.train$P_RT_NRT)

sp1.prec <- colMeans(rbind(sp1.hmp.train$P_RT_NRT, sp1.hmp.train$TFI), na.rm=TRUE)

# sp1.prec <- ifelse(is.na(sp1.hmp.train$TFI), sp1.hmp.train$P_RT_NRT,
#                    sp1.hmp.train$TFI)

pred <- data.frame(sp1 = sp1.prec,
                   hmp = sp1.hmp.train$precip_prediction,
                   ele = sp1.hmp.train$Altitude)

eval <- data.frame(sp1 = sp1.hmp.eval$P_RT_NRT,
                   hmp = sp1.hmp.eval$precip_prediction,
                   ele = sp1.hmp.eval$Altitude)

model <- gam(sp1 ~ s(hmp, k = 10) + s(ele, k = 3), 
             data = pred, weights = len/12)

fit <- predict(model, eval)

eval$fit <- fit

sp1.p <- xyplot(sp1 ~ ele, data = pred, type = "p", pch = 17,
                xlab = "Elevation [m]", 
                ylab = "Precipitation [mm]",
                xlim = c(750, 4750)) + layer(panel.smoother(...))
hmp.p <- xyplot(hmp ~ ele, data = eval, 
                type = "p", col = "red2", pch = 16) + layer(panel.smoother(...))
fit.p <- xyplot(fit ~ ele, data = eval, 
                type = "p", col = "black", pch = 15) + layer(panel.smoother(...))

png("precip_sp1_hmp_gam.png", width = 30, height = 15, 
    units = "cm", res = 300)
grid.newpage()
print(sp1.p + as.layer(fit.p) + as.layer(hmp.p))
downViewport(trellis.vpname(name = "figure"))
#grid.rect()
vp1 <- viewport(x = 0.9, y = 0.95, 
                height = 0.2, width = 0.2,
                just = c("right", "top"),
                name = "legend.vp")

pushViewport(vp1)

draw.key(key = list(col = c("cornflowerblue", "red2", "black"),
                    points = list(pch = c(17, 16, 15)),
                    text = list(c("SP1", "HMP", "FIT"), col = "black")), draw = TRUE)
upViewport(0)
dev.off()


xyplot(fit ~ hmp, data = eval, asp = "iso", xlim = c(450, 3450), 
       ylim = c(450, 3450)) + layer(panel.abline(a = 0, b = 1))



############## table of monthly means
prcp.yrly <- apply(sp1.mnthly[, 2:14], 2, sum)

prcp.mnthly <- data.frame(round(t(sp1.mnthly[, 2:14]), 1),
                          round(prcp.yrly, 1))

names(prcp.mnthly) <- c(months(seq.Date(as.Date("2013-01-01"), 
                                      as.Date("2013-12-31"), 
                                      by = "months"),
                             abbreviate = TRUE),
                      "Annual")
#rownames(ta.mnthly) <- NULL

stargazer(prcp.mnthly, out = "monthly_precip.html",
          out.header = TRUE, summary = FALSE, digits = 1)
