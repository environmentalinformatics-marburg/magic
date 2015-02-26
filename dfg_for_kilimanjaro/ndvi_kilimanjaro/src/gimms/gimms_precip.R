library(zoo)
library(bfast)
library(latticeExtra)
library(reshape2)

library(doParallel)
registerDoParallel(cl <- makeCluster(3))

source("mergeBfast.R")

# precipitation
prcp <- read.table("data/metoffice_1973-2013.csv", header = TRUE)
prcp[, 1] <- as.Date(prcp[, 1])

st <- as.Date("1982-01-01")
id_st <- which(prcp[, 1] == st)
nd <- as.Date("2011-12-01")
id_nd <- which(prcp[, 1] == nd)
prcp <- prcp[id_st:id_nd, ]
prcp <- prcp[, c(1, grep("NEW", names(prcp)))]

# gimms
fls_prd <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_prd <- stack(fls_prd)
mat_prd <- as.matrix(rst_prd)

# lm
stats_prd_prcp <- foreach(i = 1:nrow(mat_prd), .combine = "rbind") %dopar% {
  tmp_lm <- lm(mat_prd[i, ] ~ sqrt(prcp[, 4]))
  
  tmp_sum <- summary(tmp_lm)
  tmp_r <- cor(sqrt(prcp[, 4]), mat_prd[i, ])
  tmp_rsq <- tmp_sum$r.squared
  tmp_p <- tmp_sum$coefficients[2, 4]
  tmp_sl <- as.numeric(coefficients(tmp_lm)[2])
  
  return(data.frame(cell = i, r = tmp_r, rsq = tmp_rsq, sl = tmp_sl, p = tmp_p))
}

# value insertion
rst_r <- rst_rsq <- rst_sl <- rst_p <- rst_prd[[1]]
rst_r[] <- stats_prd_prcp[, 2]
rst_rsq[] <- stats_prd_prcp[, 3]
rst_sl[] <- stats_prd_prcp[, 4]
rst_p[] <- stats_prd_prcp[, 5]

# significant r-squared
rst_rsq_001 <- overlay(rst_rsq, rst_p, fun = function(x, y) {
  x[y >= .001] <- NA
  return(x)
})

cols_seq <- colorRampPalette(brewer.pal(9, "YlGn"))
p_rsq_001 <- spplot(rst_rsq_001, col.regions = cols_seq(100), at = seq(0, 0.3, 0.025))
png("vis/prcp/rsq_001.png", width = 28, height = 25, units = "cm", 
    pointsize = 15, res = 300)
print(p_rsq_001)
dev.off()

# behaviour of single cells (linear vs. hyperbolic)
id_001 <- which(rst_p[] < .001)
set.seed(123)
smpl <- sample(id_001, 100)

df_smpl <- do.call("rbind", lapply(1:length(smpl), function(i) {
  data.frame(prcp = prcp[, 4], ndvi = mat_prd[smpl[i], ])
}))

png("vis/prcp/sqrtprcp_ndvi_smpl100.png", width = 100, height = 100, units = "cm", 
    res = 300, pointsize = 15)
par(mfrow = c(10, 10))
for (i in 1:length(smpl))
  plot(mat_prd[smpl[i], ] ~ sqrt(prcp[, 4]))
dev.off()

# upper-left quadrant
fls_prd_ul <- list.files("data/rst/whittaker/ul", pattern = "8211_0_0.tif$", 
                         full.names = TRUE)
rst_prd_ul <- stack(fls_prd_ul)

fls_prd_mk_ul <- "data/rst/whittaker/ul/gimms_ndvi3g_dwnscl_8211_mk001_0_0.tif"
rst_prd_mk_ul <- raster(fls_prd_mk_ul)

id_rm <- which((is.na(rst_prd_mk_ul[])) | (rst_prd_mk_ul[] > -.25))
rst_prd_ul[id_rm] <- NA

df_prd_ul <- as.data.frame(rst_prd_ul)

