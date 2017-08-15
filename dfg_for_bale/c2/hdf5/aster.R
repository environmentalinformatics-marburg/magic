library(raster)

ast = list.files("/home/fdetsch/Downloads/", pattern = "^AST.*.tif$", full.names = TRUE)
ast = lapply(ast, raster)

setMethod('merge', signature(x = 'list', y = 'missing'), 
          function(x, y, tolerance = 0.05, filename = "", ...) {
            
            args <- x
            args$tolerance <- tolerance
            args$filename <- filename
            
            ## additional arguments
            dots <- list(...)
            args <- append(args, dots)
            
            ## perform merge
            do.call(raster::merge, args)
          })

mrg = merge(ast)

ref = spTransform(ext, CRS("+init=epsg:4326"))
ref = rgeos::gBuffer(ref, width = .01, quadsegs = 100L)
crp = crop(mrg, ref)
prj = crop(projectRaster(crp, crs = proj4string(ext)), ext, snap = "out")

prj = writeRaster(prj, "/media/fdetsch/XChange/bale/dem/ASTGTM2_N0xE0xx_dem.tif", 
                  datatype = "INT2S")
