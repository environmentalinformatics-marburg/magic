# packages
library(GSODTools)
library(Rsenal)
library(reshape2)
library(foreach)
library(ggplot2)

# start and end
st <- "1982-01"
nd <- "2011-12"

# metoffice data
prcp_kia_moshi <- read.table("data/metoffice_1973-2013.csv", sep = " ", 
                             header = TRUE)
prcp_kia_moshi[, 1] <- as.Date(prcp_kia_moshi[, 1])

id_st <- grep(st, prcp_kia_moshi[, 1])
id_nd <- grep(nd, prcp_kia_moshi[, 1])
prcp_kia_moshi <- prcp_kia_moshi[id_st:id_nd, ]

harm_prcp_sth <- lapply(c(6), function(i) {
  tmp_harm_prcp <- foreach(j = c(1982), k = c(2011), 
                           .combine = "rbind") %do% {
  
  tmp_id_st <- grep(paste0(j, "-01"), prcp_kia_moshi[, 1])
  tmp_id_nd <- grep(paste0(k, "-01"), prcp_kia_moshi[, 1])
                             
  x <- vectorHarmonics(prcp_kia_moshi[tmp_id_st:tmp_id_nd, i], st = c(j, 1), nd = c(k, 12))
  df_x <- data.frame(station = i, 
                     period = paste(j, k, sep = "-"), 
                     month = month.abb, x)
  
  return(df_x)
}})
harm_prcp_sth <- do.call("rbind", harm_prcp_sth)
harm_prcp_sth$station <- "mean(KIA, Moshi)"

# gsod data
data(gsodstations)

harm_prcp_nth <- lapply(c("JOMO KENYATTA INTL", "MAKINDU"), function(i) {
  tmp_harm_prcp <- foreach(j = c(1982), k = c(2011), 
                           .combine = "rbind") %do% {
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
    
    # seasonality
    tmp_id_st <- grep(paste0(j, "-01"), prcp_nai_mnth[, 1])
    tmp_id_nd <- grep(paste0(k, "-01"), prcp_nai_mnth[, 1])
    
    x <- vectorHarmonics(prcp_nai_mnth[tmp_id_st:tmp_id_nd, 2], 
                         st = c(j, 1), nd = c(k, 12))
    df_x <- data.frame(station = i, 
                       period = paste(j, k, sep = "-"), 
                       month = month.abb, x)
    return(df_x)
  }
})
harm_prcp_nth <- do.call("rbind", harm_prcp_nth)

# merge data
harm_prcp <- rbind(harm_prcp_nth, harm_prcp_sth)
harm_prcp$month <- factor(harm_prcp$month, levels = month.abb)

# df_harm_prcp <- data.frame(station = c("Nairobi", "Makindu", 
#                                        "Kilimanjaro Intl. Airport", "Moshi", 
#                                        "mean(KIA, Moshi)"), 
#                            harm_prcp)
# names(df_harm_prcp)[2:ncol(df_harm_prcp)] <- month.abb

# # reformat data
# mlt_harm_prcp <- melt(df_harm_prcp, id.vars = 1, variable.name = "month")

# visualize
ggplot(aes(x = month, y = x, group = station, colour = station), data = harm_prcp) + 
  geom_line(lwd = 1.5) + 
  scale_colour_manual("", values = brewer.pal(3, "Dark2")) + 
  labs(x = "\nMonth", y = "Precipitation (mm)\n") + 
  theme_bw()

ggplot(aes(x = month, y = x, group = period, linetype = period), data = harm_prcp) + 
  geom_line(lwd = 1.5) + 
  facet_wrap(~ station, ncol = 1) + 
  labs(x = "\nMonth", y = "Precipitation (mm)\n") + 
  theme_bw()
