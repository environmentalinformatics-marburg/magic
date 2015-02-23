# ls_rst_cor_lag <- lapply(-6:6, function(lag) {
#   rst_cor_lag3 <- calc(rst_ndvi_anom, function(x) {
#     if (all(is.na(x))) {
#       return(NA)
#     } else {
#       if (lag > 0) {
#         r <- cor(lag(oni_mlt$ONI, lag), x, use = "complete.obs")
#         mod <- lm(x ~ lag(oni_mlt$ONI, lag))
#         p <- summary(mod)$coefficients[2, 4]
#         if (p >= .001) return(NA) else return(r)
#       } else {
#         r <- cor(lag(x, abs(lag)), oni_mlt$ONI, use = "complete.obs")
#         mod <- lm(oni_mlt$ONI ~ lag(x, abs(lag)))
#         p <- summary(mod)$coefficients[2, 4]
#         if (p >= .001) return(NA) else return(r)
#       }
#     }}, filename = paste0("data/rst/cor_ndvi_enso/cor_oni_ndvi_lag", lag),
#     format = "GTiff", overwrite = TRUE)
# })
# rst_cor_lag <- stack(ls_rst_cor_lag)

fls_rst_cor_lag <- list.files("data/rst/cor_ndvi_enso", pattern = "^cor_oni_ndvi_lag", 
                              full.names = TRUE)
order_id <- substr(basename(fls_rst_cor_lag), 1, nchar(basename(fls_rst_cor_lag))-4)
order_id <- sapply(strsplit(order_id, "lag"), "[[", 2)
order_id <- as.numeric(order_id)
fls_rst_cor_lag <- fls_rst_cor_lag[order(order_id)]
rst_cor_lag <- stack(fls_rst_cor_lag)

spplot(rst_cor_lag[[c(1:6, 8:13)]], at = seq(-.55, .55, .1), 
       col.regions = colorRampPalette(brewer.pal(11, "BrBG")))


# dmi
# ls_rst_cor_dmi_lag <- lapply(-6:6, function(lag) {
#   rst_cor_lag3 <- calc(rst_ndvi_anom, function(x) {
#     x <- x[1:length(dat_dmi$DMI)]
#     if (all(is.na(x))) {
#       return(NA)
#     } else {
#       if (lag > 0) {
#         r <- cor(lag(dat_dmi$DMI, lag), x, use = "complete.obs")
#         mod <- lm(x ~ lag(dat_dmi$DMI, lag))
#         p <- summary(mod)$coefficients[2, 4]
#         if (p >= .001) return(NA) else return(r)
#         return(r)
#       } else {
#         r <- cor(lag(x, abs(lag)), dat_dmi$DMI, use = "complete.obs")
#         mod <- lm(dat_dmi$DMI ~ lag(x, abs(lag)))
#         p <- summary(mod)$coefficients[2, 4]
#         if (p >= .001) return(NA) else return(r)
#       }
#     }}, filename = paste0("data/rst/cor_ndvi_enso/cor_dmi_ndvi_lag", lag),
#     format = "GTiff", overwrite = TRUE)
# })
# rst_cor_dmi_lag <- stack(ls_rst_cor_dmi_lag)

fls_rst_cor_dmi_lag <- list.files("data/rst/cor_ndvi_enso", pattern = "^cor_dmi_ndvi_lag", 
                              full.names = TRUE)
order_id <- substr(basename(fls_rst_cor_dmi_lag), 1, nchar(basename(fls_rst_cor_dmi_lag))-4)
order_id <- sapply(strsplit(order_id, "lag"), "[[", 2)
order_id <- as.numeric(order_id)
fls_rst_cor_dmi_lag <- fls_rst_cor_dmi_lag[order(order_id)]
rst_cor_dmi_lag <- stack(fls_rst_cor_dmi_lag)

spplot(rst_cor_dmi_lag[[c(1:6, 8:13)]], at = seq(-.45, .45, .1), 
       col.regions = colorRampPalette(brewer.pal(11, "BrBG")))
