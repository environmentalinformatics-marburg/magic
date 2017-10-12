library(ESD)

shp <- list.files("data/shapefiles", pattern = "^poly.*polygon.*.shp", 
                  full.names = TRUE)

gms <- download("GIMMS", 
                dsn = "/media/XChange/exploratories/data/rasters/ndvi3g.v1/")

for (i in 1:2) {
  gms_ppc <- preprocess("GIMMS", gms, cores = 3L, keep = 0, # keep 'good' values only
                        ext = readRDS(system.file("extdata/alb.rds", package = "ESD")), 
                        lambda = 500, 
                        outDirPath = "data/rasters/alb/NDVI3g.v1/")
}

lst <- foreach(pattern = c("yL2", "yL500", "yL5000"), .packages = "raster") %dopar% {
  fls <- list.files("data/rasters/alb/NDVI3g.v1", full.names = TRUE, 
                    pattern = paste0(pattern, ".ndvi"))
  as.numeric(stack(fls)[5])
}

rst <- rasterizeGimms(gms, ext = readRDS(system.file("extdata/alb.rds", package = "ESD")), 
                      keep = 0, cores = 3L)
val <- as.numeric(rst[5])
plot(val, type = "l", col = "grey30")
library(RColorBrewer)
clr <- brewer.pal(3, "Set3")
for (i in 1:3)
  lines(lst[[i]], col = "green")
