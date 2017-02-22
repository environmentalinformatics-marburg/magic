### environmental stuff -----

## working directory
setwd(switch(Sys.info()[["sysname"]], 
             "Linux" = "/media/permanent/xchange/tnauss", 
             "Windows" = "E:/xchange/tnauss"))

## packages and functions
lib <- c("raster", "rgdal", "TSA", "RColorBrewer")
Orcs::loadPkgs(lib)

source("R/cellHarmonics.R")
source("R/ndviPhaseShift.R")


### data processing: seasonality -----

## Data import


# 1-km GIMMS NDVI data (1982-2011)
fls_ndvi <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_ndvi <- stack(fls_ndvi)


# Temporal subsetting
st_year <- 1982
nd_year <- 2011
n_years <- 15
n_months <- n_years * 12

rst.st <- rst_ndvi[[1:n_months]]
rst.nd <- rst_ndvi[[(nlayers(rst_ndvi)-n_months+1):nlayers(rst_ndvi)]]

rst.har <-  cellHarmonics(st = rst.st, 
                          nd = rst.nd, 
                          st.start = c(st_year, 1), st.end = c(st_year+n_years-1, 12), 
                          nd.start = c(nd_year-n_years+1, 1), nd.end = c(nd_year, 12), 
                          product = "GIMMS", 
                          path.out = "data/rst/harmonic_8296_9711", n.cores = 3)

# Start variance (maximum - minimum)
st_diff_max_min <- rst.har[[1]][[2]]-rst.har[[1]][[4]]

# End variance (maximum - minimum)
nd_diff_max_min <- rst.har[[2]][[2]]-rst.har[[2]][[4]]

# Shift in maximum NDVI
diff_max_y <- overlay(rst.har[[1]][[2]], rst.har[[2]][[2]], fun = function(x, y) {
  return(y - x)
})

# Shift in minimum NDVI
diff_min_y <- overlay(rst.har[[1]][[4]], rst.har[[2]][[4]], fun = function(x, y) {
  return(y - x)
})

# Shift in months regarding NDVI maximum
diff_max_x <- overlay(rst.har[[1]][[1]], rst.har[[2]][[1]], 
                      st_diff_max_min, nd_diff_max_min,
                      fun = function(x, y, z_max, z_min) 
                        ndviPhaseShift(x, y, z_max, z_min, 
                                       rejectLowVariance = TRUE, 
                                       varThreshold = .04))

cols_div <- colorRampPalette(brewer.pal(5, "BrBG"))
p_diff_max_x <- 
  spplot(diff_max_x, col.regions = cols_div(100), scales = list(draw = TRUE), 
         xlab = "x", ylab = "y", at = seq(-2.5, 2.5, 1),
         sp.layout = list("sp.lines", rasterToContour(dem), col = "grey65"))
# png("out/harmonic/harmonic_modis_diff_max_x_0306_1013.png", width = 20, 
#     height = 17.5, units = "cm", pointsize = 15, res = 300)
# print(p_diff_max_x)
# dev.off()

# Shift in months regarding NDVI minimum
diff_min_x <- overlay(rst.har[[1]][[3]], rst.har[[2]][[3]], 
                      st_diff_max_min, nd_diff_max_min, 
                      fun = function(x, y, z_max, z_min) 
                        ndviPhaseShift(x, y, z_max, z_min, 
                                       rejectLowVariance = TRUE, 
                                       varThreshold = .04))

p_diff_min_x <- 
  spplot(diff_min_x, col.regions = cols_div(100), scales = list(draw = TRUE), 
         xlab = "x", ylab = "y", at = seq(-2.5, 2.5, 1),
         sp.layout = list("sp.lines", rasterToContour(dem), col = "grey65"))


foreach(i = list(diff_max_x, diff_min_x, diff_max_y, diff_min_y), 
        j = list("diff_max_x", "diff_min_x", "diff_max_y", "diff_min_y")) %do% 
  writeRaster(i, paste0("data/rst/harmonic_8296_9711/", j), format = "GTiff", overwrite = TRUE)

### Visualization

# hcl colorspace
df_hcl <- data.frame(cell = 1:ncell(diff_max_x), 
                     h = 90 + diff_max_x[] * 10, 
                     c = 50, # increasing chroma with higher values
                     l = 50 + diff_max_y[] * 100) # decreasing luminance with higher values

for (i in c(3, 4)) {
  if (any(df_hcl[, i] < 0))
    df_hcl[which(df_hcl[, i] < 0), i] <- 0
}

df_hcl_cc <- df_hcl[complete.cases(df_hcl), ]

template <- rasterToPolygons(diff_max_x)
plot(template, col = hcl(h = df_hcl_cc[, 2], c = df_hcl_cc[, 3], l = df_hcl_cc[, 4]), 
     border = "transparent")

