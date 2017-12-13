fireDates <- function(x, verbose = FALSE) {
  lapply(x, function(i) {
    nfo <- if (verbose) {
      rgdal::GDALinfo(i, returnScaleOffset = FALSE)
    } else {
      suppressWarnings(rgdal::GDALinfo(i, returnScaleOffset = FALSE,
                                       silent = TRUE)) 
    }
    mtd <- attr(nfo, "mdata")
    dts <- mtd[grep("Dates", mtd)]
    dts <- gsub("Dates=", "", dts)
    unlist(strsplit(dts, " "))
  })
}