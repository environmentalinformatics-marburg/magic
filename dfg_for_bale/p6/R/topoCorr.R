### environmental stuff -----

## clear workspace
rm(list = ls(all = TRUE))

## packages
lib <- c("parallel", "rgdal", "satellite", "RStoolbox")
Orcs::loadPkgs(lib)

## temporary raster folder
rasterOptions(tmpdir = "../../tmp")
jnk <- tmpDir()

## working directory
setwd("../../data/bale/DigitalGlobeFoundation/ImageryGrant")

## parallelization
cl <- makePSOCKcluster(0.75 * detectCores())
clusterExport(cl, "lib"); jnk <- clusterEvalQ(cl, Orcs::loadPkgs(lib))


### processing -----

## union extent of worldview-1 images required for aster data download
drs <- dir("arcsidata/Raw", full.names = TRUE)
drs <- drs[grep("PAN$", drs)]

# pys <- do.call("bind", lapply(drs, function(i) {
#   fls <- list.files(i, pattern = ".TIF$", full.names = TRUE)
#   do.call("bind", lapply(fls, function(j) {
#     rst <- raster(j)
#     spy <- as(extent(rst), "SpatialPolygons")
#     proj4string(spy) <- projection(rst)
#     return(spy)
#   }))
# }))
# 
# spy <- as(extent(pys), "SpatialPolygons"); proj4string(spy) <- proj4string(pys)
# spy <- SpatialPolygonsDataFrame(spy, data = data.frame(ID = 1))
# writeOGR(spy, "shp", "extent", "ESRI Shapefile")
spy <- readOGR("shp", "extent", verbose = FALSE)

## slope and aspect from aster dem
# dms <- list.files("dem/ASTER", pattern = "dem.tif$", recursive = TRUE,
#                   full.names = TRUE)
# dms <- do.call("merge", lapply(dms, raster))
# dms <- crop(dms, spTransform(spy, CRS(projection(dms))), snap = "out")
# dms <- trim(projectRaster(dms, crs = proj4string(spy)), datatype = "INT2U",
#             filename = "dem/ASTER/ASTGTM2_N0XE039", format = "GTiff")
dms <- raster("dem/ASTER/ASTGTM2_N0XE039.tif")
# trr <- lapply(c("slope", "aspect"), function(opt) terrain(dms, opt))
# clusterExport(cl, "trr")
clusterExport(cl, "dms")

## hillshade and topographic correction of worldview-1 images
getWVSunEle <- function(x) {
  require(magrittr)
  x %>%
    xml2::xml_find_all("///MEANSUNEL") %>%
    xml2::xml_text() %>%
    as.numeric()
}

getWVSunAzi <- function(x) {
  require(magrittr)
  x %>%
    xml2::xml_find_all("///MEANSUNAZ") %>%
    xml2::xml_text() %>%
    as.numeric()
}

topocorr <- vector("list", length(drs)); n <- 1L
for (i in drs) {
  
  ## status message
  cat("Image", basename(i), "is in, start processing...\n")
  
  ## list available files, retrieve sun elevation and azimuth angle 
  fls <- list.files(i, pattern = ".TIF$", full.names = TRUE)
  mtd <- xml2::read_xml(list.files(i, pattern = ".XML$", full.names = TRUE))
  sel <- getWVSunEle(mtd); szn <- getWVSunAzi(mtd) 
  clusterExport(cl, c("sel", "szn"))
  
  ## loop over available files
  out <- parLapply(cl, fls, function(j) {
    # nms <- paste0("dem/ASTER/", gsub("P001.TIF", "P001_HLSH.tif", basename(j)))
    nms_dem <- paste0("dem/ASTER/", gsub(".TIF$", "_ELEV.tif", basename(j)))
    nms_slp <- paste0("dem/ASTER/", gsub(".TIF$", "_SLOP.tif", basename(j)))
    nms_asp <- paste0("dem/ASTER/", gsub(".TIF$", "_ASPE.tif", basename(j)))
    
    if (file.exists(nms_slp) & file.exists(nms_asp)) {
      # rsm <- raster(nms); na <- FALSE
      trr <- stack(nms_slp, nms_asp); names(trr) <- c("slope", "aspect"); na <- FALSE
    } else {
      rst <- raster(j); rst[rst[] == 0] <- NA; rst <- trim(rst); na <- TRUE
      # lst <- stack(lapply(trr, function(k) crop(k, rst, snap = "out")))
      # hsd <- hillShade(lst[[1]], lst[[2]], sel, szn); rm(lst)
      # tmp <- resample(hsd, rst) 
      # rsm <- writeRaster(tmp, nms) 
      # jnk <- attr(tmp@file, "name"); rm(tmp) 
      # if (nchar(jnk) > 0) { 
      #   file.remove(jnk); file.remove(gsub("grd$", "gri", jnk))
      # }

      # import or resample dem      
      if (file.exists(nms_dem)) {
        dem <- raster(nms_dem)
      } else {
        tmp <- resample(dms, rst)
        dem <- writeRaster(tmp, filename = nms_dem)
        jnk <- attr(tmp@file, "name"); rm(tmp) 
        if (nchar(jnk) > 0) {
          file.remove(jnk); file.remove(gsub("grd$", "gri", jnk))
        }
      }
      
      # calculate slope and aspect
      trr <- stack(lapply(1:2, function(opt) {
        nms <- ifelse(opt == 1, nms_slp, nms_asp)
        if (file.exists(nms)) {
          raster(nms)
        } else {
          terrain(dem, ifelse(opt == 1, "slope", "aspect"), filename = nms)
        }
      })); names(trr) <- c("slope", "aspect")
      
      # trr <- writeRaster(tmp, filename = nms_trr); names(trr) <- c("slope", "aspect")
      # jnk <- try(attr(tmp@file, "name"), silent = TRUE); rm(tmp) 
      # if (!inherits(jnk, "try-error")) {
      #   if (nchar(jnk) > 0)
      #     file.remove(jnk); file.remove(gsub("grd$", "gri", jnk))
      # }
    }
    
    nms_tpc <- gsub(".TIF$", "_TOPO-2.tif", j)
    tpc <- if (file.exists(nms_tpc)) {
      raster(nms_tpc) 
    } else { 
      if (!na) { rst <- raster(j); rst[rst[] == 0] <- NA; rst <- trim(rst) }
      # tpc <- calcTopoCorr(rst, rsm, filename = nms_tpc, datatype = "INT2U")
      topCor(rst, trr, solarAngles = c(szn, (90 - sel)) * pi / 180, 
             filename = nms_tpc, datatype = "INT2U")
    }
     
    return(tpc) 
  })
  
  ## create image mosaic from orthorectified images
  nms_mrg <- list.files(i, pattern = ".XML$", full.names = TRUE)
  nms_mrg <- gsub(".XML$", "_TOPO-2.tif", nms_mrg)
  
  mrg <- if (file.exists(nms_mrg)) {
    raster(nms_mrg)
  } else {
    do.call(function(...) merge(..., filename = nms_mrg), out)
  }; rm(out)
  
  tmp <- list.files(tmpDir(FALSE), full.names = TRUE); jnk <- file.remove(tmp)
  topocorr[[n]] <- mrg; n <- n + 1L
}

## close parallel backend
stopCluster(cl)
