# packages
library(lubridate)
library(doParallel)
library(RColorBrewer)
library(Rsenal)

source("ensoNdvi2sp.R")

oni_mlt <- oni_mlt[id_st:id_nd, c("Date", "ONI")]

dates <- oni_mlt$Date


## el nino

dates_nino <- c("1982-09-01", "1987-09-01", "1997-09-01", "2009-09-01")
dates_nino <- as.Date(dates_nino)
dates_nina <- c("1983-09-01", "1988-09-01", "1998-09-01", "2010-09-01")
dates_nina <- as.Date(dates_nina)

cols_div <- colorRampPalette(brewer.pal(11, "RdYlGn"))

# integrated ndvi
ls_emp <- foreach(nino = dates_nino, nina = dates_nina, .combine = "append") %do% {
  
  lapply(c(nino, nina), function(i) {
    lbl1 <- substr(i, 1, 4)
    lbl1 <- as.numeric(lbl1)
    lbl2 <- lbl1+1
    lbl2 <- substr(lbl2, 3, 4)
    lbl <- paste(lbl1, lbl2, sep = "/")
    
    ensoNdvi2sp(enso_date = i, span = 11,
                ndvi = rst_ndvi, ndvi_date = dates, 
                fun = sum, col.regions = cols_div(100), 
                # at = seq(-75, 75, 10),
                at = 2:11,
                scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                sp.layout = list("sp.text", c(350000, 9625000), lbl, 
                                 font = "bold", cex = 1.2))
  })
 
}

# merge plots
p_emp <- latticeCombineGrid(ls_emp, layout = c(2, 4))

png("vis/cor_ndvi_oni/map_ndvi_enso.png", width = 20, height = 35, units = "cm", 
    pointsize = 18, res = 600)
print(p_emp)
dev.off()

# integrated ndvi, deseasoned
ls_emp_dsn <- foreach(nino = dates_nino, nina = dates_nina, .combine = "append") %do% {
  
  lapply(c(nino, nina), function(i) {
    lbl1 <- substr(i, 1, 4)
    lbl1 <- as.numeric(lbl1)
    lbl2 <- lbl1+1
    lbl2 <- substr(lbl2, 3, 4)
    lbl <- paste(lbl1, lbl2, sep = "/")
    
    ensoNdvi2sp(enso_date = i, span = 11,
                ndvi = rst_ndvi_dsn, ndvi_date = dates, 
                fun = sum, col.regions = cols_div(100), 
                # at = seq(-75, 75, 10),
                at = seq(-2.125, 2.125, .25),
                scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                sp.layout = list("sp.text", c(350000, 9625000), lbl, 
                                 font = "bold", cex = 1.2))
  })
  
}

# merge plots
p_emp_dsn <- latticeCombineGrid(ls_emp_dsn, layout = c(2, 4))

png("vis/cor_ndvi_oni/map_ndvi_dsn_enso.png", width = 20, height = 35, units = "cm", 
    pointsize = 18, res = 600)
print(p_emp_dsn)
dev.off()

# anomalies
ls_emp_anom <- foreach(nino = dates_nino, nina = dates_nina, .combine = "append") %do% {
  
  foreach(i = c(nino, nina), j = c(max, min)) %do% {
    lbl1 <- substr(i, 1, 4)
    lbl1 <- as.numeric(lbl1)
    lbl2 <- lbl1+1
    lbl2 <- substr(lbl2, 3, 4)
    lbl <- paste(lbl1, lbl2, sep = "/")
    
    ensoNdvi2sp(enso_date = i, span = 11,
                ndvi = rst_ndvi_anom, ndvi_date = dates, 
                fun = mean, col.regions = cols_div(100), 
                at = seq(-55, 55, 10),
                # at = 2:11,
                scales = list(draw = TRUE), xlab = "x", ylab = "y", 
                sp.layout = list("sp.text", c(350000, 9625000), lbl, 
                                 font = "bold", cex = 1.2))
  }
  
}

# merge plots
p_emp_anom <- latticeCombineGrid(ls_emp_anom, layout = c(2, 4))

png("vis/cor_ndvi_oni/map_ndvi_anom_enso.png", width = 20, height = 35, 
    units = "cm", pointsize = 18, res = 600)
print(p_emp_anom)
dev.off()


# ## iod
# 
# dates_piod <- c("1982-09-01", "1987-09-01", "1997-09-01", "1994-09-01")
# dates_piod <- as.Date(dates_piod)
# dates_niod <- c("1983-09-01", "1988-09-01", "1998-09-01", "1995-09-01")
# dates_niod <- as.Date(dates_niod)
# 
# cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
# 
# ls_emp <- foreach(piod = dates_piod, niod = dates_niod, .combine = "append") %do% {
#   
#   lapply(c(piod, niod), function(i) {
#     ensoNdvi2sp(enso_date = i, 
#                 ndvi = rst_ndvi, ndvi_date = dates, 
#                 fun = sum, col.regions = cols_div(100), 
#                 at = seq(-75, 75, 10),
#                 # at = 3:13,
#                 scales = list(draw = TRUE), xlab = "x", ylab = "y")
#   })
#   
# }
# 
# # merge plots
# latticeCombineGrid(ls_emp, layout = c(2, 4))
