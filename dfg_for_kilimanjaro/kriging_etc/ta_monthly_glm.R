#library(automap)
library(raster)
library(caret)

# path <- "/media/tims_ex/kilimanjaro_ta200_interp"
# setwd(path)
path.server <- "/media/memory01/data/casestudies/kilimanjaro_ta200_interp"
setwd(path.server)

# preparation -------------------------------------------------------------
### define response variable
resp.var <- "Ta_200"
mthd <- "glm"
### load necessary data
## grids
nms.grids <- c("dem", "slp", "svf", "ndvi")
files <- c("in/dem_hemp_utm37s1.sdat", "in/kiliDEM_UTM_slope.sdat", 
           "in/kiliDEM_UTM_sky_view_factor.sdat")

exp.var.stck <- stack(files)
projection(exp.var.stck) <- "+proj=utm +zone=37 +south +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"

ndvi.files <- list.files("in/monthly_means", pattern = glob2rx("utm*"),
                         full.names = TRUE)
ndvi.stck <- stack(ndvi.files)


## points
plots <- read.csv("kili_plots_sp1_utm.csv")
ta.monthly <- read.csv("sp01_plot_monthly_temperature.csv",
                       stringsAsFactors = FALSE)
plots.ta.monthly <- merge(ta.monthly, plots, by.x = "PlotId",
                          by.y = "PlotID", all.x = TRUE)
plots.ta.monthly <- plots.ta.monthly[!is.na(plots.ta.monthly$Easting), ]
coordinates(plots.ta.monthly) <- ~ Easting + Northing

### crop grids to research area extent
ext <- extent(bbox(plots.ta.monthly))
ext@xmin <- ext@xmin - 1000
ext@xmax <- ext@xmax + 1000
ext@ymin <- ext@ymin - 1000
ext@ymax <- ext@ymax + 1000

exp.var.stck.cr <- crop(exp.var.stck, ext)
ndvi.stck.cr <- crop(ndvi.stck, ext)
# exp.var.stck.cr.sp <- as(exp.var.stck.cr, "SpatialPixelsDataFrame")
# ndvi.stck.cr.sp <- as(ndvi.stck.cr, "SpatialPixelsDataFrame")

### extract predictor variables and add to table
extracted.values <- lapply(seq(nlayers(exp.var.stck.cr)), function(j) {
  exp <- extract(exp.var.stck.cr[[j]], plots.ta.monthly)
})

for (k in seq(extracted.values)) {
  plots.ta.monthly@data[nms.grids[k]] <- extracted.values[[k]]
}

plots.ta.monthly.mss <- split(plots.ta.monthly, plots.ta.monthly$Month)

extracted.ndvi <- lapply(seq(nlayers(ndvi.stck.cr)), function(i) {
  extract(ndvi.stck[[i]], plots.ta.monthly.mss[[i]])
})

for (i in seq(plots.ta.monthly.mss)) {
  plots.ta.monthly.mss[[i]]$ndvi <- extracted.ndvi[[i]]
}

plots.ta.monthly.all <- do.call("rbind", plots.ta.monthly.mss)
plots.ta.monthly <- plots.ta.monthly.all[complete.cases(plots.ta.monthly.all@data), ]

plots.ta.monthly$year <- substr(plots.ta.monthly$Datetime, 1, 4)
plots.ta.monthly <- subset(plots.ta.monthly, year != "2010")
plots.ta.monthly.rug <- subset(plots.ta.monthly, 
                               StationId == "000rug" | StationId == "000rad")

proj4string(plots.ta.monthly.rug) <- "+proj=utm +zone=37 +south +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
plots.ta.monthly.rug <- plots.ta.monthly.rug[order(plots.ta.monthly.rug$Datetime), ]


### global training
for (i in 1:500) {
  cat("running", mthd, ": iteration", i, "\n")
  set.seed(i)
  
  ind.eval <- sample(nrow(plots.ta.monthly.rug), nrow(plots.ta.monthly.rug) * 0.9)
  ta.pred <- plots.ta.monthly.rug[ind.eval, ]
  ta.eval <- plots.ta.monthly.rug[-ind.eval, ]
  
  resp <- ta.pred@data[[resp.var]]
  pred <- data.frame(ta.pred@data$dem, ta.pred@data$slp, ta.pred@data$svf, 
                     ta.pred@data$ndvi, 
                     x = coordinates(ta.pred)[, 1],
                     y = coordinates(ta.pred)[, 2])
  pred$month <- ta.pred@data$Month
  pred$year <- as.integer(ta.pred@data$year)
  names(pred) <- c(nms.grids, "x", "y", "month", "year")
  pred <- data.frame(scale(pred, center = T, scale = T))
  pred$resp <- resp
  
  eval <- data.frame(ta.eval@data$dem, ta.eval@data$slp, ta.eval@data$svf, 
                     ta.eval@data$ndvi, 
                     x = coordinates(ta.eval)[, 1],
                     y = coordinates(ta.eval)[, 2])
  eval$month <- ta.eval@data$Month
  eval$year <- as.integer(ta.eval@data$year)
  names(eval) <- c(nms.grids, "x", "y", "month", "year")
  eval <- data.frame(scale(eval, center=T, scale=T))
  
  fmla <- as.formula(paste("resp ~ ", 
                           paste(names(pred)[1:(length(names(pred)) - 1)],
                                 collapse = "+")))
  
  model <- train(fmla, data = pred, method = mthd)
  fit <- predict(model, eval)
  
  df.out <- data.frame(year = ta.eval@data$year,
                       month = ta.eval@data$Month,
                       PlotID = as.character(ta.eval@data$PlotId),
                       StationID = as.character(ta.eval@data$StationId),
                       Ta_obs = ta.eval@data$Ta_200,
                       Ta_pred = fit,
                       elevation = ta.eval@data$dem,
                       method = mthd,
                       iteration = i)
  
  dir.create(paste("results", mthd, sep = "/"), showWarnings = FALSE)
  
  out.path <- paste("results", mthd, paste("ki", mthd,
                                           "ta_dem_slp_svf_ndvi_x_y_mon_yr.csv",
                                           sep = "_"),
                    sep = "/")
  
  write.table(df.out, out.path, 
              row.names = FALSE, col.names = FALSE, append = TRUE, sep = ",")
}