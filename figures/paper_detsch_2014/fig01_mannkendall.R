lib <- c("grid", "Rsenal", "latticeExtra", "doParallel")
sapply(lib, function(x) library(x, character.only = TRUE))

source("src/visMannKendall.R")

registerDoParallel(cl <- cluster(2))

### Mann-Kendall rasters for NDVI (2003-2013)
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

### Combination of MannKendall `spplot` objects
p_mk_comb <- latticeCombineGrid(p_mk, layout = c(1, 2))

vp_dens <- viewport(x = .8, y = .5, 
                    height = 0.2, width = 0.4,
                    just = c("center", "center"))

### Final figure
png("out/final/fig01_mannkendall.png", width = 26, height = 36, units = "cm", 
    res = 300, pointsize = 15)
print(p_mk_comb)
downViewport(trellis.vpname(name = "figure"))
pushViewport(vp_dens)
print(p_dens, newpage = FALSE)
grid.rect(gp = gpar(col = "black", fill = "transparent"))
dev.off()

stopCluster(cl)
