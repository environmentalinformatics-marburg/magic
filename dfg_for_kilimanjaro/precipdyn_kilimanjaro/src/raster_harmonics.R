library(TSA)
library(latticeExtra)
library(raster)
library(Rsenal)

path <- "/media/tims_ex/kilimanjaro_ndvi_harmonics"
setwd(path)

#source("cellHarmonics.R")

files <- list.files("/media/tims_ex/reot_ndvi_dwnsc/gimms_dwnscld_ndvi_82_06_250m", 
                    pattern = glob2rx("*epsg21*"), full.names = TRUE)
ndvi.stck.utm <- stack(files)

recl_mat <- cbind(NA, -2)

strt <- ndvi.stck.utm[[1:(12*6)]]
strt_recl <- reclassify(strt, recl_mat)
end <- ndvi.stck.utm[[(nlayers(ndvi.stck.utm) - (12*6) + 1):nlayers(ndvi.stck.utm)]]
end_recl <- reclassify(end, recl_mat)

# ext_crop <- extent(c(300000, 310000, 9640000, 9650000))
# strt_recl <- crop(strt_recl, ext_crop)
# end_recl <- crop(end_recl, ext_crop)

strt_vals <- strt_recl[]
end_vals <- end_recl[]

### calculate start and end harmonics
strt_harm <- lapply(seq(nrow(strt_vals)), function(i) {
  vectorHarmonics(x = strt_vals[i, ], frq = 12, 
                  st = c(1982, 01), nd = c(1987, 12))
})

end_harm <- lapply(seq(nrow(end_vals)), function(i) {
  vectorHarmonics(x = end_vals[i, ], frq = 12, 
                  st = c(2001, 01), nd = c(2006, 12))
})

### calculate pixel values
## difference in amplitude
delta_amp <- sapply(seq(strt_harm), function(i) {
  diff(range(end_harm[[i]])) - diff(range(strt_harm[[i]]))
})

## difference in month of max value
delta_max <- sapply(seq(strt_harm), function(i) {
  st <- which(strt_harm[[i]] == max(strt_harm[[i]]))[1]
  nd <- which(end_harm[[i]] == max(end_harm[[i]]))[1]
  if ((nd - st) < -6) {
    tmp <- (nd - st) + 12
  } else if ((nd - st) > 6) {
    tmp <- (nd - st) - 12
  } else {
    tmp <- (nd - st)
  }
  return(tmp)
})

## difference in month of min value
delta_min <- sapply(seq(strt_harm), function(i) {
  st <- which(strt_harm[[i]] == min(strt_harm[[i]]))
  nd <- which(end_harm[[i]] == min(end_harm[[i]]))
  if ((nd - st) < -6) {
    tmp <- (nd - st) + 12
  } else if ((nd - st) > 6) {
    tmp <- (nd - st) - 12
  } else {
    tmp <- (nd - st)
  }
  return(tmp)
})

## difference in mean
delta_mean <- sapply(seq(strt_harm), function(i) {
  mean(end_harm[[i]]) - mean(strt_harm[[i]])
})

## max value start
max_strt <- sapply(seq(strt_harm), function(i) {
  max(strt_harm[[i]])
})

## max value end
max_end <- sapply(seq(strt_harm), function(i) {
  max(end_harm[[i]])
})

## template
rst_amp <- rst_min <- rst_max <- rst_mean <- 
  rst_max_strt <- rst_max_end <- strt_recl[[1]]

## assign values to templates
rst_amp[] <- delta_amp
rst_min[] <- delta_min
rst_max[] <- delta_max
rst_mean[] <- delta_mean
rst_max_strt[] <- max_strt
rst_max_end[] <- max_end

## color definitions
clrs_ndvi <- colorRampPalette(brewer.pal(9, "BrBG"))
clrs_mnths <- colorRampPalette(brewer.pal(9, "RdBu"))

## plots
p_max <- spplot(rst_max, col.regions = clrs_mnths(13),
                at = seq(-6.5, 6.5, 1), 
                colorkey = list(space = "top", 
                                height = 0.75, width = 1))
p_min <- spplot(rst_min, col.regions = clrs_mnths(13),
                at = seq(-6.5, 6.5, 1))
p_amp <- spplot(rst_amp, col.regions = clrs_ndvi(1000), 
                at = seq(-0.15, 0.15, 0.001))
p_mean <- spplot(rst_mean, col.regions = clrs_ndvi(1000), 
                 at = seq(-0.15, 0.15, 0.001))
p_max_strt <- spplot(rst_max_strt, col.regions = clrs_ndvi(1000), 
                     at = seq(0, 1, 0.01))
p_max_end <- spplot(rst_max_end, col.regions = clrs_ndvi(1000), 
                    at = seq(0, 1, 0.01))

plots <- list(p_max, p_min, p_amp, p_mean)

outLayout <- function(x, y) {
  update(c(x, y, layout = c(2, 2)),
         between = list(x = 0.3, y = 0.3))
}

out <- Reduce(outLayout, plots)
out
