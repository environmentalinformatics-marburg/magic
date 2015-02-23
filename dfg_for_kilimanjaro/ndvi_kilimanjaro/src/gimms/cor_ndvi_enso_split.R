## oni ~ ndvi

# split raster
library(Rsenal)
fls_ndvi_wolndvi <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211_wolndvi.tif"
fls_ndvi_wolndvi_split <- paste0(dirname(fls_ndvi_wolndvi), "/ul/", 
                                 substr(basename(fls_ndvi_wolndvi), 1, nchar(basename(fls_ndvi_wolndvi))-4))
                                
rst_split <- splitRaster(fls_ndvi_wolndvi)

fls_split <- list.files("data/rst/whittaker/ul", pattern = "dwnscl_8211.*.tif$", 
                        full.names = TRUE)
fls_split <- fls_split[-grep("mk001", fls_split)]
rst_split <- lapply(fls_split, stack)

# average monthly ndvi
indices <- rep(1:12, nlayers(rst_split[[1]])/12)

num_split_ltm <- foreach(i = rst_split, j = list("0_0", "0_1", "1_0", "1_1"), 
                         quadrant = list("NW", "SW", "NE", "SE"), 
                         .combine = "rbind", .packages = lib) %dopar% {
#   rst <- stackApply(i, indices, fun = mean, 
#                     filename = paste0("data/rst/whittaker/ul/gimms_ndvi3g_dwnscl_8211_ltm_", j), 
#                     bylayer = FALSE, format = "GTiff", overwrite = TRUE)
  rst <- stack(paste0("data/rst/whittaker/ul/gimms_ndvi3g_dwnscl_8211_ltm_", j, ".tif"))
  mat <- as.matrix(rst)
  med <- apply(mat, 2, function(...) median(..., na.rm = TRUE))
  df_med <- data.frame(x = 1:12, y = med[c(7:12, 1:6)])
  
  ltm_ext <- merge(data.frame(x = 1:19), df_med, by = "x", all = TRUE)
  ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
  ltm_ext$quadrant <- quadrant
  return(ltm_ext)
}

# el nino
groups <- list("all El Ninos", "pure El Ninos", "pure m/s El Ninos", 
               "El Ninos w IOD+", "m/s El Ninos w IOD+", "purest IOD+")

groups_nino <- list(c("WE", "ME", "SE"),
                    c("WE", "ME", "SE"),
                    c("ME", "SE"), 
                    c("WE", "ME", "SE"), 
                    c("ME", "SE"), 
                    "WE")

groups_iod <- list(c("M", "", "P"), 
                   "", 
                   "", 
                   "P", 
                   "P", 
                   "P")

# nino <- groups_nino[[1]]
# iod <- groups_iod[[1]]
# group <- groups[[1]]
# span <- 8

ndvi_split_sp <- foreach(h = rst_split, quadrant = list("NW", "SW", "NE", "SE"), 
                         .combine = "rbind") %do% {
  ndvi_sp <- foreach(nino = groups_nino, iod = groups_iod, group = groups, 
                     span = rep(8, length(groups)), .packages = lib, 
                     .combine = "rbind") %dopar% {
                       oni_mlt_sub <- subset(oni_mlt, (Type %in% nino) & (IOD %in% iod))
                       
                       # remove incomplete data (e.g. late 2011)
                       seasons <- split(oni_mlt_sub, as.factor(oni_mlt_sub$Season))
                       seasons_len <- sapply(seasons, nrow)
                       seasons <- seasons[seasons_len == 12]
                       
                       oni_mlt_sub <- lapply(seasons, function(i) {
                         extentEnsoSeason(i, ndvi = h, span = span)
                       })
                       oni_mlt_sub <- do.call("rbind", oni_mlt_sub)
                       
                       sp <- smooth.spline(oni_mlt_sub$Month, oni_mlt_sub$NDVI, spar = .01)
                       sp_pred <- predict(sp, seq(1, nlevels(oni_mlt_sub$Month), .01))
                       
                       mat_sp_pred <- do.call("cbind", sp_pred)
                       df_sp_pred <- data.frame(group = group, mat_sp_pred)
                       #   df_sp_pred$x <- unique(oni_mlt_sub$Month)
                       
                       return(df_sp_pred)
                     }
  
  ndvi_sp$quadrant <- quadrant
  
  return(ndvi_sp)
}

ndvi_split_sp$quadrant <- factor(ndvi_split_sp$quadrant, 
                                 levels = c("NW", "NE", "SW", "SE"))

# ndvi_split_sp <- foreach(i = 1:4, quadrant = c("ul", "ll", "ur", "lr")) %do% {
#   ndvi_split_sp[[i]]$quadrant <- quadrant
#   return(ndvi_split_sp[[i]])
# }

red <- brewer.pal(4, "Reds")
blue <- brewer.pal(4, "Blues")

plot.colors <- c("black", blue[3], blue[4], red[3], red[4], "darkgreen")
names(plot.colors) <- groups

# df_med_ndvi_ltm$x <- factor(df_med_ndvi_ltm$x)
ltm_ext <- merge(data.frame(x = 1:19), df_med_ndvi_ltm, by = "x", 
                 all = TRUE)
ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
# ltm_ext$x <- as.numeric(as.character(ltm_ext[, 1]))

# x-axis labels
lbl <- rep(c(7:12, 1:6, 7:12, 1:2))
names(lbl) <- 1:(12+span)

