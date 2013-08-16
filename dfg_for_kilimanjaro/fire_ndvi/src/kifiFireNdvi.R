### Environmental stuff

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
# path.wd <- "/media/pa_NDown/ki_modis_ndvi" # Linux
path.wd <- "G:/ki_modis_ndvi" # Windows
setwd(path.wd) 

# Required packages and functions
lib <- c("doParallel", "raster", "latticeExtra", "popbio", "ggplot2")
sapply(lib, function(x) stopifnot(require(x, character.only = T)))

lib.par <- c("rgdal", "raster", "foreach")

fun <- paste("src", 
             c("kifiAggData.R", "kifiMaxChange.R", "kifiProbMat.R"), sep = "/")
sapply(fun, source)

# Parallelization
registerDoParallel(cl <- makeCluster(4))


### Data import

## MODIS NDVI 

# List files and order by date
ndvi.fls <- list.files("data/quality_control/", recursive = T, full.names = T)

ndvi.dates <- substr(basename(ndvi.fls), 13, 19)
ndvi.years <- unique(substr(basename(ndvi.fls), 13, 16))

ndvi.fls <- ndvi.fls[order(ndvi.dates)]

# Setup time series
ndvi.ts <- do.call("c", lapply(ndvi.years, function(i) { 
  seq(as.Date(paste(i, "01", "01", sep = "-")), 
      as.Date(paste(i, "12", "31", sep = "-")), 8)
}))

# Merge time series with available NDVI files
ndvi.ts.fls <- merge(data.frame(date = ndvi.ts), 
                     data.frame(date = as.Date(dates, format = "%Y%j"), 
                                file = ndvi.fls, stringsAsFactors = F), 
                     by = "date", all.x = T)

# Import raster files
ndvi.rst <- foreach(i = seq(nrow(ndvi.ts.fls)), .packages = lib.par) %dopar% {
  if (is.na(ndvi.ts.fls[i, 2])) {
    NA
  } else {
    raster(ndvi.ts.fls[i, 2])
  }
}


## MODIS fire

# Import raster files and aggregate on 8 days
aggregate.exe <- T

if (aggregate.exe) {
  # List files
  fire.fls <- list.files("data/reclass/md14a1", full.names = TRUE, pattern = ".tif$")
  
  # Setup time series
  fire.dates <- substr(basename(fire.fls), 8, 14)
  fire.years <- unique(substr(basename(fire.fls), 8, 11))
  
  fire.dly.ts <- do.call("c", lapply(fire.years, function(i) { 
    seq(as.Date(paste(i, "01", "01", sep = "-")), 
        as.Date(paste(i, "12", "31", sep = "-")), 1)
  }))
  
  # Merge time series with available fire data
  fire.dly.ts.fls <- merge(data.frame(date = fire.dly.ts), 
                           data.frame(date = as.Date(fire.dates, format = "%Y%j"), 
                                      file = fire.fls, stringsAsFactors = F), 
                           by = "date", all.x = T)
  
  fire.rst <- unlist(kifiAggData(
    data = fire.dly.ts.fls, 
    years = fire.years, 
    over.fun = max, 
    dsn = "G:/ki_modis_ndvi/data/overlay/md14a1_agg/", 
    out.str = "md14a1", format = "GTiff", overwrite = T, 
    out.proj = "+init=epsg:32737", n.cores = 4
  ))
} else {
  # List files
  fire.fls <- list.files("data/overlay/md14a1_agg", pattern = "md14a1.*.tif$", full.names = TRUE)
  
  # Setup time series
  fire.dates <- substr(basename(fire.fls), 8, 14)
  fire.years <- unique(substr(basename(fire.fls), 8, 11))

  fire.ts <- do.call("c", lapply(fire.years, function(i) { 
    seq(as.Date(paste(i, "01", "01", sep = "-")), 
        as.Date(paste(i, "12", "31", sep = "-")), 8)
  }))
  
  # Merge time series with available fire data
  fire.ts.fls <- merge(data.frame(date = fire.ts), 
                       data.frame(date = as.Date(fire.dates, format = "%Y%j"), 
                                  file = fire.fls, stringsAsFactors = F), 
                       by = "date", all.x = T)
  
  # Import aggregated fire data
  fire.rst <- foreach(i = seq(nrow(fire.ts.fls)), .packages = lib.par) %dopar% {
    if (is.na(fire.ts.fls[i, 2])) {
      NA
    } else {
      raster(fire.ts.fls[i, 2])
    }
  }
}

