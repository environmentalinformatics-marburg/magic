library(latticeExtra)
library(zoo)
library(Rsenal)
library(gridExtra)

Sys.setenv(TZ='UTC')
setwd("/media/HDEXTENSION/kili_precip/")

#source("/home/ede/software/Rpckgdev/Rsenal/R/vectorHaromics.R")

kia.prcp <- read.csv("kia_prcp_1975_2012_mnthly.csv",
                     stringsAsFactors = FALSE)
moshi.prcp <- read.csv("moshi_precip_1950_1990.csv",
                       stringsAsFactors = FALSE)
names(moshi.prcp) <- c("Date", "P_RT_NRT")
nai.prcp <- read.csv("nairobi_prcp_1975_2012_mnthly.csv",
                     stringsAsFactors = FALSE)

kia.prcp$Date <- as.Date(kia.prcp$year)
moshi.prcp$Date <- as.Date(moshi.prcp$Date)
nai.prcp$Date <- as.Date(nai.prcp$year)

### kia has only 11 months in 1975
kia.prcp <- subset(kia.prcp, Date >= as.Date("1976-01-01",
                                             origin = "1976-01-01"))
nai.prcp <- subset(nai.prcp, Date >= as.Date("1976-01-01",
                                             origin = "1976-01-01"))

station.lst <- list(kia.prcp = kia.prcp, 
                    moshi.prcp = moshi.prcp, 
                    nai.prcp = nai.prcp)

names <- c("Kilimanjaro Airport", "Moshi", "Nairobi")

harm.plots <- lapply(seq(station.lst), function(i) {

  tmp.prcp.st <- subset(station.lst[[i]], Date >= as.Date(station.lst[[i]]$Date[1], 
                                           origin = station.lst[[i]]$Date[1]) & 
                          Date < as.Date(station.lst[[i]]$Date[1] + 365 * 6, 
                                         origin = station.lst[[i]]$Date[1] + 365 * 6))
  
  strt.st <- c(as.numeric(substr(tmp.prcp.st$Date[1], 1, 4)), 01)
  end.st <- c(as.numeric(substr(tmp.prcp.st$Date[nrow(tmp.prcp.st)], 1, 4)), 12)
  harm.st <- vectorHarmonics(tmp.prcp.st$P_RT_NRT, frq = 12, fun = median,
                             st = strt.st, nd = end.st, m = 2)
  harm.st[harm.st < 0] <- 0
  
  tmp.prcp.mid1 <- subset(station.lst[[i]], Date >= as.Date("1976-01-01", 
                                                            origin = "1976-01-01") & 
                            Date < as.Date("1982-01-01", 
                                           origin = "1976-01-01"))
  strt.mid1 <- c(as.numeric(substr(tmp.prcp.mid1$Date[1], 1, 4)), 01)
  end.mid1 <- c(as.numeric(substr(tmp.prcp.mid1$Date[nrow(tmp.prcp.mid1)], 1, 4)), 12)
  harm.mid1 <- vectorHarmonics(tmp.prcp.mid1$P_RT_NRT, frq = 12, fun = median,
                             st = strt.mid1, nd = end.mid1, m = 2)
  harm.mid1[harm.mid1 < 0] <- 0
  
  tmp.prcp.mid2 <- subset(station.lst[[i]], Date >= as.Date("1984-01-01", 
                                                            origin = "1985-01-01") & 
                            Date < as.Date("1990-01-01", 
                                           origin = "1985-01-01"))
  strt.mid2 <- c(as.numeric(substr(tmp.prcp.mid2$Date[1], 1, 4)), 01)
  end.mid2 <- c(as.numeric(substr(tmp.prcp.mid2$Date[nrow(tmp.prcp.mid2)], 1, 4)), 12)
  harm.mid2 <- vectorHarmonics(tmp.prcp.mid2$P_RT_NRT, frq = 12, fun = median,
                               st = strt.mid2, nd = end.mid2, m = 2)
  harm.mid2[harm.mid2 < 0] <- 0
  
  if(identical(harm.st, harm.mid1)) {
    harm.mid <- harm.mid2 
    mid.date <- paste(strt.mid2[1], end.mid2[1], sep = " - ")
  } else {
    harm.mid <- harm.mid1
    mid.date <- paste(strt.mid1[1], end.mid1[1], sep = " - ")
  }
  print(mid.date)
  
  tmp.prcp.end <- subset(station.lst[[i]], 
                         Date >= as.Date(station.lst[[i]]$Date[nrow(station.lst[[i]])] - 365 * 6, 
                                         origin = station.lst[[i]]$Date[nrow(station.lst[[i]])] - 365 * 6))
  
  strt.end <- c(as.numeric(substr(tmp.prcp.end$Date[1], 1, 4)), 01)
  end.end <- c(as.numeric(substr(tmp.prcp.end$Date[nrow(tmp.prcp.st)], 1, 4)), 12)
  harm.end <- vectorHarmonics(tmp.prcp.end$P_RT_NRT, frq = 12, fun = median,
                             st = strt.end, nd = end.end, m = 2)
  harm.end[harm.end < 0] <- 0

  mx <- max(c(harm.st, harm.end, harm.mid)) * 1.1
  
  key.txt <- list(c(paste(strt.st[1], end.st[1], sep = " - "),
                    mid.date,
                    paste(strt.end[1], end.end[1], sep = " - ")))
  
  st.plot <- xyplot(harm.st ~ seq(harm.st), type = "l", asp = 1/3,
                    lty = 2, xlab = "Month", main = names[i],
                    ylab = "Precipitation [mm]", ylim = c(-10, mx),
                    key = list(x = 0.2, y = 0.1, corner = c(0, 0), 
                               lines = list(lty = c(2, 2, 1), 
                                            col = c("cornflowerblue", 
                                                    "grey", "red2")), 
                               text = key.txt))
  
  mid.plot <- xyplot(harm.mid ~ seq(harm.mid), type = "l", 
                     col = "grey", lty = 2)

  end.plot <- xyplot(harm.end ~ seq(harm.end), type = "l", 
                     col = "red2", lty = 1)
  
  st.plot + as.layer(mid.plot) + as.layer(end.plot)
  
})

