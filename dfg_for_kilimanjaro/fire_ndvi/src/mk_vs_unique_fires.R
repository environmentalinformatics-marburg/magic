lib <- c("raster", "rgdal", "Kendall", "doParallel", "OpenStreetMap", "ggplot2")
sapply(lib, function(x) library(x, character.only = TRUE))

source("src/uniqueFires.R")
source("src/uniqueFiresKendall.R")

registerDoParallel(cl <- makeCluster(4))

# osm data
bng <- kiliAerial(minNumTiles = 20)

# modis ndvi mk data
fls_ndvi_mk <- "out/mk/myd13q1_mk001_0313.tif"
rst_ndvi_mk <- raster(fls_ndvi_mk)

# 1-km ndvi mk data
fls_1km_mk <- "../gimms3g/gimms3g/data/rst/whittaker/gimms_ndvi3g_dwnscl_8211_mk001.tif"
rst_1km_mk <- raster(fls_1km_mk)

# monthly fire data
fls_agg1m <- list.files("data/md14a1/low/aggregated", pattern = "^aggsum_md14a1", 
                        full.names = TRUE)
rst_agg1m <- stack(fls_agg1m)

# dates
fire_months <- substr(basename(fls_agg1m), 15, 20)
fire_years <- substr(fire_months, 1, 4)

# unique fire cells
unique_fires <- uniqueFires(rst_agg1m, n_cores = 3)
unique_fires$month <- fire_months[unique_fires$id]
unique_fires$year <- fire_years[unique_fires$id]

unique_fires_0305 <- subset(unique_fires, year %in% 2003:2006)
unique_fires_1113 <- subset(unique_fires, year %in% 2010:2013)

unique_fires_1012 <- subset(unique_fires, year %in% 2010:2012)
unique_fires_0212 <- subset(unique_fires, year %in% 2002:2012)
unique_fires_0211 <- subset(unique_fires, year %in% 2002:2011)

# modis masks for 2003-05, 2011-13 (both Aqua), 2010-12, 2002-12 (both 1-km)
ls_mk <- foreach(i = list(unique_fires_0305, unique_fires_1113, 
                          unique_fires_1012, unique_fires_0212), 
                 j = list("2003-2006", "2010-2013", "2010-2012", "2002-2012"), 
                 k = list(rst_ndvi_mk, rst_ndvi_mk, rst_1km_mk, rst_1km_mk),
                 .packages = lib) %dopar% {
  uniqueFiresKendall(template = rst_agg1m[[1]], 
                     cell_id = i$cell, 
                     time_stamp = i$month,
                     rst = k, period = j,
                     fun = function(x) {
                       if (all(is.na(x))) NA else mean(x, na.rm = TRUE)
                     })
}

# rst_tmp <- rst_agg1m[[1]]
# rst_tmp[] <- NA
# 
# rst_tmp_0305 <- rst_tmp
# rst_tmp_0305[unique_fires_0305$cell] <- 1
# shp_tmp_0305 <- rasterToPolygons(rst_tmp_0305)  
# 
# rst_tmp_1113 <- rst_tmp
# rst_tmp_1113[unique_fires_1113$cell] <- 1
# shp_tmp_1113 <- rasterToPolygons(rst_tmp_1113)  
# 
# rst_tmp_1012 <- rst_tmp
# rst_tmp_1012[unique_fires_1012$cell] <- 1
# shp_tmp_1012 <- rasterToPolygons(rst_tmp_1012)  
# 
# rst_tmp_0212 <- rst_tmp
# rst_tmp_0212[unique_fires_0212$cell] <- 1
# shp_tmp_0212 <- rasterToPolygons(rst_tmp_0212)  
# 
# # mk value extraction
# ls_mk_0305 <- extract(rst_ndvi_mk, shp_tmp_0305, fun = function(...) {
#   if (all(is.na(...))) return(NA) else return(mean(..., na.rm = TRUE))
# })
# val_mk_0305 <- if (is.list(ls_mk_0305)) do.call("c", ls_mk_0305) else as.numeric(ls_mk_0305)
# df_mk_0305 <- data.frame(period = "2003-2005", ndvi_mk = val_mk_0305)
# 
# ls_mk_1113 <- extract(rst_ndvi_mk, shp_tmp_1113, fun = function(...) {
#   if (all(is.na(...))) return(NA) else return(mean(..., na.rm = TRUE))
# })
# val_mk_1113 <- if (is.list(ls_mk_1113)) do.call("c", ls_mk_1113) else as.numeric(ls_mk_1113)
# df_mk_1113 <- data.frame(period = "2011-2013", ndvi_mk = val_mk_1113)
# 
# df_mk_0305_1113 <- rbind(df_mk_0305, df_mk_1113)

