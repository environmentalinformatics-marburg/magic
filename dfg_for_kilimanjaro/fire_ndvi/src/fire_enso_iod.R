lib <- c("raster", "zoo", "ggplot2", "doParallel", "RColorBrewer", "rgeos", 
         "Rsenal")
sapply(lib, function(x) library(x, character.only = TRUE))

# monthly fire rasters
fls_agg1m <- list.files("data/md14a1/low/aggregated", pattern = "^aggsum_md14a1", 
                        full.names = TRUE)
rst_agg1m <- stack(fls_agg1m)

# date sequence
ch_dates_agg1m <- basename(fls_agg1m)
ch_dates_agg1m <- substr(ch_dates_agg1m, 1, nchar(ch_dates_agg1m)-4)
ls_dates_agg1m <- strsplit(ch_dates_agg1m, "_")
ch_dates_agg1m <- sapply(ls_dates_agg1m, "[[", 3)
ch_dates_agg1m <- paste0(ch_dates_agg1m, "01")
dt_dates_agg1m <- as.Date(ch_dates_agg1m, format = "%Y%m%d")

# monthly fire events
val_sum <- sapply(1:nlayers(rst_agg1m), function(i) {
  sum(rst_agg1m[[i]][], na.rm = TRUE)
})

df_fire_agg1m <- data.frame(Date = dt_dates_agg1m, fires = val_sum)

# oni
source("../gimms3g/gimms3g/importOni.R")
df_oni <- importOni(file = "../gimms3g/gimms3g/data/oni/enso_and_iod.csv")

# dmi
source("../gimms3g/gimms3g/importDmi.R")
df_dmi <- importDmi(file = "../gimms3g/gimms3g/data/dmi/dmi.dat")

# merge oni and dmi
df_oni_dmi <- merge(df_oni, df_dmi, by = "Date", all = TRUE)
months <- sapply(strsplit(basename(fls_agg1m), "_"), "[[", 3)
months <- substr(months, 5, 6)

# merge oni/dmi with fire data
df_oni_dmi_fire <- merge(df_fire_agg1m, df_oni_dmi, by = "Date", all.x = TRUE)

# enso/iod groups
groups_nino <- list("all El Ninos", "pure El Ninos", "pure m/s El Ninos", 
                    "El Ninos w IOD+", "m/s El Ninos w IOD+", "purest IOD+", "neutral")

types_nino <- list(c("WE", "ME", "SE"),
                   c("WE", "ME", "SE"),
                   c("ME", "SE"), 
                   c("WE", "ME", "SE"), 
                   c("ME", "SE"), 
                   "WE", 
                   "")

groups_nina <- list("all La Ninas", "pure La Ninas", "pure m/s La Ninas", 
                    "La Ninas w IOD+", "m/s La Ninas w IOD+", "pure IOD+", "neutral")

types_nina <- list(c("WL", "ML", "SL"),
                   c("WL", "ML", "SL"),
                   c("ML", "SL"), 
                   c("WL", "ML", "SL"), 
                   c("ML", "SL"), 
                   "WL", 
                   "")

groups_iod <- list(c("M", "", "P"), 
                   "", 
                   "", 
                   "P", 
                   "P", 
                   "P", 
                   "")

# fires per season

# nino <- types_nino[[2]]
# iod <- groups_iod[[2]]
# group <- groups_nino[[2]]
# span <- 0

fires_agg_nino <- foreach(nino = types_nino, iod = groups_iod, 
                          group = groups_nino, .combine = "rbind") %do% {
                            
  # subset oni/dmi                   
  df_oni_dmi_fire_sub <- subset(df_oni_dmi_fire, (Type %in% nino) & (IOD %in% iod))
  
  if (nrow(df_oni_dmi_fire_sub) == 0)
    return(data.frame(Group = group, fires = NA))
  
  # remove incomplete data (e.g. late 2011)
  seasons <- split(df_oni_dmi_fire_sub, as.factor(df_oni_dmi_fire_sub$Season))
  seasons_len <- sapply(seasons, nrow)
  seasons <- seasons[seasons_len == 12]
  
  df_oni_dmi_fire_sub <- do.call("rbind", seasons)
  
  # aggregate (sum) rainfall amounts per season
  df_oni_dmi_fire_sub_aggssn <- aggregate(df_oni_dmi_fire_sub[, "fires"], 
                                          by = list(df_oni_dmi_fire_sub$Season), 
                                          FUN = sum)
  
  # aggregate (mean) rainfall amounts per current nino group
  num_oni_dmi_fire_sub_aggall <- mean(df_oni_dmi_fire_sub_aggssn$x)
  num_oni_dmi_fire_sub_aggall <- round(num_oni_dmi_fire_sub_aggall)
  df_oni_dmi_fire_sub_aggall <- data.frame(Group = group, 
                                           fires = num_oni_dmi_fire_sub_aggall)
  
  return(df_oni_dmi_fire_sub_aggall)
}

