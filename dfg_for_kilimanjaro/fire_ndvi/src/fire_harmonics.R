lib <- c("raster", "zoo", "ggplot2", "doParallel", "RColorBrewer", "rgeos")
sapply(lib, function(x) library(x, character.only = TRUE))

setwd("/media/envin/XChange/kilimanjaro/ndvi/")

source("src/multiVectorHarmonics.R")

fls_agg1m <- list.files("data/md14a1/low/aggregated", pattern = "^aggsum_md14a1", 
                        full.names = TRUE)
rst_agg1m <- stack(fls_agg1m)

# Overall observed active fire pixels per month between 2001 and 2013
val_sum <- sapply(1:nlayers(rst_agg1m), function(i) {
  sum(rst_agg1m[[i]][], na.rm = TRUE)
})

months <- sapply(strsplit(basename(fls_agg1m), "_"), "[[", 3)
months <- substr(months, 5, 6)

val_sum_agg <- aggregate(val_sum, by = list(months), FUN = sum)
names(val_sum_agg) <- c("month", "value")
val_sum_agg$month <- factor(month.abb, levels = month.abb)

ggplot(aes(x = month, y = value), data = val_sum_agg) + 
  geom_histogram(stat = "identity") + 
  labs(x = "\nMonth", y = "No. of active fires\n") + 
  theme_bw()

# Observed active fire pixels per month 2001-05 vs. 2009-13
yrmn <- sapply(strsplit(basename(fls_agg1m), "_"), "[[", 3)
yrmn <- substr(yrmn, 1, 6)

harm_0105_0913 <- multiVectorHarmonics(rst_agg1m, time_info = yrmn, 
                                       intervals = c(2001, 2009), width = 5)
ggplot(aes(x = month, y = value, group = interval, colour = interval, 
           fill = interval), data = harm_0105_0913) + 
  #   geom_line() + 
  geom_histogram(stat = "identity", position = "dodge") + 
  labs(x = "\nMonth", y = "No. of active fires\n") +
  scale_colour_manual("", values = c("black", "grey65")) + 
  scale_fill_manual("", values = c("black", "grey65")) + 
  theme_bw()

# Same issue, but for 2001-04 vs. 2004-07 vs. 2007-10 vs. 2010-13
harm_0104_0407_0710_1013 <- multiVectorHarmonics(rst_agg1m, time_info = yrmn, 
                                                 intervals = seq(2001, 2010, 3), 
                                                 width = 4)

ggplot(aes(x = month, y = value, group = interval, colour = interval), 
       data = harm_0104_0407_0710_1013) + 
  geom_line(lwd = 2) + 
  labs(x = "\nMonth", y = "No. of active fires\n") +
  scale_colour_manual("", values = brewer.pal(4, "Reds")) + 
  theme_bw()

# # Separate fires inside the NP from fires outside the NP
# np_old <- readOGR(dsn = "data/protected_areas/", 
#                   layer = "fdetsch-kilimanjaro-national-park-1420535670531", 
#                   p4s = "+init=epsg:4326")
# np_old_utm <- spTransform(np_old, CRS("+init=epsg:21037"))
# 
# np_new <- readOGR(dsn = "data/protected_areas/", 
#                   layer = "fdetsch-kilimanjaro-1420532792846", 
#                   p4s = "+init=epsg:4326")
# np_new_utm <- spTransform(np_new, CRS("+init=epsg:21037"))
# np_new_utm_lines <- as(np_new_utm, "SpatialLines")
# 
# rst_agg1m_inside <- mask(rst_agg1m, np_new_utm)
# rst_agg1m_outside <- mask(rst_agg1m, np_new_utm, inverse = TRUE)
# 
# harm_0104_0613_inside <- multiVectorHarmonics(rst_agg1m_inside, time_info = yrmn, 
#                                               intervals = c(2001, 2006, 2010), width = 4)
# harm_0104_0613_inside$location <- "inside"
# harm_0104_0613_outside <- multiVectorHarmonics(rst_agg1m_outside, time_info = yrmn, 
#                                               intervals = c(2001, 2006, 2010), width = 4)
# harm_0104_0613_outside$location <- "outside"
# 
# harm_0104_0613_inside_outside <- 
#   rbind(harm_0104_0613_inside, harm_0104_0613_outside)
# 
# ggplot(aes(x = month, y = value, group = interval, colour = interval, 
#            fill = interval), data = harm_0104_0613_inside_outside) + 
#   geom_histogram(stat = "identity", position = "dodge") + 
#   facet_wrap(~location, ncol = 1) + 
#   labs(x = "\nMonth", y = "No. of active fires\n") +
#   scale_colour_manual("", values = c("grey75", "grey45", "black")) +   
#   scale_fill_manual("", values = c("grey75", "grey45", "black")) + 
#   theme_bw()

# Same issue, but with rejection of cells intersected by NP border
id_intersect <- foreach(i =1:ncell(rst_agg1m), .packages = lib, 
                        .combine = "c") %dopar% {
  rst <- rst_agg1m[[1]]
  rst[][-i] <- NA
  shp <- rasterToPolygons(rst)
  return(gIntersects(np_new_utm_lines, shp))
}

rst_agg1m_rmb <- rst_agg1m
rst_agg1m_rmb[id_intersect] <- NA

rst_agg1m_rmb_inside <- mask(rst_agg1m_rmb, np_new_utm)
rst_agg1m_rmb_outside <- mask(rst_agg1m_rmb, np_new_utm, inverse = TRUE)

harm_before_after_rmb_inside <- multiVectorHarmonics(rst_agg1m_rmb_inside, time_info = yrmn, 
                                              intervals = c(2001, 2006, 2010), width = 4)
harm_before_after_rmb_inside$location <- "inside"
harm_before_after_rmb_outside <- multiVectorHarmonics(rst_agg1m_rmb_outside, time_info = yrmn, 
                                               intervals = c(2001, 2006, 2010), width = 4)
harm_before_after_rmb_outside$location <- "outside"

harm_before_after_rmb_inside_outside <- 
  rbind(harm_before_after_rmb_inside, harm_before_after_rmb_outside)

ggplot(aes(x = month, y = value, group = interval, colour = interval, 
           fill = interval), data = harm_before_after_rmb_inside_outside) + 
  geom_histogram(stat = "identity", position = "dodge") + 
  facet_wrap(~location, ncol = 1) + 
  labs(x = "\nMonth", y = "No. of active fires\n") +
  scale_colour_manual("", values = c("grey75", "grey45", "black")) +   
  scale_fill_manual("", values = c("grey75", "grey45", "black")) + 
  theme_bw()
