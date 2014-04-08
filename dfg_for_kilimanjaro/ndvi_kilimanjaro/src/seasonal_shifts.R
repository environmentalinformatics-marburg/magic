library(TSA)
library(latticeExtra)
library(raster)

path <- "/media/tims_ex/kilimanjaro_ndvi_harmonics"
setwd(path)

#source("cellHarmonics.R")

files <- list.files("/media/tims_ex/reot_ndvi_dwnsc/gimms_dwnscld_ndvi_82_06_250m", full.names = TRUE)

strt <- stack(files[1:(12*6)])# / 10000
end <- stack(files[(length(files) - (12*6) + 1):length(files)])# / 10000

plots <- read.csv("kili_plots_64.csv")
plots <- subset(plots, Valid == "Y")
plots <- subset(plots, Categories == "maize" | Categories == "savanna")
#plots <- plots[plots$Categories != "sun coffee plantation", ]
coordinates(plots) <- c("POINT_X", "POINT_Y")

strt.plots <- extract(strt, plots)
end.plots <- extract(end, plots)

sin.list <- lapply(seq(plots$PlotID), function(i) {
  
  st.ts <- ts(strt.plots[i, ], start = c(1982, 1), 
              end = c(1987, 12), frequency = 12)
  st.har <- harmonic(st.ts, m = 2)
  st.mod <- lm(st.ts ~ st.har)
  st.fit <- ts(fitted(st.mod), start = c(1982, 1), end = c(1987, 12), 
               frequency = 12)
  
  # Medianxyplot(~ st.ts)
  st.fit.med <- apply(matrix(st.fit, ncol = 12, byrow = T), 2, 
                      FUN = median)
  
  
  end.ts <- ts(end.plots[i, ], start = c(2001, 1), 
               end  = c(2006, 12), frequency = 12)
  end.har <- harmonic(end.ts, m = 2)
  end.mod <- lm(end.ts ~ end.har)
  end.fit <- ts(fitted(end.mod), start = c(2001, 1), end = c(2006, 12), 
                frequency = 12)
  
  # Median
  end.fit.med <- apply(matrix(end.fit, ncol = 12, byrow = T), 2, 
                       FUN = median)

  key.txt <- list(c("1982 - 1987", "2001 - 2006"))
  
  st.plot <- xyplot(st.fit.med ~ seq(st.fit.med), type = "l", asp = 1,
                    ylim = c(0.35, 0.75), lty = 2,
                    xlab = "Months", ylab = "NDVI")
  
  end.plot <- xyplot(end.fit.med ~ seq(end.fit.med), type = "l", 
                     ylim = c(0.35, 0.75), col = "red2", lty = 1)

  return(st.plot + as.layer(end.plot))
  
})

outLayout <- function(x, y) {
  update(c(x, y, 
           layout = c(5, 2)), 
         between = list(y = 0.3, x = 0.3))
}

out <- Reduce(outLayout, sin.list)

png("ndvi_seasonal_shifts_mai_sav.png", width = 30, height = 20, 
    units = "cm", res = 300)
update(out, strip = strip.custom(bg = "grey20", 
                                 factor.levels = toupper(plots$PlotID), 
                                 par.strip.text = list(col = "white", 
                                                       font = 2, 
                                                       cex = 0.8)),
       par.settings = list(layout.heights = list(strip = 0.8)),
       key = list(x = 0.01, y = 0.525, corner = c(0, 0), 
                  lines = list(lty = c(2, 1), 
                               col = c("cornflowerblue", 
                                       "red2")), cex = 0.7,
                  text = key.txt))
dev.off()
  # mod.plots <- as.data.frame(mod.plots)
# mod.plots$PlotID <- plots$PlotID
# mod.plots.long <- melt(mod.plots)

# tst <- cellHarmonics(st = strt, nd = end, 
#                      st.start =  c(2003, 1),
#                      st.end = c(2005, 12),
#                      nd.start = c(2010, 1),
#                      nd.end = c(2012, 12))
