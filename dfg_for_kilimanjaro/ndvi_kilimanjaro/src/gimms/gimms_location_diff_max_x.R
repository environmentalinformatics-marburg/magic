fls_diff <- list.files("data/rst/harmonic/", pattern = "^diff.*.tif$", full.names = TRUE)
rst_diff <- raster(fls_diff[1])
rst_diff[rst_diff[] > -1.5 & rst_diff[] < 1.5] <- NA
rst_diff[rst_diff[] < -3] <- -3
shp_diff <- rasterToPolygons(rst_diff)
shp_diff@data$id <- rownames(shp_diff@data)
shp_diff_points <- fortify(shp_diff, region = "diff_max_x")

library(RColorBrewer)
cols <- brewer.pal(4, "RdBu")
names(cols) <- c("3", "2", "-2", "-3")

p <- autoplot(kili.map) + 
  geom_polygon(aes(long, lat, group = group, colour = id), data = shp_diff_points, 
               fill = "transparent", size = 1.25) + 
  scale_colour_manual("", values = cols, breaks = c(3, 2, -2, -3)) + 
  theme_bw() + 
  theme(axis.title.x = element_text(size = rel(1.4)), 
        axis.text.x = element_text(size = rel(1.1)), 
        axis.title.y = element_text(size = rel(1.4)), 
        axis.text.y = element_text(size = rel(1.1)))

png("vis/kili_topo__diff_max_x.png", units = "cm", width = 30, 
    height = 24, res = 600, pointsize = 14)
print(p)
dev.off()
