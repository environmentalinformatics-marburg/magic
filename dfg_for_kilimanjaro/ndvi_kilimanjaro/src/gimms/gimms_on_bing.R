library(OpenStreetMap)

kili.map <- openproj(openmap(upperLeft = c(-2.8, 36.975), 
                             lowerRight = c(-3.425, 37.75), type = "bing", 
                             minNumTiles = 20L), projection = "+init=epsg:21037")


fls_gimms <- list.files("data/rst/whittaker", pattern = "_crp_utm_wht_aggmax", 
                        full.names = TRUE)
rst_gimms <- stack(fls_gimms)
template <- rasterToPolygons(rst_gimms[[1]])

template@data$id <- rownames(template@data)
template_points <- fortify(template, region = "id")
template_df <- join(template_points, template@data, by="id")

png("vis/kili_topo_gimms_location.png", units = "cm", width = 30, height = 30, 
    res = 300, pointsize = 14)
autoplot(kili.map) + 
  geom_polygon(aes(long, lat, group = group), template_points, 
               fill = "transparent", colour = "black") + 
  theme(axis.title.x = element_text(size = rel(1.4)), 
        axis.text.x = element_text(size = rel(1.1)), 
        axis.title.y = element_text(size = rel(1.4)), 
        axis.text.y = element_text(size = rel(1.1)))
dev.off()
