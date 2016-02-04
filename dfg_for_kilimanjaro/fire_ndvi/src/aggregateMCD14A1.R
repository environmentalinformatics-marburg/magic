aggregateMCD14A1 <- function(st_year, 
                             nd_year, 
                             n = "month",
                             indir = ".", 
                             outdir = ".",
                             pos1 = 22, 
                             pos2 = 28,
                             ...) {
  
  stopifnot(require(raster))
  
  ### Data import
  
  ## MODIS fire
  
  # Import daily reclassified fire files
  fire.fls <- list.files(indir, full.names = TRUE, ...)
  
  # Limit time window 
  st <- grep(st_year, fire.fls)[1]
  nd <- grep(nd_year, fire.fls)[length(grep(nd_year, fire.fls))]
  fire.fls <- fire.fls[st:nd]
  
  # Import reclassified fire data
  fire_rst <- stack(fire.fls)
  
  # Aggregate months
  if (n == "month") {
    dates <- as.Date(substr(basename(fire.fls), pos1, pos2), format = "%Y%j")
    months <- strftime(dates, format = "%Y%m")
    indices <- as.numeric(as.factor(months))
    
    fire_rst_agg <- stackApply(fire_rst, indices = indices, fun = sum, 
                               filename = paste0(outdir, "/aggsum"), 
                               bylayer = TRUE, suffix = paste0("md14a1_", unique(months)), 
                               format = "GTiff", overwrite = TRUE)
    
  } else {
    # Aggregate 8-day intervals
    source("src/kifiAggData.R")
    
    dates <- as.Date(substr(basename(fire.fls), pos1, pos2), format = "%Y%j")
    st_date <- as.Date(paste0(st_year, "-01-01"))
    nd_date <- as.Date(paste0(nd_year, "-12-31"))
    seq_dates <- seq(st_date, nd_date, "day")
    
    df_seq_dates <- merge(data.frame(seq_dates), data.frame(dates, fire.fls), 
                          all.x = TRUE, by = 1)
    
    fire_rst_agg <- kifiAggData(data = df_seq_dates, 
                                n = n,
                                years = st_year:nd_year, 
                                dsn = outdir, 
                                out.str = "aggsum_8day_md14a1", 
                                format = "GTiff", overwrite = TRUE)
    
  }
  
  return(fire_rst_agg)
}