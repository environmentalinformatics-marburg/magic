library(OpenStreetMap)
library(ggplot2)
library(plyr)

# gimms data
fls_gimms <- list.files("data/rst/whittaker", pattern = "_crp_utm_wht_aggmax", 
                        full.names = TRUE)
rst_gimms <- stack(fls_gimms)
template <- rasterToPolygons(rst_gimms[[1]])

template@data$id <- rownames(template@data)
template_points <- fortify(template, region = "id")

# 1-km data
fls_prd <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_prd <- stack(fls_prd)
template_1km <- rasterToPolygons(rst_prd[[1]])

template_1km_crp <- crop(template_1km, template[9, ])
template_1km_crp@data$id <- rownames(template_1km_crp@data)
template_1km_crp_points <- fortify(template_1km_crp, region = "id")

# rgb bing image
ext_gimms <- projectExtent(template, "+init=epsg:4326")

kili.map <- openproj(openmap(upperLeft = c(ymax(ext_gimms), xmin(ext_gimms)), 
                             lowerRight = c(ymin(ext_gimms), xmax(ext_gimms)), 
                             type = "bing", minNumTiles = 40L), 
                             projection = "+init=epsg:21037")

# # visualization of split bing image
# library(Rsenal)
# rst_kili <- raster(kili.map)
# rst_kili <- writeRaster(rst_kili, "data/bing/bing_aerial", format = "GTiff", 
#                         bylayer = FALSE, overwrite = TRUE)
# rst_kili_split <- splitRaster("data/bing/bing_aerial.tif")
# 
# par(mfrow = c(2, 2))
# for (i in c(1, 3, 2, 4))
#   plotRGB(rst_kili_split[[i]])

# np borders
np_old <- readOGR(dsn = "../../ndvi/data/protected_areas/", 
                  layer = "fdetsch-kilimanjaro-national-park-1420535670531", 
                  p4s = "+init=epsg:4326")
np_old_utm <- spTransform(np_old, CRS("+init=epsg:21037"))

np_old_utm@data$id <- rownames(np_old_utm@data) #join id column to data slot on SpatialLinesDataFrame
np_old_utm_df <- fortify(np_old_utm,region="id") #create data frame from SpatialLinesDataFrame
np_old_utm_df <- join(np_old_utm_df, np_old_utm@data, by="id") #add Turbity information to the data frame object

np_new <- readOGR(dsn = "../../ndvi/data/protected_areas/", 
                  layer = "fdetsch-kilimanjaro-1420532792846", 
                  p4s = "+init=epsg:4326")
np_new_utm <- spTransform(np_new, CRS("+init=epsg:21037"))

np_new_utm@data$id <- rownames(np_new_utm@data) #join id column to data slot on SpatialLinesDataFrame
np_new_utm_df <- fortify(np_new_utm,region="id") #create data frame from SpatialLinesDataFrame
np_new_utm_df <- join(np_new_utm_df, np_new_utm@data, by="id") #add Turbity information to the data frame object

# # country borders
# tz <- readOGR(dsn = "data/shp/", layer = "ne_110m_admin_0_countries")
# tz <- crop(tz, spTransform(template, CRS("+init=epsg:4326")))
# tz_utm <- spTransform(tz, CRS("+init=epsg:21037"))
# tz_utm_sl <- as(tz_utm, "SpatialLinesDataFrame")
# 
# tz_utm_sl@data$id <- rownames(tz_utm_sl@data)
# tz_utm_sl_df <- fortify(tz_utm_sl, region = "id")
# tz_utm_sl_df <- join(tz_utm_sl_df, tz_utm_sl@data, by = "id")

png("vis/kili_topo_gimms_location_incl_np.png", units = "cm", width = 30, 
    height = 24, res = 600, pointsize = 14)
autoplot(kili.map) + 
  geom_polygon(aes(long, lat), data = np_new_utm_df, colour = "grey75", 
               lwd = 1.2, fill = "transparent") + 
  geom_polygon(aes(long, lat), data = np_old_utm_df, colour = "grey75", 
               lwd = 1.2, lty = 2, fill = "transparent") + 
  geom_polygon(aes(long, lat, group = group), template_points, 
               fill = "transparent", colour = "black") + 
  geom_polygon(aes(long, lat, group = group), template_1km_crp_points, 
               fill = "transparent", colour = "black") + 
#   geom_polygon(aes(long, lat), data = tz_utm_sl_df, colour = "grey75",
#                fill = "transparent") + 
  theme_bw() + 
  theme(axis.title.x = element_text(size = rel(1.4)), 
        axis.text.x = element_text(size = rel(1.1)), 
        axis.title.y = element_text(size = rel(1.4)), 
        axis.text.y = element_text(size = rel(1.1)))
dev.off()
