# packages
library(GSODTools)
library(Rsenal)
library(foreach)
library(ggplot2)

# start and end
st <- "1982-01"
nd <- "2011-12"

st_date <- as.Date(paste0(st, "-01"))
nd_date <- as.Date(paste0(nd, "-01"))
seq_dates <- seq(st_date, nd_date, "month")
df_dates <- data.frame(seq_dates)

st_intervals <- c(1982, 1992, 2002)
nd_intervals <- c(1991, 2001, 2011)

# metoffice data
prcp_kia_moshi <- read.table("data/metoffice_1973-2013.csv", sep = " ", 
                             header = TRUE)
prcp_kia_moshi[, 1] <- as.Date(prcp_kia_moshi[, 1])

id_st <- grep(st, prcp_kia_moshi[, 1])
id_nd <- grep(nd, prcp_kia_moshi[, 1])
prcp_kia_moshi <- prcp_kia_moshi[id_st:id_nd, ]

harm_prcp_sth <- lapply(c(6), function(i) {
  tmp_harm_prcp <- foreach(j = st_intervals, k = nd_intervals, 
                           .combine = "rbind") %do% {
                             
    tmp_id_st <- grep(paste0(j, "-01"), prcp_kia_moshi[, 1])
    tmp_id_nd <- grep(paste0(k, "-01"), prcp_kia_moshi[, 1])
    
    x <- vectorHarmonics(prcp_kia_moshi[tmp_id_st:tmp_id_nd, i], st = c(j, 1), nd = c(k, 12))
    df_x <- data.frame(station = "mean(KIA, Moshi)",
#       station = ifelse(i == 2, "Kilimanjaro Intl. Airport", "Moshi"),
                                        period = paste(j, k, sep = "-"), 
                                        month = month.abb, x)
                       
    return(df_x)
  }})
harm_prcp_sth <- do.call("rbind", harm_prcp_sth)

# gsod data
data(gsodstations)

harm_prcp_nth <- lapply(c("JOMO KENYATTA INTL", "MAKINDU"), function(i) {
  tmp_harm_prcp <- foreach(j = st_intervals, k = nd_intervals, 
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
    
    # continuous ts
    prcp_nai_mnth <- merge(df_dates, prcp_nai_mnth, by = 1, all.x = TRUE)
    
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
  
  if (i == "MAKINDU")
    tmp_harm_prcp <- subset(tmp_harm_prcp, period != "2002-2011")
  
  return(tmp_harm_prcp)
})
harm_prcp_nth <- do.call("rbind", harm_prcp_nth)

# merge data
harm_prcp <- rbind(harm_prcp_nth, harm_prcp_sth)
harm_prcp$month <- factor(harm_prcp$month, levels = month.abb)

# visualize
levels(harm_prcp[, 1]) <- c("Jomo Kenyatta Intl. Airport, Nairobi, Kenya", 
                            "Makindu, Kenya", 
                            "Southern Kilimanjaro region, Tanzania")

cols_qual <- brewer.pal(7, "Set3")[c(7, 1, 3)]

p <- ggplot(aes(x = month, y = x, group = period, colour = period), data = harm_prcp) + 
  geom_line(lwd = 1.5) + 
  facet_wrap(~ station, ncol = 1) + 
  labs(x = "\nMonth", y = "Precipitation (mm)\n") + 
  scale_colour_manual("", values = cols_qual) + 
  theme_bw() + 
  theme(legend.position = c(1, .55), legend.justification = c(1, 1))

png("vis/prcp/prcp_harm__8291_9201_0211.png", width = 22, height = 24, 
    units = "cm", pointsize = 18, res = 300)
print(p)
dev.off()