fires_agg_nina <- foreach(nina = types_nina, iod = groups_iod, 
                          group = groups_nina, .combine = "rbind") %do% {
                            
                            # subset oni/dmi                   
                            df_oni_dmi_fire_sub <- subset(df_oni_dmi_fire, (Type %in% nina) & (IOD %in% iod))
                            
                            if (nrow(df_oni_dmi_fire_sub) == 0)
                              return(data.frame(Group = group, fires = NA))
                            
                            # remove incomplete data (e.g. late 2011)
                            seasons <- split(df_oni_dmi_fire_sub, as.factor(df_oni_dmi_fire_sub$Season))
                            seasons_len <- sapply(seasons, nrow)
                            seasons <- seasons[seasons_len == 12]
                            
                            df_oni_dmi_fire_sub <- do.call("rbind", seasons)
                            
                            # aggregate (sum) rainfall amounts per season
                            df_oni_dmi_fire_sub_aggssn <- aggregate(df_oni_dmi_fire_sub[, "fires"], 
                                                                    by = list(df_oni_dmi_fire_sub$Season), 
                                                                    FUN = sum)
                            
                            # aggregate (mean) rainfall amounts per current nina group
                            num_oni_dmi_fire_sub_aggall <- mean(df_oni_dmi_fire_sub_aggssn$x)
                            num_oni_dmi_fire_sub_aggall <- round(num_oni_dmi_fire_sub_aggall)
                            df_oni_dmi_fire_sub_aggall <- data.frame(Group = group, 
                                                                     fires = num_oni_dmi_fire_sub_aggall)
                            
                            return(df_oni_dmi_fire_sub_aggall)
                          }

# occurrence of each group
ssn_cnt_nino <- foreach(nino = types_nino, iod = groups_iod, group = groups_nino, 
                        span = rep(0, length(types_nino)), .combine = "rbind") %do% {
  df_oni_dmi_fire_sub <- subset(df_oni_dmi_fire, (Type %in% nino) & (IOD %in% iod)) 
  
  if (nrow(df_oni_dmi_fire_sub) == 0)
    return(data.frame(Group = group, Count = NA))
  
  # remove incomplete data (e.g. late 2011)
  seasons <- split(df_oni_dmi_fire_sub, as.factor(df_oni_dmi_fire_sub$Season))
  seasons_len <- sapply(seasons, nrow)
  seasons <- seasons[seasons_len == 12]
  
  ssn_cnt <- length(unique(df_oni_dmi_fire_sub$Season))
  df_ssn_cnt <- data.frame(Group = group, Count = ssn_cnt)
  return(df_ssn_cnt)
}

ssn_cnt_nina <- foreach(nina = types_nina, iod = groups_iod, group = groups_nina, 
                        span = rep(0, length(types_nina)), .combine = "rbind") %do% {
  df_oni_dmi_fire_sub <- subset(df_oni_dmi_fire, (Type %in% nina) & (IOD %in% iod)) 
  
  if (nrow(df_oni_dmi_fire_sub) == 0)
    return(data.frame(Group = group, Count = NA))
  
  # remove incomplete data (e.g. late 2011)
  seasons <- split(df_oni_dmi_fire_sub, as.factor(df_oni_dmi_fire_sub$Season))
  seasons_len <- sapply(seasons, nrow)
  seasons <- seasons[seasons_len == 12]
  
  ssn_cnt <- length(seasons)
  df_ssn_cnt <- data.frame(Group = group, Count = ssn_cnt)
  return(df_ssn_cnt)
}