# extend ltm
# df_med_ndvi_ltm$x <- factor(df_med_ndvi_ltm$x)
ltm_ext <- merge(data.frame(x = 1:20), df_med_ndvi_ltm, by = "x", 
                 all = TRUE)
ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
# ltm_ext$x <- as.numeric(as.character(ltm_ext[, 1]))

p_nino <- ggplot(aes(x, y, group = group, colour = group), data = ndvi_split_sp) + 
  geom_line() +
  geom_line(aes(x, y), data = num_split_ltm, colour = "grey65", linetype = 2) + 
  facet_wrap(~ quadrant, ncol = 2) + 
  scale_colour_manual("", values = plot.colors) + 
  #   scale_x_discrete("\nMonth", labels = lbl) + 
  scale_x_continuous("\nMonth", breaks = 1:(12+span), labels = lbl) + 
  labs(x = "\nMonth", y = expression(atop(NDVI[median], "\n"))) + 
  theme_bw()

png("vis/cor_ndvi_oni/ts_nino_ndvi_split.png", width = 36, height = 15, 
    units = "cm", pointsize = 18, res = 300)
print(p_nino)
dev.off()


# la nina
groups <- list("all La Ninas", "pure La Ninas", "pure m/s La Ninas", 
               "La Ninas w IOD+", "m/s La Ninas w IOD+", "purest IOD+")

groups_nina <- list(c("WL", "ML", "SL"),
                    c("WL", "ML", "SL"),
                    c("ML", "SL"), 
                    c("WL", "ML", "SL"), 
                    c("ML", "SL"), 
                    "WL")

groups_iod <- list(c("M", "", "P"), 
                   "", 
                   "", 
                   "P", 
                   "P", 
                   "P")

# nino <- groups_nino[[1]]
# iod <- groups_iod[[1]]
# group <- groups[[1]]
# span <- 8

ndvi_split_sp <- foreach(h = rst_split, quadrant = list("NW", "SW", "NE", "SE"), 
                         .combine = "rbind") %do% {
  ndvi_sp <- foreach(nina = groups_nina, iod = groups_iod, group = groups, 
                     span = rep(8, length(groups)), .packages = lib, 
                     .combine = "rbind") %dopar% {
    oni_mlt_sub <- subset(oni_mlt, (Type %in% nina) & (IOD %in% iod))
    
    # remove incomplete data (e.g. late 2011)
    seasons <- split(oni_mlt_sub, as.factor(oni_mlt_sub$Season))
    seasons_len <- sapply(seasons, nrow)
    seasons <- seasons[seasons_len == 12]
    
    oni_mlt_sub <- lapply(seasons, function(i) {
      extentEnsoSeason(i, ndvi = h, span = span)
    })
    oni_mlt_sub <- do.call("rbind", oni_mlt_sub)
    
    sp <- smooth.spline(oni_mlt_sub$Month, oni_mlt_sub$NDVI, spar = .01)
    sp_pred <- predict(sp, seq(1, nlevels(oni_mlt_sub$Month), .01))
    
    mat_sp_pred <- do.call("cbind", sp_pred)
    df_sp_pred <- data.frame(group = group, mat_sp_pred)
    #   df_sp_pred$x <- unique(oni_mlt_sub$Month)
    
    return(df_sp_pred)
  }
  
  ndvi_sp$quadrant <- quadrant
  
  return(ndvi_sp)
}

ndvi_split_sp$quadrant <- factor(ndvi_split_sp$quadrant, 
                                 levels = c("NW", "NE", "SW", "SE"))

# ndvi_split_sp <- foreach(i = 1:4, quadrant = c("ul", "ll", "ur", "lr")) %do% {
#   ndvi_split_sp[[i]]$quadrant <- quadrant
#   return(ndvi_split_sp[[i]])
# }

red <- brewer.pal(4, "Reds")
blue <- brewer.pal(4, "Blues")

plot.colors <- c("black", blue[3], blue[4], red[3], red[4], "darkgreen")
names(plot.colors) <- groups

# df_med_ndvi_ltm$x <- factor(df_med_ndvi_ltm$x)
ltm_ext <- merge(data.frame(x = 1:19), df_med_ndvi_ltm, by = "x", 
                 all = TRUE)
ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
# ltm_ext$x <- as.numeric(as.character(ltm_ext[, 1]))

# x-axis labels
lbl <- rep(c(7:12, 1:6, 7:12, 1:2))
names(lbl) <- 1:(12+span)

# extend ltm
# df_med_ndvi_ltm$x <- factor(df_med_ndvi_ltm$x)
ltm_ext <- merge(data.frame(x = 1:20), df_med_ndvi_ltm, by = "x", 
                 all = TRUE)
ltm_ext[is.na(ltm_ext$y), 2] <- ltm_ext[1:sum(is.na(ltm_ext$y)), 2]
# ltm_ext$x <- as.numeric(as.character(ltm_ext[, 1]))

p_nina <- ggplot(aes(x, y, group = group, colour = group), data = ndvi_split_sp) + 
  geom_line() +
  geom_line(aes(x, y), data = num_split_ltm, colour = "grey65", linetype = 2) + 
  facet_wrap(~ quadrant, ncol = 2) + 
  scale_colour_manual("", values = plot.colors) + 
  #   scale_x_discrete("\nMonth", labels = lbl) + 
  scale_x_continuous("\nMonth", breaks = 1:(12+span), labels = lbl) + 
  labs(x = "\nMonth", y = expression(atop(NDVI[median], "\n"))) + 
  theme_bw()

png("vis/cor_ndvi_oni/ts_nina_ndvi_split.png", width = 36, height = 15, 
    units = "cm", pointsize = 18, res = 300)
print(p_nina)
dev.off()