f <- function(...) grid.arrange(..., heights = 1, ncol = 1)

png("precip_seasonal_shifts.png", width = 25, height = 30, 
    units = "cm", res = 300)
do.call(f, harm.plots)   #Final plot
dev.off()

#   #########################
# mnths.7579 <- data.frame(year = seq(as.Date("1975-01-01", 
#                                                origin = "1970-01-01"),
#                                     as.Date("1979-12-01", 
#                                                origin = "1970-01-01"),
#                                     by = "months"))
# kia.prcp.8084 <- subset(kia.prcp, year >= as.Date("1980-01-01", 
#                                                   origin = "1970-01-01") & 
#                                 year < as.Date("1985-01-01", 
#                                                    origin = "1970-01-01"))
# 
# kia.prcp.0812 <- subset(kia.prcp, year >= as.Date("2008-01-01", 
#                                                  origin = "1970-01-01"))
# 
# ### create median seasonal curves and calculate area under the curve
# tst.0812 <- vectorHarmonics(kia.prcp.0812$P_RT_NRT, frq = 12, fun = median,
#                             st = c(2008, 01), nd = c(2012, 12), m = 2)
# tst.0812[tst.0812 < 0] <- 0
# id.0812 <- order(tst.0812)
# auc.0812 <- sum(diff(seq(tst.0812))*rollmean(tst.0812,2))
# 
# tst.8084 <- vectorHarmonics(kia.prcp.8084$P_RT_NRT, frq = 12, fun = median,
#                             st = c(1980, 01), nd = c(1984, 12), m = 2)
# tst.8084[tst.8084 < 0] <- 0
# id.8084 <- order(tst.8084)
# auc.8084 <- sum(diff(seq(tst.8084))*rollmean(tst.8084,2))
# 
# st.plot <- xyplot(tst.8084 ~ seq(tst.8084), type = "l", asp = 1/3,
#                   ylim = c(-10, 110), lty = 2, xlab = "Month", 
#                   ylab = "Precipitation [mm]", 
#                   key = list(x = .02, y = .8, corner = c(0, 0), 
#                              lines = list(lty = c(2, 1), 
#                                           col = c("cornflowerblue", "red2")), 
#                              text = list(c("1980 - 1984", "2008 - 2012"))))
# 
# end.plot <- xyplot(tst.0812 ~ seq(tst.0812), type = "l", 
#                    col = "red2", lty = 1)
# 
# png("kia_precip_seasonal_shifts.png", width = 20, height = 10, 
#     units = "cm", res = 300)
# st.plot + as.layer(end.plot)
# dev.off()
