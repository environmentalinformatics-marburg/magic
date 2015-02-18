## precipitation
# start and end
st <- "1982-01"
nd <- "2011-12"

# nairobi, makindu
fls_prcp_nai_mak <- list.files("data/gsod", pattern = "^prcp_mnth", full.names = TRUE)
dat_prcp_nai_mak <- lapply(fls_prcp, function(i) {
  dat <- read.csv(i)
  dat[, 1] <- as.Date(dat[, 1])
  return(dat)
})

# moshi, kia
dat_prcp_kia_mos <- read.table("data/metoffice_1973-2013.csv", sep = " ", 
                             header = TRUE)
dat_prcp_kia_mos[, 1] <- as.Date(dat_prcp_kia_mos[, 1])
id_st <- grep(st, dat_prcp_kia_mos[, 1])
id_nd <- grep(nd, dat_prcp_kia_mos[, 1])
dat_prcp_kia_mos <- dat_prcp_kia_mos[id_st:id_nd, ]


## ndvi
fls_ndvi <- "data/rst/whittaker/gimms_ndvi3g_dwnscl_8211.tif"
rst_ndvi <- stack(fls_ndvi)
mat_ndvi <- as.matrix(rst_ndvi)


## correlation
set.seed(123)
smpl <- sample(ncell(rst_ndvi), 100)

png("vis/cor_ndvi_prcp/vis_relationship.png", width = 60, height = 60, 
    units = "cm", pointsize = 18, res = 600)
par(mfrow = c(10, 10))
for (i in smpl)
  plot(mat_ndvi[i, ] ~ dat_prcp_kia_mos[, 2])
dev.off()

calc(rst_ndvi, fun = function(x) {
  cor(x, dat_prcp_kia_mos[, 2])
})