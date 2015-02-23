ensoNdvi2sp <- function(enso_date, span = 7,
                        ndvi, ndvi_date = NULL, 
                        fun = mean, 
                        ...) {
  
  stopifnot(require(Rsenal))
  
  enso_start <- enso_date
  enso_end <- enso_date
  month(enso_end) <- month(enso_end) + span
  
  if (!is.null(ndvi_date)) {
    ndvi_enso_id <- ndvi_date >= enso_start & ndvi_date <= enso_end
    ndvi_enso <- ndvi[[which(ndvi_enso_id)]]
  } else {
    ndvi_enso <- ndvi
  }
  
  rst_nino_agg <- calc(ndvi_enso, fun = fun)
  spp_nino_agg <- spplot(rst_nino_agg, ...)
  emp_nino_agg <- envinmrRasterPlot(spp_nino_agg)
  
  return(emp_nino_agg)
}