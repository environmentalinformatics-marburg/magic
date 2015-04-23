library(rgdal)
library(raster)
library(reshape2)
library(plyr)
library(ggplot2)

## ndvi

# data import
ch_dir_ndvi <- "/media/fdetsch/XChange/kilimanjaro/gimms3g/gimms3g/data/rst/whittaker/"
ch_fls_ndvi <- "gimms_ndvi3g_dwnscl_8211.tif"
rst_ndvi1km <- stack(paste0(ch_dir_ndvi, ch_fls_ndvi))

# corresponding months
ch_months <- formatC(1:12, width = 2, flag = "0")
ls_ndvi1km_months <- lapply(1982:2011, function(i) {
  paste0(i, ch_months)
})
ch_ndvi1km_months <- do.call("c", ls_ndvi1km_months)

int_id_st <- "201001"
int_id_nd <- "201101"
rst_ndvi1km_1011 <- rst_ndvi1km[[grep(int_id_st, ch_ndvi1km_months):
                                   grep(int_id_nd, ch_ndvi1km_months)]]


## plots

# data import
ch_dir_crd <- "/media/permanent/kilimanjaro/coordinates/coords/"
ch_fls_crd <- "PlotPoles_ARC1960_mod_20140807_final"
spy_plt <- readOGR(dsn = ch_dir_crd, ch_fls_crd)
spy_plt_amp <- subset(spy_plt, PoleType == "AMP")
spy_plt_amp$habitat <- substr(spy_plt_amp$PlotID, 1, 3)

# ndvi extraction
ls_plt_ndvi <- lapply(c("fer", "fed"), function(i) {
  tmp_spy_plt_amp <- subset(spy_plt_amp, habitat == i)
  tmp_plt_ndvi <- extract(rst_ndvi1km_1011, tmp_spy_plt_amp)
  data.frame(habitat = i, plot = tmp_spy_plt_amp$PlotID, tmp_plt_ndvi)
})
df_plt_ndvi <- do.call("rbind", ls_plt_ndvi)

# vis
df_plt_ndvi_mlt <- melt(df_plt_ndvi, id.vars = c(1, 2))
ggplot(aes(x = habitat, y = value), data = df_plt_ndvi_mlt) + 
  geom_boxplot(,subset = .(plot != "fer0"), fill = "grey75", notch = TRUE, 
               lwd = 1) + 
  labs(x = "Habitat type", y = "NDVI") + 
  theme_bw()
