library(MODIS)

MODISoptions(localArcPath = paste0(getwd(), "/data/MODIS_ARC/"), 
             outDirPath = paste0(getwd(), "/data/MODIS_ARC/PROCESSED/"))

template.ext.ll <- extent(37, 37.72, -3.4, -2.84)
template.rst.ll <- raster(ext = template.ext.ll)
template.rst.utm <- projectExtent(template.rst.ll, crs = "+init=epsg:21037")

runGdal("MCD12Q1", 
        tileH = 21, tileV = 9, SDSstring = paste0("1", rep("0", 15)), 
        outProj = "EPSG:21037", job = "mcd12q1_land_cover_type")

fls_lcp <- list.files("data/MODIS_ARC/PROCESSED/mcd12q1_land_cover_type/", 
                      pattern = "Land_Cover_Type_1.tif$", full.names = TRUE)
rst_lcp <- stack(fls_lcp)

rst_lcp_crp <- crop(rst_lcp, template.rst.utm)

# Occurring values
val_lcp_crp <- lapply(1:nlayers(rst_lcp_crp), function(i) {
  tmp_val <- getValues(rst_lcp_crp[[i]])
  return(unique(tmp_val))
})
val_lcp_crp <- do.call(function(...) sort(unique(c(...))), val_lcp_crp)

# Reclassification matrix
mat_rcl <- matrix(c(0, 0, 0, 
                    1, 5, 1,    # forest
                    6, 7, 6,    # shrublands
                    8, 9, 8,    # savanna
                    10, 10, 10, # grasslands
                    11, 11, 11, # wetlands
                    12, 12, 12, # croplands
                    13, 13, 13, # urban and built-up
                    14, 14, 14, # cropland, natural vegetation mosaic
                    15, 15, 15, # snow and ice
                    16, 16, 16), # barren or sparsely vegetated
                  byrow = TRUE, ncol = 3)

rst_lcp_crp_rcl <- reclassify(rst_lcp_crp, mat_rcl, right = FALSE)
