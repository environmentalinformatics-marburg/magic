lib <- c("raster", "rgdal", "doParallel", "reshape2", "ggplot2", "scales", "grid")
sapply(lib, function(x) library(x, character.only = TRUE))

registerDoParallel(cl <- makeCluster(2))

source("src/visMannKendall.R")
source("../gimms3g/gimms3g/sortByElevation.R")
source("src/visTerraAqua.R")

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

p_mk <- foreach(i = c("mod13q1", "myd13q1"), .packages = lib, 
                  .export = "visMannKendall") %dopar% {

  fls_ndvi <- list.files(paste0("data/processed/whittaker_", i), 
                         pattern = "^WHT.*.tif$", full.names = TRUE)
  
  st <- grep(st_year, fls_ndvi)[1]
  nd <- grep(nd_year, fls_ndvi)[length(grep(nd_year, fls_ndvi))]
  
  fls_ndvi <- fls_ndvi[st:nd]
  rst_ndvi <- stack(fls_ndvi)
  
  p <- visMannKendall(rst = rst_ndvi, 
                      dem = dem, 
                      p_value = .001, 
                      filename = paste0("out/mk/", i, "_mk001_0313"), 
                      format = "GTiff", overwrite = TRUE)

#   png_out <- paste0("out/mk/", i, "_mk001_0313.png")
#   png(png_out, units = "mm", width = 300, 
#       res = 300, pointsize = 20)
#   plot(p)
#   dev.off()
  
  return(p)
}

### Amount of significant positive and negative pixels in Terra and Aqua
ls_mk <- lapply(c("mk01", "mk001"), function(h) {
  fls_mk <- list.files("out/mk/", pattern = paste(h, ".tif$", sep = ".*"), 
                       full.names = TRUE)
  rst_mk <- lapply(fls_mk, raster)
  
  val_mk_pos <- sapply(rst_mk, function(i) sum(values(i) > 0, na.rm = TRUE) / ncell(i))
  val_mk_neg <- sapply(rst_mk, function(i) sum(values(i) < 0, na.rm = TRUE) / ncell(i))
  
  val_mk <- cbind(val_mk_pos, val_mk_neg)
  val_mk <- round(val_mk, 3)
  
  df_mk <- data.frame(sensor = c("mod13q1", "myd13q1"), val_mk)
  names(df_mk)[2:3] <- paste(c("pos", "neg"), h, sep = "_")
  return(df_mk)
})

### Density plots of significant pixels in Terra and Aqua
ls_val <- lapply(c("mk01", "mk001"), function(h) {
  fls_mk <- list.files("out/mk/", pattern = paste(h, ".tif$", sep = ".*"), 
                       full.names = TRUE)
  val_mk <- lapply(fls_mk, function(i) {
    rst_mk <- raster(i)
    values(rst_mk)
  })
})

# scientific_10 <- function(x) {
#   parse(text=gsub("e", " %*% 10^", scientific_format()(x)))
# }

png("out/mk/ndvi_mk_terra_vs_aqua.png", width = 26, height = 18, units = "cm", 
    res = 300, pointsize = 12)
ggplot() + 
#   geom_density(aes(x = ls_val[[1]][[1]], y = ..count.., colour = "Terra"), lwd = 1.2) + 
#   geom_density(aes(x = ls_val[[1]][[2]], y = ..count.., colour = "Aqua"), lwd = 1.2) +
  geom_line(aes(x = ls_val[[2]][[1]], y = ..count.., lty = "Terra"), 
            stat = "density", lwd = 2.5) + 
  geom_line(aes(x = ls_val[[2]][[2]], y = ..count.., lty = "Aqua"), 
            stat = "density", lwd = 2.5) + 
#   scale_colour_manual("Sensor\n", breaks = c("Terra", "Aqua"), 
#                       values = c("Terra" = "grey75", "Aqua" = "black")) + 
  scale_linetype_manual("", breaks = c("Terra", "Aqua"), 
                        values = c("Terra" = 2, "Aqua" = 1)) +
#   scale_y_continuous(labels = scientific_10) + 
  labs(x = "\nKendall's tau", y = "Frequency\n") + 
  theme_bw() + 
  theme(text = element_text(size = 30), 
        panel.grid = element_blank(),
        legend.key.size = unit(2.5, "cm"), 
        legend.key = element_rect(colour = "transparent"),
        legend.text = element_text(size = 40),
        legend.position = c(1, 1), legend.justification = c(1, 1))
dev.off()

### Differences between significant Terra and Aqua pixels (Terra - Aqua)
ls_val <- lapply(c("mk01", "mk001"), function(h) {
  fls_mk <- list.files("out/mk/", pattern = paste("^m", h, ".tif$", sep = ".*"), 
                       full.names = TRUE)
  rst_mk <- lapply(fls_mk, raster)
  val_mk <- do.call("cbind", lapply(rst_mk, values))
  val_diff <- val_mk[, 1] - val_mk[, 2]

  return(val_diff)
})

png("out/mk/ndvi_mk_diff_terra_vs_aqua.png", width = 26, height = 18, 
    units = "cm", res = 300, pointsize = 12)
ggplot() + 
  geom_line(aes(x = ls_val[[1]], y = ..count.., lty = "p < 0.01"), 
            stat = "density", lwd = 1.1) + 
  geom_line(aes(x = ls_val[[2]], y = ..count.., lty = "p < 0.001"), 
            stat = "density", lwd = 1) + 
  scale_linetype_manual("", breaks = c("p < 0.01", "p < 0.001"), 
                      values = c("p < 0.01" = 1, "p < 0.001" = 2)) + 
  labs(x = expression("Kendall's" * tau [Difference]), y = "Frequency") + 
  theme_bw() + 
  theme(text = element_text(size = 15), 
        legend.key.size = unit(1, "cm"))
dev.off()


### NDVI MOD vs. MYD: plot basis
rst_cld <- foreach(i = c("mod13q1", "myd13q1"), .packages = lib) %dopar% {
  
  fls_cld <- list.files("data/processed/", full.names = TRUE, 
                        pattern = paste("^BF", toupper(i), "NDVI.tif$", sep = ".*"))
  
  st <- grep(st_year, fls_cld)[1]
  nd <- grep(nd_year, fls_cld)[length(grep(nd_year, fls_cld))]
  
  fls_cld <- fls_cld[st:nd]
  rst_cld <- stack(fls_cld) / 10000
  
  return(rst_cld)
}

rst_vza <- foreach(i = c("mod13q1", "myd13q1"), .packages = lib) %dopar% {
                     
  fls_vza <- list.files("data/processed/", full.names = TRUE,
                        pattern = paste("CRP", toupper(i), 
                                        "view_zenith_angle.tif$", sep = ".*"))
  
  st <- grep(st_year, fls_vza)[1]
  nd <- grep(nd_year, fls_vza)[length(grep(nd_year, fls_vza))]
  
  fls_vza <- fls_vza[st:nd]
  rst_vza <- stack(fls_vza) * .01
  
  return(rst_vza)
}

png("out/plots/ndvi_terra_vs_aqua.png", width = 24, height = 27, units = "cm", 
    res = 300, pointsize = 15)
visTerraAqua(rst = rst, 
             cld = rst_cld,
             vza = rst_vza,
             plot_names = official_plots, 
             plot_shape = plots)
dev.off()

# Apply `convert -trim` to all png images 
fls_png <- list.files("out/", pattern = ".png", full.names = TRUE, recursive = TRUE)
for (i in fls_png)
  system(paste("convert -trim", i, i))

stopCluster(cl)