# visualization
p_mk_0306_1013 <- ggplot(aes(x = period, y = ndvi_mk), data = df_mk_0306_1013) + 
  geom_boxplot(fill = "grey75") + 
  geom_hline(aes(y = 0), col = "grey10", linetype = "dashed") + 
  labs(x = "", y = expression("Kendall's" ~ tau)) + 
  theme_bw() + 
  theme(axis.text.x = element_text(size = 15, face = "bold"), 
        axis.title.y = element_text(size = 15))

png("out/fire/burnt_ndvi_mk_0306_1013.png", width = 12, height = 25, units = "cm", 
    pointsize = 18, res = 300)
print(p_mk_0306_1013)
dev.off()

library(dplyr)
df_mk_0306_1013 %>% 
  group_by(period) %>%
  summarise(median(ndvi_mk, na.rm = TRUE))

# # 1-km mk value extraction
# ls_1km_1012 <- extract(rst_1km_mk, shp_tmp_1012)
# val_1km_1012 <- if (is.list(ls_1km_1012)) do.call("c", ls_1km_1012) else as.numeric(ls_1km_1012)
# df_1km_1012 <- data.frame(period = "2011-2013", ndvi_mk = val_1km_1012)
# 
# ls_1km_0212 <- extract(rst_1km_mk, shp_tmp_0212)
# val_1km_0212 <- if (is.list(ls_1km_0212)) do.call("c", ls_1km_0212) else as.numeric(ls_1km_0212)
# df_1km_0212 <- data.frame(period = "2011-2013", ndvi_mk = val_1km_0212)

df_mk_0306_1013 <- do.call("rbind", ls_mk[1:2])


# mk 2002-2012 vs. mk 1982-2001
fls_1km <- "../gimms3g/gimms3g/data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_1km <- stack(fls_1km)

st <- as.Date("1982-01-01")
nd <- as.Date("2011-12-01")
st_nd <- seq(st, nd, "month")

# rst_1km_8201 <- rst_1km[[1:grep("2001-12-01", st_nd)]]
# rst_1km_8201_mk <- overlay(rst_1km_8201, fun = function(x) {
#   mk <- MannKendall(x)
#   tau <- mk$tau
#   sl <- mk$sl
#   tau[sl >= .01] <- NA
#   return(tau)
# }, filename = "../gimms3g/gimms3g/data/rst/whittaker/gimms_ndvi3g_dwnscl_8201_mk01.tif", 
# overwrite = TRUE, format = "GTiff")
fls_1km_8201_mk <- "../gimms3g/gimms3g/data/rst/whittaker/gimms_ndvi3g_dwnscl_8201_mk001.tif"
rst_1km_8201_mk <- raster(fls_1km_8201_mk)

# rst_1km_0211 <- rst_1km[[grep("2002-01-01", st_nd):(grep("2011-12-01", st_nd))]]
# rst_1km_0211_mk <- overlay(rst_1km_0211, fun = function(x) {
#   mk <- MannKendall(x)
#   tau <- mk$tau
#   sl <- mk$sl
#   tau[sl >= .01] <- NA
#   return(tau)
# }, filename = "../gimms3g/gimms3g/data/rst/whittaker/gimms_ndvi3g_dwnscl_0211_mk01.tif", 
# overwrite = TRUE, format = "GTiff")
fls_1km_0211_mk <- "../gimms3g/gimms3g/data/rst/whittaker/gimms_ndvi3g_dwnscl_0211_mk001.tif"
rst_1km_0211_mk <- raster(fls_1km_0211_mk)

