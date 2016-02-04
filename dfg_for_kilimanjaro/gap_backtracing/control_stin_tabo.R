library(gdata)
library(ggplot2)

switch(Sys.info()[["sysname"]], 
       "Linux" = setwd("/media/permanent/kilimanjaro/gap_control/"), 
       "Windows" = setwd("C:/Permanent/kilimanjaro/gap_control/"))

stin <- read.xls("station_inventory_2014-11-15.xlsx")[, 5:10]
tabo <- read.xls("task_book_red_2014-11-15.xlsx", 
                 stringsAsFactors = FALSE)[, c(3:8, 10:11)]

current_plot <- "nkw1"
subset(stin, PLOTID == current_plot)

tmp_tabo <- tabo[grep(ifelse(current_plot == "emg0", "emg", current_plot), tabo[, 1]), ]
log_substr <- substr(tmp_tabo$LOGGER, nchar(tmp_tabo$LOGGER)-2, nchar(tmp_tabo$LOGGER))
tmp_tabo[log_substr == "pu2", ]
# subset(tmp_tabo, LOGGER == "rad")
# subset(tmp_tabo, SERIAL == "80081025287")

# logger not visualized
logger_id <- "80081025282"
logger_path <- paste0("preprocessed/", current_plot)

logger_fls <- list.files(logger_path, pattern = logger_id, full.names = TRUE)

logger_ls <- lapply(logger_fls, function(i) read.table(i, skip = 5, header = FALSE, 
                                                       sep = "\t"))
logger_df <- do.call("rbind", logger_ls)
logger_df$datetime <- paste(logger_df[, 1], logger_df[, 2])
logger_df$datetime <- strptime(logger_df$datetime, format = "%d.%m.%y %H:%M:%S")

ggplot(aes(x = datetime, y = V3), data = logger_df) + 
  geom_line()
