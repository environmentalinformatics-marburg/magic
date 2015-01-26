library(reshape2)
library(ggplot2)
library(Rsenal)

# predicted data
fls_prd <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_prd <- stack(fls_prd)
mat_prd <- as.matrix(rst_prd)   # results identical to `as.data.frame`

# # spatial clustering
# clstr_prd <- kmeans(mat_prd, centers = 3, nstart = 4, iter.max = 100, 
#                     algorithm = "Ll")
# 
# rst_prd_clstr <- rst_prd[[1]]
# rst_prd_clstr[] <- clstr_prd$cluster

# mann-kendall trends
fls_prd_mk <- list.files("data/rst/whittaker", pattern = "mk", 
                               full.names = TRUE)[4:1]
rst_prd_mk <- lapply(fls_prd_mk, raster)

# indices of pixels with pronounced negative trend in upper-left quadrant
ls_prd_mk_001_split <- splitRaster(fls_prd_mk[4])
rst_prd_mk_001_ul <- raster(ls_prd_mk_001_split[[1]])
rst_prd_mk_001_ul[] <- as.numeric(ls_prd_mk_001_split[[1]][])

id_rm <- which((is.na(rst_prd_mk_001_ul[])) | (rst_prd_mk_001_ul[] > -.25))

# extract 
ls_prd_split <- splitRaster(fls_prd)
rst_prd_ul <- ls_prd_split[[1]]

rst_prd_ul[id_rm] <- NA

st <- as.Date("1982-01-01")
nd <- as.Date("2011-12-31")
days <- seq(st, nd, "month")
df_prd_ul <- as.data.frame(rst_prd_ul)
names(df_prd_ul) <- days

df_prd_mlt <- melt(df_prd_ul, variable.name = "month")
df_prd_mlt$month <- as.Date(df_prd_mlt$month)

p_prd_ul <- 
  ggplot(aes(x = month, y = value), data = df_prd_mlt) + 
  geom_boxplot(aes(group = month), colour = "grey50", outlier.shape = NA) + 
  stat_smooth(colour = "black", lwd = 1.5) + 
  geom_vline(xintercept = as.numeric(as.Date("2003-01-01")), 
             colour = "darkblue", linetype = "longdash", lwd = 1.5) + 
  geom_text(x = as.numeric(as.Date("2003-01-01")), y = .9, angle = 90,
            label = "\nAqua-MODIS", colour = "darkblue") + 
  labs(x = "\nTime [month]", y = "NDVI\n") + 
  theme_bw()

png("vis/ts_prd_ul.png", width = 25, height = 15, units = "cm", 
    pointsize = 15, res = 300)
print(p_prd_ul)
dev.off()

# time series decomposition
library(miscTools)
md_prd_ul <- colMedians(df_prd_ul, na.rm = TRUE)
ts_prd_ul <- ts(md_prd_ul, start = c(1982, 1), end = c(2011, 12), 
                frequency = 12)
stl_prd_ul <- stl(ts_prd_ul, s.window = "periodic")
plot(stl_prd_ul)

library(doParallel)
registerDoParallel(cl <- makeCluster(3))
bfast_prd_ul <- bfast(ts_prd_ul, max.iter = 10, season = "harmonic", 
                      hpc = "foreach")
plot(bfast_prd_ul)
stopCluster(cl)

save(df_prd_ul, md_prd_ul, ts_prd_ul, file = "data/ts_prd_ul.RData")

# mann-kendall 1982-2002 (prior to aqua)
st <- as.Date("1982-01-01")
nd <- as.Date("2002-12-31")
days_8202 <- seq(st, nd, "month")

rst_prd_8202 <- rst_prd[[1:length(days_8202)]]

rst_prd_8202_mk <- calc(rst_prd_8202, fun = function(x) {
  MannKendall(x)$tau
})

library(RColorBrewer)
cols_div <- colorRampPalette(brewer.pal(11, "BrBG"))
spplot(rst_prd_8202_mk, col.regions = cols_div(100), at = seq(-.4, .4, .1), 
       par.settings = list(fontsize = list(text = 15)),
       sp.layout = list(list("sp.lines", rasterToContour(dem), col = "grey65"), 
                        list("sp.lines", np_old_utm_sl, lwd = 1.6, lty = 2), 
                        list("sp.lines", np_new_utm_sl, lwd = 1.6)))
