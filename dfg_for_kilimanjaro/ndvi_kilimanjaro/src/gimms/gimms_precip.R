library(zoo)
library(latticeExtra)

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

# ggplot(aes(x = time, y = value), data = mlt_bfast_prd_ul) + 
#   geom_line() + 
#   facet_wrap(~ component, ncol = 1, scales = "free_y") + 
#   theme_bw()

p_bfast_prd_ul <- 
  xyplot(value ~ time | component, data = mlt_bfast_prd_ul, layout = c(1, 4),
         xlab = "\nTime (months)", ylab = "", 
         as.table = TRUE, scales = list(y = list(relation = "free")), 
         panel = function(x, y) {
           panel.xyplot(x, y, col = "black", type = "l", lwd = 2)
         }, par.settings = list(strip.background = list(col = "lightgrey")))

trellis.focus(name = "panel", column = 1, row = 3)
panel.abline(v = bp_months, lty = 3, col = "red", lwd = 2.5)
panel.text(x = bp_months, y = c(.5, .5, .625), labels = paste0("\n",as.yearmon(bp_months)), 
           srt = 90, col = "red")
trellis.unfocus()

for (i in c(2, 4)) {
  trellis.focus(name = "panel", column = 1, row = i)
  panel.abline(h = 0, lty = 2, col = "grey50")
  trellis.unfocus()
}


# precip bfast
ts_prcp <- ts(prcp[, 3], start = c(1982, 1), end = c(2011, 12), frequency = 12)
bfast_prcp <- bfast(ts_prcp, max.iter = 10, season = "harmonic", hpc = "foreach")
