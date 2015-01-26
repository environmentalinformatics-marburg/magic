# dem
dem <- raster("data/DEM_ARC1960_30m_Hemp.tif")

# mk data
mod_predicted_mk <- list.files("data/rst/whittaker", pattern = "mk", 
                               full.names = TRUE)[4:1]
mod_predicted_mk <- lapply(mod_predicted_mk, raster)


dem_rsmpl <- resample(dem, mod_predicted_mk[[4]])

tmp <- mod_predicted_mk[[4]]
tmp[which(dem_rsmpl[] < 3500)] <- NA

kendallStats(tmp)

overlay(mod_predicted_mk[[4]], dem_rsmpl)