# Identification of fire scenes and fire pixels
fire.scenes <- foreach(i = fire.rst, .combine = "c", .packages = lib.par) %dopar% {
  if (class(i) != "logical") {maxValue(i) > 0} else {NA}
}

fire.cells <- sort(unique(
  foreach(i = fire.rst, .combine = "c", .packages = lib.par) %dopar% {
    if (class(i) != "logical") {which(getValues(i) > 0)} else {NA}
}))


### NDVI prior to and after fire

maxchange.df <- kifiMaxChange(fire.scenes = fire.scenes, 
                              fire.ts.fls = fire.ts.fls, 
                              timespan = 1, 
                              fire.rst = fire.rst, 
                              ndvi.rst = ndvi.rst, 
                              n.cores = 4)


### Logistic regression

# Remove penultimate NDVI values from data.frame
tmp.sub <- maxchange.df[-seq(1, nrow(maxchange.df), 3), ]

# Dependent and independent variables
depend <- tmp.sub$fire
independ <- tmp.sub$ndvi_diff

# GLM
model <- glm(depend ~ independ, family = binomial)

# # Plot logistic regression
# x.new <- seq(min(independ), max(independ), len = 100)
# y.new <- predict(mod2, data.frame(independ = x.new), type = "response")
# 
# plot(fire ~ ndvi_diff, data = tmp.sub)
# lines(x.new, y.new, col = "red")

# Calculate fire propability matrices of NDVI cells
fire.prob.rst <- kifiProbMat(fire.scenes = fire.scenes, 
                             fire.ts.fls = fire.ts.fls, 
                             timespan = 1, 
                             fire.rst = fire.rst, 
                             ndvi.rst = ndvi.rst, 
                             model = model, 
                             n.cores = 4)

# Transform information about fire occurence (0/1) to factor
fire.ndvi.pre.post$fire <- factor(ifelse(fire.ndvi.pre.post$fire == 0, "no", "yes"))


# Write output
write.csv(fire.ndvi.pre.post, "out/fire_ndvi_pre_post.csv", 
          quote = FALSE, row.names = FALSE)


### Plotting stuff

# Individual color scheme
my.bw.theme <- trellis.par.get()
my.bw.theme$box.rectangle$col = "grey80" 
my.bw.theme$box.umbrella$col = "grey80"
my.bw.theme$plot.symbol$col = "grey80"

# # Fit GLM with binomial distributed data
# fire.ndvi.glm <- glm(fire ~ ndvi, data = fire.ndvi.pre.post, 
#                      family = binomial(link = "logit"))

# Plot logistic GLM fit including histogram 
png("out/glm_ndvi_fire.png", width = 800, height = 600)
par(bg = "white")
logi.hist.plot(fire.ndvi.pre.post$ndvi, ifelse(fire.ndvi.pre.post$fire == "yes", 1, 0), 
               boxp = F, type = "hist", col = "gray")
dev.off()

# Scatterplot with point density distribution and boxplots
png("out/fire_ndvi_prepos_mincell.png", width = 800, height = 600)
plot(xyplot(as.factor(fire) ~ ndvi, data = fire.ndvi.pre.post,
            par.settings = my.bw.theme, 
            xlab = "NDVI", ylab = "Fire", panel = function(x, y) {
              panel.smoothScatter(x, y, nbin = 500, bandwidth = .1, cuts = 10, nrpoints = 0)
              panel.bwplot(x, y, box.ratio = .25, pch = "|", notch = TRUE, 
                           par.settings = my.bw.theme)
            }))
dev.off()

# Densityplot
png("out/dens_ndvi.png", width = 800, height = 600)
print(ggplot(fire.ndvi.pre.post, aes(x = ndvi, fill = fire)) + 
  geom_density(alpha = .5) + 
  scale_fill_manual(values = c("no" = "black", "yes" = "red")) + 
  guides(fill = guide_legend(title = "Fire" ,
                             title.theme = element_text( face="plain", angle=0 ))) + 
  ylab("Density") + xlab("NDVI"))
dev.off()

# Deregister parallel backend
stopCluster(clstr)