library(raster)
library(Kendall)
library(RColorBrewer)
library(ggplot2)


# Check your working directory
setwd("D:/modiscdata_mod/data_rst/cir_stat/crf_mnth_sum/06_jun")

# setwd("/media/IOtte/modiscdata_myd06/data/2002/tifs/prj_scl/tau")
inputpath <- "D:/modiscdata_mod/data_rst/cir_stat/crf_mnth_sum/06_jun"
ptrn <- "crf_mnth_sum*.tif"
  
# List folders in data directory
# tau.drs <- dir("data", full.names = T)
crf.fls <- list.files(inputpath, 
                      pattern = glob2rx(ptrn), 
                      recursive = T)
stck <- stack(crf.fls)
stck.mean <- calc(stck, mean)
stck.mean.chisq <- calc(stck, function(x) chisq.test(x)$p.value)

# plot Mk trend raster
#RColorBrewer::display.brewer.all()
clrs <- colorRampPalette(brewer.pal(11, "YlGnBu"))
spplot(stck.mean, main = "Terra: mean Cirrus June, 2002 - 2013", col.regions = clrs)

# write raster file  
writeRaster(stck.mean, filename = "monthly_mean_cir",
            format = "GTiff") 
  
# Grep and order all SDS files with a specified pattern from each subfolder
#tau.fls <- unlist(lapply(tau.drs, function(i) {
#  list.files(paste(i, "tifs", "prj_scl", sep = "/"), full.names = T)
#}))
# tau.fls <- list.files(pattern = ".tif")
  
# stck <- stack(tau.fls)

  
crf.fls.dts.old <- substr(basename(crf.fls), 11, 17)
crf.fls.dts.new <- as.Date(substr(basename(crf.fls), 11, 17), format = "%Y%j")
  
crf.fls.new <- sapply(seq(crf.fls), function(i) {
  sub(crf.fls.dts.old[i], crf.fls.dts.new[i], crf.fls[i])
})
  
# Remove unclear files
crf.fls.df <- data.frame(date = as.Date(substr(basename(crf.fls), 11, 17), format = "%Y%j"), 
                          file = crf.fls, stringsAsFactors = FALSE)
crf.fls.df <- crf.fls.df[-unique(c(which(duplicated(crf.fls.df[, 1])), 
                                         which(duplicated(crf.fls.df[, 1], fromLast = T)))), ]
  
# Extract available years
crf.yrs <- unique(substr(crf.fls.df[, 1], 1, 4))
  
# Establish continuous time series
crf.ts <- do.call("c", lapply(crf.yrs, function(i) {
  seq(as.Date(paste(i, "01", "01", sep = "-")), as.Date(paste(i, "12", "31", sep = "-")), 1)
}))
  
# Merge time series template with available files
# (No file available -> tau.tau.ts.fls[, 2] == NA)  
crf.ts.fls <- merge(data.frame(date = crf.ts), 
                    crf.fls.df, 
                    by = "date", all.x = T)
  
crf.ts.fls <- crf.ts.fls[complete.cases(crf.ts.fls), ]
crf.ts.fls$mnth <- substr(crf.ts.fls$date, 1, 7)
crf.ts.fls.mnth <- split(crf.ts.fls, crf.ts.fls$mnth)
  
crf.mnth.stck <- lapply(seq(crf.ts.fls.mnth), function(i){
  calc(stack(crf.ts.fls.mnth[[i]]$file), sum, na.rm = TRUE)
})
  
  
crf.stck <- stack(crf.mnth.stck)
ex <- extent(277676.4, 355676.4, 9624011, 9686011)
crf.stck.ex <- crop(crf.stck, ex)

  
#cld.mnth <- lapply(seq(cld.ts.fls.mnth), function(i){
#  calc(stack(cld.ts.fls.mnth[[i]]$file), mean)
#})
#tau.mnth.stck <- stack(tau.mnth)  
writeRaster(crf.stck.ex, paste("crf_mnth_sum", "crf_mnth_sum", sep = "/"),
            format = "GTiff", bylayer = TRUE, suffix = "numbers") 
    
  
# time <- 1:nlayers(tau.mnth.stck)
# fun <- function(x) { MannKendall(x)$tau }
# MK_mnth_mean_tau <- calc(tau.stck, fun, quick = TRUE)
chisq.crf <- calc(crf.stck.ex, function(x) chisq.test(x)$p.value)

# plot Mk trend raster
RColorBrewer::display.brewer.all()
clrs <- colorRampPalette(brewer.pal(11, "YlGnBu"))
spplot(chisq.crf, main = "Terra: chi.sq Cirrus (monthly sum) [138 months], 2002 - 2013", col.regions = clrs)

# write raster file  
writeRaster(chisq.crf, filename = "chisq_monthly_sum_cir",
            format = "GTiff") 
