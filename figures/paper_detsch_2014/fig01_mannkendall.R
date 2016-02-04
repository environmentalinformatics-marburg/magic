setwd("/media/envin/XChange/kilimanjaro/ndvi/")

lib <- c("grid", "Rsenal", "latticeExtra", "doParallel", "ggplot2")
sapply(lib, function(x) library(x, character.only = TRUE))

source("src/panel.smoothconts.R")
source("src/visMannKendall.R")

registerDoParallel(cl <- makeCluster(2))

### DEM
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")
dem_flipped <- flip(dem, "y")
x <- coordinates(dem_flipped)[, 1]
y <- coordinates(dem_flipped)[, 2]
z <- dem_flipped[]

p_dem <- levelplot(z ~ x * y, colorkey = FALSE, at = seq(1000, 6000, 1000), 
                   panel = function(...) {
                     panel.smoothconts(zlevs.conts = seq(1000, 5500, 500), 
                                       labels = c(1000, "", 2000, "", 3000, "", 4000, "", 5000, ""), ...)
                   })

### Mann-Kendall rasters for NDVI (2003-2013)
st_year <- "2003"
nd_year <- "2013"

p_mk <- foreach(i = c("mod13q1", "myd13q1"), .packages = lib, 
                .export = "visMannKendall") %dopar% {
                  
  fls_ndvi <- list.files(paste0("data/processed/whittaker_", i), 
                         pattern = "^DSN_SCL_AGGMAX_WHT.*.tif$", full.names = TRUE)
  
  st <- grep(st_year, fls_ndvi)[1]
  nd <- grep(nd_year, fls_ndvi)[length(grep(nd_year, fls_ndvi))]
  
  fls_ndvi <- fls_ndvi[st:nd]
  rst_ndvi <- stack(fls_ndvi)
  
  p <- visMannKendall(rst = rst_ndvi, 
                      dem = dem, 
                      p_value = .001, 
                      filename = paste0("out/mk/", i, "_mk001_0313"), 
                      format = "GTiff", overwrite = TRUE)
  
  p <- p + as.layer(p_dem)
  
  return(p)
}

### Statistics
fls_mk001 <- list.files("out/mk", pattern = "mk001_0313.tif$", full.names = TRUE)
rst_mk001 <- lapply(fls_mk001, raster)

# Terra amount of significant pixels
val_mk001_terra <- rst_mk001[[1]][]
val_mk001_terra_abs <- sum(!is.na(rst_mk001[[1]][]))
val_mk001_terra_rel <- val_mk001_terra_abs / ncell(rst_mk001[[1]])
val_mk001_terra_abs_pos <- sum(val_mk001_terra > 0, na.rm = TRUE)
val_mk001_terra_rel_pos <- val_mk001_terra_abs_pos / val_mk001_terra_abs
val_mk001_terra_abs_neg <- sum(val_mk001_terra < 0, na.rm = TRUE)
val_mk001_terra_rel_neg <- val_mk001_terra_abs_neg / val_mk001_terra_abs

# Same for Aqua
val_mk001_aqua <- rst_mk001[[2]][]
val_mk001_aqua_abs <- sum(!is.na(rst_mk001[[2]][]))
val_mk001_aqua_rel <- val_mk001_aqua_abs / ncell(rst_mk001[[2]])
val_mk001_aqua_abs_pos <- sum(val_mk001_aqua > 0, na.rm = TRUE)
val_mk001_aqua_rel_pos <- val_mk001_aqua_abs_pos / val_mk001_aqua_abs
val_mk001_aqua_abs_neg <- sum(val_mk001_aqua < 0, na.rm = TRUE)
val_mk001_aqua_rel_neg <- val_mk001_aqua_abs_neg / val_mk001_aqua_abs

val_mk001 <- cbind(val_mk001_terra, val_mk001_aqua)
val_mk001_cc <- val_mk001[complete.cases(val_mk001), ]
mean(val_mk001_cc[, 1] - val_mk001_cc[, 2])

### Mann-Kendall values
ls_val <- lapply("mk001", function(h) {
  fls_mk <- list.files("out/mk/", pattern = paste(h, ".tif$", sep = ".*"), 
                       full.names = TRUE)
  val_mk <- lapply(fls_mk, function(i) {
    rst_mk <- raster(i)
    values(rst_mk)
  })
})

### Density plot
p_dens <- ggplot() + 
  geom_line(aes(x = ls_val[[1]][[1]], y = ..count.., colour = "Terra"), 
            stat = "density", lwd = .8) + 
  geom_line(aes(x = ls_val[[1]][[2]], y = ..count.., colour = "Aqua"), 
            stat = "density", lwd = .8) + 
  scale_colour_manual("", breaks = c("Terra", "Aqua"), 
                      values = c("Terra" = "grey75", "Aqua" = "black")) + 
  labs(x = expression("Kendall's " * tau), y = "Count") + 
  theme_bw() + 
  theme(text = element_text(size = 7), 
        panel.grid = element_blank(),
        legend.key.size = unit(3, "mm"), 
        legend.key = element_rect(colour = "transparent"),
        legend.text = element_text(size = 9),
        legend.position = c(.8, .75), legend.justification = c("center", "center"), 
        plot.margin = unit(rep(0, 4), units = "mm"), 
        panel.border = element_rect(colour = "black"))

# ### Difference Terra-Aqua plot
# ls_val <- lapply(c("mk01", "mk001"), function(h) {
#   fls_mk <- list.files("out/mk/", pattern = paste("^m", h, ".tif$", sep = ".*"), 
#                        full.names = TRUE)
#   rst_mk <- lapply(fls_mk, raster)
#   val_mk <- do.call("cbind", lapply(rst_mk, values))
#   val_diff <- val_mk[, 1] - val_mk[, 2]
#   
#   return(val_diff)
# })
# 
# p_diff <- ggplot() + 
#   geom_vline(xintercept = 0, colour = "grey50", linetype = "dashed") + 
#   geom_line(aes(x = ls_val[[2]], y = ..count..), stat = "density", lwd = .8) + 
#   labs(x = expression("Kendall's " * tau [Terra-Aqua]), y = "Count") + 
#   theme_bw() + 
#   theme(text = element_text(size = 15), panel.grid = element_blank(), 
#         legend.key.size = unit(1, "cm"), 
#         plot.margin = unit(rep(0, 4), units = "mm"), 
#         panel.border = element_rect(colour = "black"))

### Combination of MannKendall `spplot` objects
p_mk_comb <- latticeCombineGrid(p_mk, layout = c(1, 2))

vp_dens <- viewport(x = .8, y = .5, 
                    height = 0.2, width = 0.4,
                    just = c("center", "center"))

### Final figure
png("out/final/fig01_mannkendall.png", width = 26, height = 36, units = "cm", 
    res = 300, pointsize = 15)
plot.new()
print(p_mk_comb)
downViewport(trellis.vpname(name = "figure"))
pushViewport(vp_dens)
print(p_dens, newpage = FALSE)
grid.rect(gp = gpar(col = "black", fill = "transparent"))
dev.off()

stopCluster(cl)
