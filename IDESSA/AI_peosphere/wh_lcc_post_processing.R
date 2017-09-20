library(raster)


leg <- read.csv("F:/Uni/env_info/lcc_legend.csv", sep = ";", header = TRUE)
fls <- list.files("F:/Uni/env_info/output", full.names = TRUE, pattern = ".tif$")


for(i in seq(1,20)){
  
  rst <- raster(fls[i])
  rst[rst == leg$field[i]] <- 10
  rst[rst == leg$veg[i]] <- 40
  rst[rst == leg$other1[i]] <- 20
  if(!is.na(leg$other2[i])){rst[rst == leg$other2[i]] <- 30}
  writeRaster(rst, filename = paste0("F:/Uni/env_info/reclass/lcc_reclass_", leg$tile[i], ".tif"))
  print(i)
}