md_prd_ul <- apply(df_prd_ul, 2, FUN = median, na.rm = TRUE)
ts_prd_ul <- ts(md_prd_ul, start = c(1982, 1), end = c(2011, 12), 
                frequency = 12)

bfast_prd_ul <- bfast(ts_prd_ul, max.iter = 10, season = "harmonic", 
                      hpc = "foreach")

bp_id <- bfast_prd_ul$output[[2]]$bp.Vt$breakpoints
bp_months <- seq(st, nd, "month")[bp_id]

df_bfast_prd_ul <- mergeBfast(bfast_prd_ul)
df_bfast_prd_ul$time <- seq(st, nd, "month")
mlt_bfast_prd_ul <- melt(df_bfast_prd_ul, id.vars = "time", 
                         variable.name = "component")
levels(mlt_bfast_prd_ul$component) <- c("Input time series", paste(c("Seasonal", 
                                        "Trend", "Remainder"), "component"))

# enso data
df_oni <- importOni()
df_oni_high <- subset(df_oni, ONI >= 1)
ls_oni_high <- split(df_oni_high, as.factor(df_oni_high$Season))

ls_oni_max <- lapply(ls_oni_high, function(i) {
  int_id_max <- which.max(i$ONI)
  return(i[int_id_max, ])
})
df_oni_max <- do.call("rbind", ls_oni_max)
df_oni_max <- df_oni_max[c(4, 6, 7, 9), ]

# set back date to july
ls_oni_max_ssn_st <- strsplit(df_oni_max$Season, "-")
ch_oni_max_ssn_st <- sapply(ls_oni_max_ssn_st, "[[", 1)
ch_oni_max_ssn_st <- paste0(ch_oni_max_ssn_st, "-07-01")
dt_oni_max_ssn_st <- as.Date(ch_oni_max_ssn_st)

df_oni_max$Date <- dt_oni_max_ssn_st

# labels
ls_oni_max_lbl <- strsplit(df_oni_max$Season, "-")
mat_oni_max_lbl <- sapply(1:2, function(i) {
  ch_yr4 <- sapply(ls_oni_max_lbl, "[[", i)
  ch_yr2 <- substr(ch_yr4, 3, 4)
  return(ch_yr2)
})
ch_oni_max_lbl <- paste(mat_oni_max_lbl[, 1], mat_oni_max_lbl[, 2], sep = "/")

# vis
png("vis/bfast/bfast_ul.png", width = 30, height = 25, units = "cm", 
    pointsize = 15, res = 600)
xyplot(value ~ time | component, data = mlt_bfast_prd_ul, layout = c(1, 4),
         xlab = "\nTime (months)", ylab = "", 
         as.table = TRUE, scales = list(y = list(relation = "free")), 
         panel = function(x, y) {
           panel.xyplot(x, y, col = "black", type = "l", lwd = 2)
         }, par.settings = list(strip.background = list(col = "lightgrey")))

trellis.focus(name = "panel", column = 1, row = 3)
panel.abline(v = bp_months, lty = 3, col = "red", lwd = 2.5)
panel.text(x = bp_months, y = c(.5, .5, .625), labels = paste0("\n", as.yearmon(bp_months)), 
           srt = 90, col = "red")
trellis.unfocus()

for (i in c(2, 4)) {
  trellis.focus(name = "panel", column = 1, row = i)
  panel.abline(h = 0, lty = 2, col = "grey50")
  trellis.unfocus()
}

# major enso events
trellis.focus(name = "panel", column = 1, row = 1)
panel.abline(v = df_oni_max$Date, lty = 2, col = "darkgreen", lwd = 2.5)
panel.text(x = df_oni_max$Date, y = rep(.385, length(df_oni_max$Date)), 
           labels = paste0("\n", ch_oni_max_lbl), srt = 90, col = "darkgreen")
trellis.unfocus()

dev.off()

# precip bfast
ts_prcp <- ts(prcp[, 3], start = c(1982, 1), end = c(2011, 12), frequency = 12)
bfast_prcp <- bfast(ts_prcp, max.iter = 10, season = "harmonic", hpc = "foreach")
