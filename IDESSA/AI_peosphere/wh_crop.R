# crop distance in each direction around each center point
# tile: aerial image to crop
# centers: center points (aka waterholes)
# distance: crop distance in each direction (for a 3km square choose 1500)
# outdir: directory for the output files

wh_crop <- function(tile, centers, distance, outdir){
  
  library(raster)
  crops <- lapply(seq(length(centers)), function(i){
    
    crop(tile, c(coords$coords.x1[i]-distance,
                 coords$coords.x1[i]+distance,
                 coords$coords.x2[i]-distance,
                 coords$coords.x2[i]+distance),
         filename = paste0(outdir, "tile_", i, ".tif"), overwrite = TRUE)
    return(crops)
  })
  return(crops)
}