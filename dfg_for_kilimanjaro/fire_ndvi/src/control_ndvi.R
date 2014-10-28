lib <- c("raster", "rgdal", "doParallel", "reshape2", "ggplot2", "scales")
sapply(lib, function(x) library(x, character.only = TRUE))

registerDoParallel(cl <- makeCluster(2))

source("src/visMannKendall.R")
source("../gimms3g/gimms3g/sortByElevation.R")

### DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

### KiLi plots
plots <- readOGR(dsn = "data/coords/", 
                 layer = "PlotPoles_ARC1960_mod_20140807_final")
plots <- subset(plots, PoleType == "AMP")

official_plots <- c(paste0("cof", 1:5), 
                    paste0("fed", 1:5),
                    paste0("fer", 0:4), 
                    paste0("flm", c(1:4, 6)), 
                    paste0("foc", 1:5), 
                    paste0("fod", 1:5), 
                    paste0("fpd", 1:5), 
                    paste0("fpo", 1:5), 
                    paste0("gra", c(1:2, 4:6)), 
                    paste0("hel", 1:5), 
                    paste0("hom", 1:5), 
                    paste0("mai", 1:5), 
                    paste0("sav", 1:5))

plots <- subset(plots, PlotID %in% official_plots)

### NDVI (2003-2013)
st_year <- "2003"
nd_year <- "2013"

rst <- foreach(i = c("mod13q1", "myd13q1"), .packages = lib, 
                  .export = "visMannKendall") %dopar% {

  fls_ndvi <- list.files(paste0("data/processed/whittaker_", i), 
                         pattern = "^WHT.*.tif$", full.names = TRUE)
  
  st <- grep(st_year, fls_ndvi)[1]
  nd <- grep(nd_year, fls_ndvi)[length(grep(nd_year, fls_ndvi))]
  
  fls_ndvi <- fls_ndvi[st:nd]
  rst_ndvi <- stack(fls_ndvi)
  
  png_out <- paste0("out/mk/", i, "_mk01_0313.png")
  png(png_out, units = "mm", width = 300, 
      res = 300, pointsize = 20)
  plot(visMannKendall(rst = rst_ndvi, 
                      dem = dem, 
                      p_value = .01, 
                      filename = paste0("out/mk/", i, "_mk01_0313"), 
                      format = "GTiff", overwrite = TRUE))
  dev.off()
  
  return(rst_ndvi)
}

### NDVI MOD vs. MYD: plot basis
ls_val <- foreach(i = rst, j = list("mod14a1", "myd14a1"), .packages = lib, 
                  .export = "sortByElevation") %dopar% {
  mat_val <- extract(i, plots)
  df_val <- data.frame(PlotID = plots@data$PlotID, mat_val)
  names(df_val)[2:ncol(df_val)] <- substr(names(df_val)[2:ncol(df_val)], 5, 11)
  df_val <- sortByElevation(plot_names = official_plots, plot_shape = plots, 
                            val = df_val)
  mlt_val <- melt(df_val, id.vars = c(1, ncol(df_val)), variable.name = "date", value.name = toupper(j))
  mlt_val$date <- as.Date(mlt_val$date, format = "%Y%j")
  mlt_val[, toupper(j)] <- mlt_val[, toupper(j)] / 10000
  return(mlt_val)
}

png("out/plots/ndvi_terra_vs_aqua.png", width = 24, height = 27, units = "cm", 
    res = 300, pointsize = 15)
ggplot() + 
  geom_line(aes(x = date, y = MOD14A1), data = ls_val[[1]], color = "black", 
            alpha = .35) + 
  geom_line(aes(x = date, y = MYD14A1), data = ls_val[[2]], color = "grey", 
            alpha = .35) + 
  stat_smooth(aes(x = date, y = MOD14A1), data = ls_val[[1]], method = "lm", 
              color = "black", se = FALSE, lwd = 1, lty = 1) + 
  stat_smooth(aes(x = date, y = MYD14A1), data = ls_val[[2]], method = "lm", 
              color = "grey", se = FALSE, lwd = 1, lty = 1) + 
  facet_wrap(~ PlotID, ncol = 5, scales = "free_y") + 
  scale_x_date(labels = date_format("%Y"), 
               breaks = date_breaks(width = "4 years"), 
               minor_breaks = waiver()) +
  labs(x = "Time", y = "NDVI") + 
  theme_bw() + 
  theme(panel.grid = element_blank())
dev.off()

# Apply `convert -trim` to all png images 
fls_png <- list.files("out/", pattern = ".png", full.names = TRUE, recursive = TRUE)
for (i in fls_png)
  system(paste("convert -trim", i, i))

