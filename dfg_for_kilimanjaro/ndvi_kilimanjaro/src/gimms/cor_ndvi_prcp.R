## precipitation
# start and end
st <- "1982-01"
nd <- "2011-12"

# nairobi, makindu
fls_prcp_nai_mak <- list.files("data/gsod", pattern = "^prcp_mnth", full.names = TRUE)
dat_prcp_nai_mak <- lapply(fls_prcp_nai_mak, function(i) {
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


## aggregated rainfall amounts per season
# el nino
groups_nino <- list("all El Ninos", "pure El Ninos", "pure m/s El Ninos", 
               "El Ninos w IOD+", "m/s El Ninos w IOD+", "purest IOD+", "neutral")

types_nino <- list(c("WE", "ME", "SE"),
                    c("WE", "ME", "SE"),
                    c("ME", "SE"), 
                    c("WE", "ME", "SE"), 
                    c("ME", "SE"), 
                    "WE", 
                   "")

groups_iod <- list(c("M", "", "P"), 
                   "", 
                   "", 
                   "P", 
                   "P", 
                   "P", 
                   "")

nino <- types_nino[[1]]
iod <- groups_iod[[1]]
group <- groups_nino[[1]]
span <- 0

prcp_agg_group <- foreach(nino = types_nino, iod = groups_iod, 
                          group = groups_nino, .combine = "rbind") %do% {
  
  # subset oni/dmi                   
  oni_mlt_sub <- subset(oni_mlt, (Type %in% nino) & (IOD %in% iod))

  # remove incomplete data (e.g. late 2011)
  seasons <- split(oni_mlt_sub, as.factor(oni_mlt_sub$Season))
  seasons_len <- sapply(seasons, nrow)
  seasons <- seasons[seasons_len == 12]
  
  oni_mlt_sub <- do.call("rbind", seasons)
  
  # merge with corresponding rainfall records
  df_oni_prcp <- merge(oni_mlt_sub, dat_prcp_kia_mos, 
                       by.x = "Date", by.y = "YEAR", all.x = TRUE)
  
  # aggregate (sum) rainfall amounts per season
  df_oni_prcp_aggssn <- aggregate(df_oni_prcp[, c("P_KIA_NEW", "P_MOSHI_NEW", "P_MEAN_NEW")], 
                                  by = list(df_oni_prcp$Season), FUN = sum)
  
  # aggregate (mean) rainfall amounts per current nino group
  num_oni_prcp_aggall <- colMeans(df_oni_prcp_aggssn[, c("P_KIA_NEW", "P_MOSHI_NEW", "P_MEAN_NEW")])
  mat_oni_prcp_aggall <- matrix(num_oni_prcp_aggall, byrow = TRUE, ncol = 3)
  df_oni_prcp_aggall <- data.frame(Group = group, mat_oni_prcp_aggall)
  names(df_oni_prcp_aggall)[2:4] <- names(num_oni_prcp_aggall)
  
  return(df_oni_prcp_aggall)
}

prcp_agg_group[, 2:4] <- round(prcp_agg_group[, 2:4])

write.csv(prcp_agg_group, "data/prcp/prcp_aggyr_enso_iod.csv")
write.csv(t(prcp_agg_group), "data/prcp/prcp_aggyr_enso_iod_t.csv")
