diffMonths <- function(x) {
  stopifnot(require(zoo))
  
  int_diff_yrmn <- sapply(2:length(x), function(i) {
    x_yrmn <- as.yearmon(x[i])
    x_yrmn_m1 <- as.yearmon(x[i-1])
    
    (x_yrmn - x_yrmn_m1) * 12
  })
  
  round(mean(int_diff_yrmn), 1)
}

# kili plots
ch_dir_crd <- "/media/permanent/kilimanjaro/coordinates/coords"
ch_fls_crd <- "PlotPoles_ARC1960_mod_20140807_final"

shp_plt <- readOGR(ch_dir_crd, ch_fls_crd)
shp_plt <- subset(shp_plt, PoleType == "AMP")
shp_plt <- subset(shp_plt, PlotID != "gra0")

# available files
ch_dir_plt <- list.files("preprocessed", include.dirs = TRUE, full.names = TRUE)
ch_plt <- basename(ch_dir_plt)
id_plt <- ch_plt %in% shp_plt@data$PlotID
ch_dir_plt <- ch_dir_plt[id_plt]
ch_plt <- basename(ch_dir_plt)

ls_reprate <- lapply(ch_dir_plt, function(h) {
  tmp_ch_fls <- list.files(h)
  
  # logger
  ls_logger <- strsplit(tmp_ch_fls, "___")
  ch_logger <- sapply(ls_logger, "[[", 1)
  ls_logger <- strsplit(ch_logger, "_")
  ch_logger <- sapply(ls_logger, "[[", 2)
  
  # identify logger with longest record, and take it as reference
  tbl_logger <- table(ch_logger)
  id_logger_max <- which.max(tbl_logger)
  ch_logger_max <- names(tbl_logger)[id_logger_max]
  tmp_ch_fls <- tmp_ch_fls[grep(ch_logger_max, tmp_ch_fls)]
  
  # end date
  ls_dates <- strsplit(tmp_ch_fls, "___")
  ch_dates <- sapply(ls_dates, "[[", 2)
  ls_dates <- strsplit(ch_dates, "__")
  ch_dates <- sapply(ls_dates, "[[", 1)
  ch_dates <- sort(ch_dates)
  dt_dates <- as.Date(ch_dates, format = "%Y_%m_%d")
  dt_dates <- unique(dt_dates)

  # mean visiting cycle in month
  dt_dates_diff_mu <- diffMonths(dt_dates)
  df_dates_diff_mu <- data.frame(logger_ref = ch_logger_max, 
                                 rep_rate = dt_dates_diff_mu)
  return(df_dates_diff_mu)
})
df_reprate <- do.call("rbind", ls_reprate)
df_reprate <- data.frame(PlotID = ch_plt, df_reprate)

write.csv(df_reprate, "jn__repeating_rate.csv", row.names = FALSE, 
          quote = FALSE)