df_8201 <- uniqueFiresKendall(template = rst_agg1m[[1]], 
                              cell_id = unique_fires_0211$cell, 
                              time_stamp = unique_fires_0211$month,
                              rst = rst_1km_8201_mk, period = "1982-2001",
                              fun = function(x) {
                                if (all(is.na(x))) NA else mean(x, na.rm = TRUE)
                              })

df_0211 <- uniqueFiresKendall(template = rst_agg1m[[1]], 
                              cell_id = unique_fires_0211$cell, 
                              time_stamp = unique_fires_0211$month,
                              rst = rst_1km_0211_mk, period = "2002-2011",
                              fun = function(x) {
                                if (all(is.na(x))) NA else mean(x, na.rm = TRUE)
                              })

df_8201_0211 <- rbind(df_8201, df_0211)

p_mk_8201_0211 <- ggplot(aes(x = period, y = ndvi_mk, group = period), 
                         data = df_8201_0211) + 
  geom_boxplot(fill = "grey75") + 
  geom_hline(aes(y = 0), col = "grey10", linetype = "dashed") + 
  labs(x = "", y = expression("Kendall's" ~ tau)) + 
  theme_bw() + 
  theme(axis.text.x = element_text(size = 15, face = "bold"), 
        axis.title.y = element_text(size = 15))

png("out/fire/burnt_ndvi_mk_8201_0211.png", width = 12, height = 18, units = "cm", 
    pointsize = 18, res = 300)
print(p_mk_8201_0211)
dev.off()

# period 2002-12 from entire gimms 1-km time frame mk
df_0212 <- ls_mk[[4]]

id_pos <- which(df_0212[, 4] > 0)
df_0212_pos <- df_0212[id_pos, ]
rst_0212_pos <- rst_agg1m[[1]]
rst_0212_pos[] <- NA
rst_0212_pos[df_0212_pos$cell] <- 1
shp_0212_pos <- rasterToPolygons(rst_0212_pos)
shp_0212_pos@data$id <- rownames(shp_0212_pos@data)
shp_0212_pos_points <- fortify(shp_0212_pos, region = "id")

id_neg <- which(df_0212[, 4] < 0)
df_0212_neg <- df_0212[id_neg, ]
rst_0212_neg <- rst_agg1m[[1]]
rst_0212_neg[] <- NA
rst_0212_neg[df_0212_neg$cell] <- 1
shp_0212_neg <- rasterToPolygons(rst_0212_neg)
shp_0212_neg@data$id <- rownames(shp_0212_neg@data)
shp_0212_neg_points <- fortify(shp_0212_neg, region = "id")

id_cc <- complete.cases(df_0212)
df_0212 <- df_0212[id_cc, ]
df_0212$sign <- ifelse(df_0212[, 4] > 0, "pos", "neg")

# autoplot(bng) + 
#   geom_polygon(aes(long, lat, group = group), data = shp_0212_pos, 
#                col = "red", fill = "transparent") + 
#   geom_polygon(aes(long, lat, group = group), data = shp_0212_neg, 
#                col = "blue", fill = "transparent")
# 
# ggplot(df_0212, aes(x = as.numeric(as.character(month)), group = sign, 
#                     colour = sign)) + 
#   geom_density()

p_mk_0212 <- ggplot(aes(x = period, y = ndvi_mk), data = df_0212) + 
  geom_boxplot(fill = "grey75") + 
  geom_hline(aes(y = 0), col = "grey10", linetype = "dashed") + 
  labs(x = "", y = expression("Kendall's" ~ tau)) + 
  theme_bw() + 
  theme(axis.text.x = element_text(size = 15, face = "bold"), 
        axis.title.y = element_text(size = 15))

png("out/fire/burnt_ndvi_mk_0212.png", width = 6, height = 18, units = "cm", 
    pointsize = 18, res = 300)
print(p_mk_0212)
dev.off()

median(df_0212$ndvi_mk, na.rm = TRUE)
