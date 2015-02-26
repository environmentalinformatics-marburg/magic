importOni <- function(file = "data/oni/enso_and_iod.csv") {
  stopifnot(require(reshape2))
  
  oni <- read.csv(file, skip = 1, stringsAsFactors = FALSE)
  oni$Season <- paste0(oni[, 3], oni[, 4], oni[, 5])
  oni <- oni[, -(4:5)]
  month_num <- formatC(c(7:12, 1:6), width = 2, flag = "0")
  names(oni)[4:ncol(oni)] <- month_num
  oni_mlt <- melt(oni, id.vars = 1:3, variable.name = "Month", value.name = "ONI")
  
  years <- strsplit(oni_mlt$Season, "-")
  oni_mlt$Year1 <- sapply(years, "[[", 1)
  oni_mlt$Year2 <- sapply(years, "[[", 2)
  oni_mlt$Year <- ifelse(as.numeric(as.character(oni_mlt$Month)) %in% 1:6, 
                         oni_mlt$Year2, oni_mlt$Year1)
  dates <- paste(oni_mlt$Year, oni_mlt$Month, "01", sep = "-")
  oni_mlt$Date <- as.Date(dates)
  oni_mlt <- oni_mlt[order(oni_mlt$Date), ]
  
  id_st <- grep(st, oni_mlt$Date)
  id_nd <- grep(nd, oni_mlt$Date)
  oni_mlt <- oni_mlt[id_st:id_nd, c("Date", "Season", "ONI", "Type", "IOD")]
  
  return(oni_mlt)
}
