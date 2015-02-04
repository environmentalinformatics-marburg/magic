# packages
library(GSODTools)
library(ggplot2)
library(bfast)

# gsod data
data(gsodstations)

bfast_prcp <- lapply(c("JOMO KENYATTA INTL", "MAKINDU"), function(i) {
  gsod_sub <- gsodstations[gsodstations$STATION.NAME == i, ]
  gsod_nai <- dlGsodStations(usaf = gsod_sub$USAF, start_year = 1982, end_year = 2011, 
                             dsn = "data/gsod", unzip = TRUE, rm_gz = TRUE)
  
  # inches to mm conversion
  gsod_nai$PRCP <- gsod_nai$PRCP * 25.4
  
  # monthly aggregation
  prcp_nai_mnth <- aggregate(gsod_nai$PRCP, FUN = function(...) sum(..., na.rm = TRUE),
                             by = list(substr(gsod_nai$YEARMODA, 1, 6)))
  names(prcp_nai_mnth)[1] <- "YEARMODA"
  prcp_nai_mnth[, 1] <- paste0(prcp_nai_mnth[, 1], 01)
  prcp_nai_mnth[, 1] <- as.Date(prcp_nai_mnth[, 1], format = "%Y%m%d")
  
  # # visualization
  # ggplot(aes(x = YEARMODA, y = x), data = prcp_nai_mnth) + 
  #   geom_histogram(stat = "identity") + 
  #   labs(x = "\nTime (months)", y = "Precipitation (mm)") + 
  #   theme_bw()
  
  # lm, bfast
  ts_prcp_nai <- ts(prcp_nai_mnth$x, start = c(1982, 1), end = c(2011, 12), 
                    frequency = 12)
  lm_prcp_nai <- tslm(ts_prcp_nai ~ trend + season)
  
  bfast_prcp_nai <- bfast(ts_prcp_nai, max.iter = 10, season = "harmonic", hpc = "foreach")
  
  return(list(lm_prcp_nai, bfast_prcp_nai))
})