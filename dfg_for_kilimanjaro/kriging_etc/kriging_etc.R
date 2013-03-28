library(raster)
library(latticeExtra)
library(parallel)
library(automap)
library(rgdal)
library(grid)
library(directlabels)
library(AMORE)
library(metvurst)
library(randomForest)
#library(ggplot2)

###### claculate aspect and slope and rename ndvi files ########################

# demUTM <- raster("/media/windows/tappelhans/uni/marburg/kili/plots/kiliDEM/kiliDEM.grd")
# 
# #demUTM <- dem
# # plots <- read.csv("/media/windows/tappelhans/uni/marburg/lehre/students/ZA/kordillaMarie/")
# # 
# # coordinates(plots) <- c("Easting", "Northing")
# # plots@proj4string@projargs <- "+proj=utm +ellps=clrk80 +zone=37 +units=m +south"
# # plots <- plots[, -c(1, 3)]
# # 
# # demplot <- spplot(demUTM)
# # pointplot <- spplot(plots, col.regions = "black")
# # comboplot <- demplot + as.layer(pointplot)
# # comboplot
# 
# #?terrain
# aspct <- terrain(demUTM, 'aspect', unit = 'degrees')
# #spplot(aspct)
# slp <- terrain(demUTM, 'slope', unit = 'degrees')
# #spplot(slp)
# 
# ki.terrain <- stack(demUTM, aspct, slp)
# 
# #ki.terrain.sp <- as(ki.terrain, "SpatialGridDataFrame")
# #ki.terrain.sp <- as(ki.terrain, "SpatialPixelsDataFrame")
# 
# setwd("/media/windows/tappelhans/uni/marburg/lehre/students/ZA/kordillaMarie/ndvi/")
# 
# ### File processing parallel
# 
# # Available files
# ndvi.files <- list.files(pattern = ".rst")
# ndvi.names <- paste("NDVI", substr(ndvi.files, 22, 28), sep = "_")
# 
# n.cores <- detectCores()
# clstr <- makePSOCKcluster(n.cores)
# 
# clusterExport(clstr, c("ndvi.files", "ndvi.names", "demUTM"))
# clusterEvalQ(clstr, library(raster))
# 
# ndvi <- parLapply(clstr, seq(ndvi.files), function(i) {
#   tmp <- raster(ndvi.files[i])
#   names(tmp) <- ndvi.names[i]
#   #projectRaster(tmp, demUTM)
#   return(tmp)
# })
# 
# stopCluster(clstr)
# 
# ndvi.stack <- stack(ndvi)
# 
# ndvi.stack <- resample(ndvi.stack, ki.terrain)
# 
# # n.cores <- detectCores()
# # clstr <- makePSOCKcluster(n.cores)
# # 
# # clusterExport(clstr, c("ndvi.files", "ndvi.names", "ki.terrain", "ndvi.stack"))
# # clusterEvalQ(clstr, c(library(raster), library(rgdal)))
# 
# lapply(seq(ndvi.stack), function(i) {
#   tmp <- stack(ki.terrain, ndvi.stack[[i]])
#   names(tmp) <- c("elevation", "aspect", "slope", ndvi.names[i])
#   writeRaster(tmp, paste("ki.all.stack", ndvi.names[i], "grd", sep = "."))
# })
# 

# stopCluster(clstr)
                  
# ki.all <- stack(ki.terrain, ndvi.stack)
# ki.all <- aggregate(ki.all, 20)
# writeRaster(ki.all, "ki.all.stack.lowres.grd")
################################################################################




###### plot data management ####################################################
# stations <- read.csv("/media/windows/tappelhans/uni/marburg/lehre/students/ZA/kordillaMarie/ndvi/temp2012152.csv",
#                      stringsAsFactors = FALSE)
# stations <- stations[order(stations$PlotId, stations$Datetime), ]
# #write.table(stations, "temp2012152.csv", col.names = TRUE, row.names = FALSE, sep = ",")
# coordinates(stations) <- c("Lon", "Lat")
# stations@proj4string@projargs <- "+proj=latlon"
# stations <- spTransform(stations, 
#                         CRS("+proj=utm +ellps=clrk80 +zone=37 +units=m +south"))
# 
# setwd("/media/windows/tappelhans/uni/marburg/lehre/students/ZA/kordillaMarie/ndvi/latlon/")
# 
# ndvi.files <- list.files(pattern = ".grd")
# ndvi.names <- substr(ndvi.files, 14, 25)
# 
# 
# jul.days <- julian(as.Date(stations$Datetime), origin = as.Date("2011-12-31"))
# ndvi.days <- as.integer(substr(ndvi.names, 10, 13))
# ndvi.days <- rep(ndvi.days, each = length(unique(jul.days)) / length(ndvi.days))
# ndvi.days <- rep(ndvi.days, length(jul.days)/length(ndvi.days))
# 
# #ndvi.days[6990:7000] %% as.integer(jul.days)[6990:7000]
# 
# ki.all <- lapply(seq(ndvi.files), function(i) {
#   tmp <- stack(ndvi.files[i])
#   names(tmp) <- c("elevation", "aspect", "slope", "ndvi")
#   return(tmp)
# })
# 
# n.cores <- detectCores()
# clstr <- makePSOCKcluster(n.cores)
# 
# clusterExport(clstr, c("ki.all", "ndvi.names"))
# clusterEvalQ(clstr, library(raster))
# 
# ki.all <- parLapply(clstr, seq(ki.all), function(i) {
#   projectRaster(ki.all[[i]], 
#                 crs = "+proj=utm +ellps=clrk80 +zone=37 +units=m +south",
#                 res = 30)
# })
# 
# stopCluster(clstr)
# 
# n.cores <- detectCores()
# clstr <- makePSOCKcluster(n.cores)
# clusterExport(clstr, c("ki.all", "ndvi.names"))
# clusterEvalQ(clstr, library(raster))
# 
# parLapply(clstr, seq(ki.all), function(i) {
#    writeRaster(ki.all[[i]], paste("ki.all.stackUTM", ndvi.names[i], "grd", sep = "."))
# })
# 
# stopCluster(clstr)
# 
# xmin <- stations@bbox[1,1] - 1000
# xmax <- stations@bbox[1,2] + 1000
# ymin <- stations@bbox[2,1] - 1000
# ymax <- stations@bbox[2,2] + 1000
# 
# ext <- extent(c(xmin, xmax, ymin, ymax))
# 
# ki.all <- lapply(seq(ki.all), function(i) {
#   crop(ki.all[[i]], ext)
# })
# 
# ki.all.sp <- lapply(seq(ki.all), function(i) {
#   as(ki.all[[i]], "SpatialPixelsDataFrame")
# })
# #names(ki.all.sp) <- c("a", "b", "c", "d")
# 
# asp <- over(stations, ki.all.sp[[1]][, 2])
# slp <- over(stations, ki.all.sp[[1]][, 3])
# ele <- over(stations, ki.all.sp[[1]][, 1])
# 
# ndv <- sapply(seq(ki.all.sp), function(i) {
#   unlist(rep(unique(over(stations, ki.all.sp[[i]][, 4])), 8))
# })
# 
# stns <- read.csv("/media/windows/tappelhans/uni/marburg/lehre/students/ZA/kordillaMarie/ndvi/temp2012152.csv",
#                      stringsAsFactors = FALSE)
# 
# stns$elevation <- ele[, 1]
# stns$aspect <- asp[, 1]
# stns$slope <- slp[, 1]
# 
# stns <- stns[order(stns$Datetime), ]
# 
# stns$ndvi <- as.numeric(ndv)
# 
# write.table(stns, "Ta_ele_asp_slp_ndvi_clean.csv", col.names = TRUE, row.names = FALSE,
#             sep = ",")
################################################################################




###### Kriging #################################################################
eval.sample.size <- 10
days <- 1:152
ncycles <- 50

stations <- read.csv("/media/windows/tappelhans/uni/marburg/lehre/students/ZA/kordillaMarie/Ta_ele_asp_slp_ndvi_clean.csv",
                     stringsAsFactors = FALSE)

coordinates(stations) <- c("Lon", "Lat")
stations@proj4string@projargs <- "+proj=latlon"
stations <- spTransform(stations, 
                        CRS("+proj=utm +ellps=clrk80 +zone=37 +units=m +south"))

stns.complete <- split(stations, stations$Datetime)

setwd("/media/windows/tappelhans/uni/marburg/lehre/students/ZA/kordillaMarie/ndvi/UTM/")

xmin <- stations@bbox[1,1] - 1000
xmax <- stations@bbox[1,2] + 1000
ymin <- stations@bbox[2,1] - 1000
ymax <- stations@bbox[2,2] + 1000

ext <- extent(c(xmin, xmax, ymin, ymax))

ndvi.files <- list.files(pattern = ".grd")
ndvi.files <- rep(ndvi.files, each = 8)
#ndvi.names <- substr(ndvi.files, 17, 28)

for (i in days) {
  ki.all <- stack(ndvi.files[i])
  ki.all <- crop(ki.all, ext)
  ki.all.sp <- as(ki.all, "SpatialPixelsDataFrame")
  
  for (j in 1:ncycles) {
    eval.id <- sample(nrow(stns.complete[[i]]), eval.sample.size)
    stns.train <- stns.complete[[i]][-c(eval.id), ]
    stns.pred <- stns.complete[[i]][c(eval.id), ]
    
    cat("\n", 
        "Performing Kriging on day", i, "cycle", j, 
        "\n", sep = " ")
    
    krig_result <- autoKrige(Ta_200 ~ elevation+slope+ndvi+aspect,
                             stns.train, ki.all.sp)
    
    Ta_pred <- over(stns.pred, krig_result$krige_output[, 1])
    
    scale.min <- min(c(Ta_pred[, 1], stns.pred$Ta_200)) - 1
    scale.max <- max(c(Ta_pred[, 1], stns.pred$Ta_200)) + 1 
    
    day <- i
    cycle <- j
    df <- data.frame(day, cycle, stns.pred$Ta_200, Ta_pred[, 1])
    write.table(df, "../../results/krig.output.txt", col.names = FALSE, row.names = FALSE, 
                append = TRUE, sep = ",")
        
    title.krig <- paste("2012", "Day:", i, "Cycle:", j, "Kriging", sep = " ")
    
    scatter <- xyplot(Ta_pred[, 1] ~ stns.pred$Ta_200, groups = stns.pred$PlotId,
                      xlim = c(scale.min, scale.max), pch = 19,
                      ylim = c(scale.min, scale.max), asp = "iso",
                      xlab = "observed", ylab = "predicted", main = title.krig,
                      xscale.components = xscale.components.subticks,
                      yscale.components = yscale.components.subticks) +
      layer(panel.ablineq(lm(y ~ x), r.sq = TRUE, rot = FALSE, x = scale.max * 0.5,
                          y = scale.max * 0.9)) +
      #   layer(panel.text(x = x, y = y, labels = stns.pred$PlotId, pos = 1, 
      #                    offset = 1)) +
      layer(panel.abline(a = 0, b = 1, lty = 2, col = "red"))
    
    pdf(paste("../../results/krig.eval", i, j, "pdf", sep = "."), 7, 7)
    trellis.par.set(standard.theme(color = FALSE))
    print(direct.label(scatter, list("smart.grid")))
    dev.off()
    
    clrs <- colorRampPalette(c(rev(brewer.pal(11, "Spectral")), "black"))
    plt <- spplot(krig_result$krige_output[,1], col.regions = clrs(1000), 
                  at = seq(-15, 40, 1),
                  asp = "iso", main = title) +
      as.layer(spplot(stns.train, zcol = "Ta_200", col.regions = "black")) +
      as.layer(spplot(stns.pred, zcol = "Ta_200", col.regions = "grey80"))
              
    png(paste("../../results/krig.pred", i, j, "png", sep = "."),
        height = 8*300, width = 8*300, res = 300)
    print(plt)
    dev.off()
################################################################################
    
###### neural network approach mit AMORE #######################################
    trgt.id <- sample(nrow(stns.train), eval.sample.size)
    inpt.train <- stns.train[-c(trgt.id), ]
    inpt.trgt <- stns.train[c(trgt.id), ]
    
    train.list <- lapply(seq(nrow(stns.pred)), function(k) {
      trgt.tmp <- inpt.trgt@data[k, "Ta_200"]
      trgt.ele <- inpt.trgt@data[k, "elevation"]
      trgt.asp <- inpt.trgt@data[k, "aspect"]
      trgt.slp <- inpt.trgt@data[k, "slope"]
      trgt.ndv <- inpt.trgt@data[k, "ndvi"]
      trgt.est <- inpt.trgt@coords[k, 1]
      trgt.nth <- inpt.trgt@coords[k, 2]
      
      inpt.tmp <- inpt.train@data[, "Ta_200"]
      inpt.ele <- inpt.train@data[, "elevation"] - trgt.ele
      inpt.asp <- inpt.train@data[, "aspect"] - trgt.asp
      inpt.slp <- inpt.train@data[, "slope"] - trgt.slp
      inpt.ndv <- inpt.train@data[, "ndvi"] - trgt.ndv
      inpt.dst <- uv2ws(inpt.train@coords[, 2] - trgt.nth, 
                        inpt.train@coords[, 1] - trgt.est)
      
      train.out <- data.frame(inpt.tmp, inpt.ele, inpt.asp, inpt.slp, 
                              inpt.ndv, inpt.dst, trgt.tmp)
      return(train.out)
    })
    
    #### 'long' version (1 stations for prediction) ####
    train.table <- train.list[[1]]
    for (l in 2:length(train.list))
      train.table <- rbind(train.table, train.list[[l]])
    
    train.inpt <- scale(train.table[, -length(train.table)], center=T, scale=T) # standardize input data
    train.trgt <- train.table[, length(train.table)]
    
    ann <- newff(c(ncol(train.inpt), 10, 1), learning.rate.global = 0.03, 
                 momentum.global = 0.1, error.criterium = "LMS", Stao = NA, 
                 hidden.layer = "sigmoid", output.layer = "purelin", 
                 method = "ADAPTgdwm")
    
    trainedANN <- train(ann, train.inpt, train.trgt, show.step=1, n.shows=10)
    
    pred.list <- lapply(seq(nrow(stns.pred)), function(m) {
      pred.tmp <- stns.pred@data[m, "Ta_200"]
      pred.ele <- stns.pred@data[m, "elevation"]
      pred.asp <- stns.pred@data[m, "aspect"]
      pred.slp <- stns.pred@data[m, "slope"]
      pred.ndv <- stns.pred@data[m, "ndvi"]
      pred.est <- stns.pred@coords[m, 1]
      pred.nth <- stns.pred@coords[m, 2]
    
      inpt.tmp <- stns.train@data[, "Ta_200"]
      inpt.ele <- stns.train@data[, "elevation"] - pred.ele
      inpt.asp <- stns.train@data[, "aspect"] - pred.asp
      inpt.slp <- stns.train@data[, "slope"] - pred.slp
      inpt.ndv <- stns.train@data[, "ndvi"] - pred.ndv
      inpt.dst <- uv2ws(stns.train@coords[, 2] - pred.nth, 
                        stns.train@coords[, 1] - pred.est)
    
      pred.out <- data.frame(inpt.tmp, inpt.ele, inpt.asp, inpt.slp, 
                             inpt.ndv, inpt.dst, pred.tmp)
      return(pred.out)
    })
    
    pred.table <- pred.list[[1]]
    for (l in 2:length(pred.list))
      pred.table <- rbind(pred.table, pred.list[[l]])
    
    pred.inpt <- scale(pred.table[, -length(pred.table)], center=T, scale=T) # standardize input data
    pred.trgt <- pred.table[, length(pred.table)]
    
    fit <- sim(trainedANN$net, pred.inpt)
    fit <- cbind(fit, rep(1:eval.sample.size, 
                          each = nrow(stns.train)))
    fit <- aggregate(fit[, 1], by = list(fit[, 2]), FUN = mean)
    
    day <- i
    cycle <- j
    
    df.nn <- data.frame(day, cycle, stns.pred$Ta_200, fit$x)
    
    write.table(df.nn, "../../results/nn.output.txt", col.names = FALSE, row.names = FALSE, 
                append = TRUE, sep = ",")
    
    title.nn <- paste("2012", "Day:", i, "Cycle:", j, "AMORE_NN", sep = " ")
    
    scale.min <- min(c(fit$x, stns.pred$Ta_200)) - 1
    scale.max <- max(c(fit$x, stns.pred$Ta_200)) + 1 
    
    scatter.nn <- xyplot(fit$x ~ stns.pred$Ta_200, groups = stns.pred$PlotId,
                         xlim = c(scale.min, scale.max), pch = 19,
                         ylim = c(scale.min, scale.max), asp = "iso",
                         xlab = "observed", ylab = "predicted", main = title.nn,
                         xscale.components = xscale.components.subticks,
                         yscale.components = yscale.components.subticks) +
      layer(panel.ablineq(lm(y ~ x), r.sq = TRUE, rot = FALSE, x = scale.max * 0.5,
                          y = scale.max * 0.9)) +
      #   layer(panel.text(x = x, y = y, labels = stns.pred$PlotId, pos = 1, 
      #                    offset = 1)) +
      layer(panel.abline(a = 0, b = 1, lty = 2, col = "red"))
    
    pdf(paste("../../results/nn.eval", i, j, "pdf", sep = "."), 7, 7)
    trellis.par.set(standard.theme(color = FALSE))
    print(direct.label(scatter.nn, list("smart.grid")))
    dev.off()
    
    
    #### wide version (6 stations for prediction) ####
    input.lst.wide <- lapply(seq(10), function(s) {
      train.sample <- lapply(seq(train.list), function(i) {
        id <- sample(nrow(train.list[[i]]), 15)
        tmp <- train.list[[i]][id, ]
        tmp <- tmp[order(tmp$inpt.dst), ]
        tmp <- tmp[1:6, ]
        names(tmp) <- paste(names(tmp), i, sep = "_")
        return(tmp)
        })
      
      pred.lst.wide <- lapply(seq(train.sample), function(i) {
        pred.table.wide <- train.sample[[i]][, -length(train.sample[[i]])]    
        ma <- as.matrix(pred.table.wide) 
        ma.ls <- split(ma, row(ma))
        tst <- c(unlist(ma.ls), unique(train.sample[[i]][, length(train.sample[[i]])]))
        })
      
      pred.table.wide <- pred.lst.wide[[1]]
      for (l in 2:length(pred.lst.wide))
        pred.table.wide <- rbind(pred.table.wide, pred.lst.wide[[l]])
      
      return(pred.table.wide)
    })

    input.table.wide <- input.lst.wide[[1]]
    for (t in 2:length(input.lst.wide))
      input.table.wide <- rbind(input.table.wide, input.lst.wide[[t]])
    
    train.inpt.wide <- scale(input.table.wide[, -NCOL(input.table.wide)], 
                            center=T, scale=T) # standardize input data
    train.trgt.wide <- input.table.wide[, NCOL(input.table.wide)]
    
    ann <- newff(c(ncol(train.inpt.wide), 10, 1), learning.rate.global = 0.03, 
                 momentum.global = 0.1, error.criterium = "LMS", Stao = NA, 
                 hidden.layer = "sigmoid", output.layer = "purelin", 
                 method = "ADAPTgdwm")
    
    trainedANN <- train(ann, train.inpt.wide, train.trgt.wide, 
                        show.step=1, n.shows=10)
    
    
    pred.lst.wide <- lapply(seq(nrow(stns.pred)), function(m) {
      pred.tmp <- stns.pred@data[m, "Ta_200"]
      pred.ele <- stns.pred@data[m, "elevation"]
      pred.asp <- stns.pred@data[m, "aspect"]
      pred.slp <- stns.pred@data[m, "slope"]
      pred.ndv <- stns.pred@data[m, "ndvi"]
      pred.est <- stns.pred@coords[m, 1]
      pred.nth <- stns.pred@coords[m, 2]
      
      inpt.tmp <- stns.train@data[, "Ta_200"]
      inpt.ele <- stns.train@data[, "elevation"] - pred.ele
      inpt.asp <- stns.train@data[, "aspect"] - pred.asp
      inpt.slp <- stns.train@data[, "slope"] - pred.slp
      inpt.ndv <- stns.train@data[, "ndvi"] - pred.ndv
      inpt.dst <- uv2ws(stns.train@coords[, 2] - pred.nth, 
                        stns.train@coords[, 1] - pred.est)
      
      pred.out <- data.frame(inpt.tmp, inpt.ele, inpt.asp, inpt.slp, 
                             inpt.ndv, inpt.dst, pred.tmp)
      return(pred.out)
    })
    
    pred.lst.wide <- lapply(seq(pred.lst.wide), function(i) {
      tmp <- pred.lst.wide[[i]][order(pred.lst.wide[[i]]$inpt.dst), ]
      tmp <- tmp[1:6, ]
      return(tmp)
    })
    
    pred.lst.wide <- lapply(seq(pred.lst.wide), function(i) {
      tmp <- pred.lst.wide[[i]][, -ncol(pred.lst.wide[[i]])]    
      ma <- as.matrix(tmp) 
      ma.ls <- split(ma, row(ma))
      tst <- c(unlist(ma.ls), 
               unique(pred.lst.wide[[i]][, length(pred.lst.wide[[i]])]))
      return(tst)
    })
    
    pred.table.wide <- pred.lst.wide[[1]]
    for (l in 2:length(pred.lst.wide))
      pred.table.wide <- rbind(pred.table.wide, pred.lst.wide[[l]])
    
    pred.inpt.wide <- scale(pred.table.wide[, -ncol(pred.table.wide)], 
                            center=T, scale=T) # standardize input data
    pred.trgt.wide <- pred.table.wide[, ncol(pred.table.wide)]
    
    fit.wide <- sim(trainedANN$net, pred.inpt.wide)
        
    day <- i
    cycle <- j
    df.nn.wide <- data.frame(day, cycle, stns.pred$Ta_200, fit.wide[, 1])
    
    write.table(df.nn.wide, "../../results/nn.wide.output.txt", col.names = FALSE, row.names = FALSE, 
                append = TRUE, sep = ",")
    
    title.nn.wide <- paste("2012", "Day:", i, "Cycle:", j, "AMORE_NN_wide", sep = " ")
    
    scale.min <- min(c(fit.wide, stns.pred$Ta_200)) - 1
    scale.max <- max(c(fit.wide, stns.pred$Ta_200)) + 1 
    
    scatter.nn.wide <- xyplot(fit.wide ~ stns.pred$Ta_200, groups = stns.pred$PlotId,
                              xlim = c(scale.min, scale.max), pch = 19,
                              ylim = c(scale.min, scale.max), asp = "iso",
                              xlab = "observed", ylab = "predicted", main = title.nn.wide,
                              xscale.components = xscale.components.subticks,
                              yscale.components = yscale.components.subticks) +
      layer(panel.ablineq(lm(y ~ x), r.sq = TRUE, rot = FALSE, x = scale.max * 0.5,
                          y = scale.max * 0.9)) +
      #   layer(panel.text(x = x, y = y, labels = stns.pred$PlotId, pos = 1, 
      #                    offset = 1)) +
      layer(panel.abline(a = 0, b = 1, lty = 2, col = "red"))
    
    pdf(paste("../../results/nn.wide.eval", i, j, "pdf", sep = "."), 7, 7)
    trellis.par.set(standard.theme(color = FALSE))
    print(direct.label(scatter.nn.wide, list("smart.grid")))
    dev.off()
    
################################################################################


###### random forest ###########################################################
    #set.seed(47)
    
    n.tree <- 500
    m.try <- 4
    
    train.inpt <- train.table[, -length(train.table)]
    pred.inpt <- pred.table[, -length(pred.table)]
    
    train.rf <- randomForest(x = train.inpt,
                             y = train.trgt,
                             ntree = n.tree,
                             mtry = m.try,
                             importance = TRUE,
                             keep.forest = TRUE, 
                             do.trace = 100)
    
    ##  predict Rain for new data set
    fit.rf <- predict(train.rf, pred.inpt)
    
    fit.rf <- cbind(fit.rf, rep(1:eval.sample.size, 
                                each = nrow(stns.train)))
    fit.rf <- aggregate(fit.rf[, 1], by = list(fit.rf[, 2]), FUN = mean)
    
    ## writing prediction 
    day <- i
    cycle <- j
    df.rf <- data.frame(day, cycle, stns.pred$Ta_200, fit.rf$x)
    
    write.table(df.rf, "../../results/rf.output.txt", col.names = FALSE, row.names = FALSE, 
                append = TRUE, sep = ",")
    
    title.rf <- paste("2012", "Day:", i, "Cycle:", j, "random Forest", sep = " ")
    
    scale.min <- min(c(fit.rf$x, stns.pred$Ta_200)) - 1
    scale.max <- max(c(fit.rf$x, stns.pred$Ta_200)) + 1 
    
    scatter.rf <- xyplot(fit.rf$x ~ stns.pred$Ta_200, groups = stns.pred$PlotId,
                         xlim = c(scale.min, scale.max), pch = 19,
                         ylim = c(scale.min, scale.max), asp = "iso",
                         xlab = "observed", ylab = "predicted", main = title.rf,
                         xscale.components = xscale.components.subticks,
                         yscale.components = yscale.components.subticks) +
      layer(panel.ablineq(lm(y ~ x), r.sq = TRUE, rot = FALSE, x = scale.max * 0.5,
                          y = scale.max * 0.9)) +
      #   layer(panel.text(x = x, y = y, labels = stns.pred$PlotId, pos = 1, 
      #                    offset = 1)) +
      layer(panel.abline(a = 0, b = 1, lty = 2, col = "red"))
    
    pdf(paste("../../results/rf.eval", i, j, "pdf", sep = "."), 7, 7)
    trellis.par.set(standard.theme(color = FALSE))
    print(direct.label(scatter.rf, list("smart.grid")))
    dev.off()
    
    
  }
}
################################################################################
################################################################################
################################################################################



###### junk ####################################################################
# eval.df <- data.frame(pred = Ta_pred[, 1], obs = stns.pred$Ta_200, 
#                       plot = stns.pred$PlotId)
# 
# scatter <- ggplot(eval.df, aes(pred, obs, colour = plot)) + 
#   geom_point() +
#   scale_colour_brewer(palette = "Paired")
#   
# print(direct.label(scatter, "smart.grid"))

# clrs <- colorRampPalette(c(rev(brewer.pal(11, "Spectral")), "black"))
# plot(krig_result, col.regions = clrs(1000))
################################################################################




###### neural networ approach mit AMORE ########################################
# i <- 1
# j <- 1
# 
# nn.list <- lapply(seq(nrow(stns.pred)), function(k) {
#   trgt.tmp <- stns.pred@data[k, "Ta_200"]
#   trgt.ele <- stns.pred@data[k, "elevation"]
#   trgt.asp <- stns.pred@data[k, "aspect"]
#   trgt.slp <- stns.pred@data[k, "slope"]
#   trgt.ndv <- stns.pred@data[k, "ndvi"]
#   
#   inpt.tmp <- stns.train@data[, "Ta_200"]
#   inpt.ele <- stns.train@data[, "elevation"] - trgt.ele
#   inpt.asp <- stns.train@data[, "aspect"] - trgt.asp
#   inpt.slp <- stns.train@data[, "slope"] - trgt.slp
#   inpt.ndv <- stns.train@data[, "ndvi"] - trgt.ndv
#   
#   out <- data.frame(inpt.tmp, inpt.ele, inpt.asp, inpt.slp, inpt.ndv, trgt.tmp)
#   return(out)
# })
# 
# nn.table <- nn.list[[1]]
# for (l in 2:length(nn.list))
#   nn.table <- rbind(nn.table, nn.list[[l]])
# 
# 
# #trgt <- scale(trgt, center=T, scale=T) # standardize target data
# inpt <- scale(nn.table[, -length(nn.table)], center=T, scale=T) # standardize input data
# trgt <- nn.table[, length(nn.table)]
# 
# ann <- newff(c(5,10,1), learning.rate.global=0.03, momentum.global=0.1, 
#              error.criterium="LMS", Stao=NA, hidden.layer="sigmoid", 
#              output.layer="purelin", method="ADAPTgdwm")
# 
# trainedANN <- train(ann, inpt, trgt, show.step=1, n.shows=1000)
# 
# fit <- sim(trainedANN$net, inpt)
# fit <- cbind(fit, rep(1:10, each = 37))
# fit <- aggregate(fit[, 1], by = list(fit[, 2]), FUN = mean)
# 
# scatter.nn <- xyplot(fit$x ~ unique(trgt), groups = stns.pred$PlotId,
#                      xlim = c(scale.min, scale.max), pch = 19,
#                      ylim = c(scale.min, scale.max), asp = "iso",
#                      xlab = "observed", ylab = "predicted", main = title,
#                      xscale.components = xscale.components.subticks,
#                      yscale.components = yscale.components.subticks) +
#   layer(panel.ablineq(lm(y ~ x), r.sq = TRUE, rot = FALSE, x = scale.max * 0.5,
#                       y = scale.max * 0.9)) +
#   #   layer(panel.text(x = x, y = y, labels = stns.pred$PlotId, pos = 1, 
#   #                    offset = 1)) +
#   layer(panel.abline(a = 0, b = 1, lty = 2, col = "red"))
# 
# pdf(paste("nn.eval", i, j, "pdf", sep = "."), 7, 7)
# trellis.par.set(standard.theme(color = FALSE))
# print(direct.label(scatter.nn, list("smart.grid")))
# dev.off()
# 



###### junk code to test whether ponts and grid overly #########################
# plots <- read.csv("/media/windows/tappelhans/uni/marburg/kili/plots/location_plots.csv")
# coordinates(plots) <- c("Easting", "Northing")
# plots@proj4string@projargs <- "+proj=utm +ellps=clrk80 +zone=37 +units=m +south"
# plots <- plots[, -c(1, 3)]
# ndviplot <- spplot(ki.all, zcol = "elevation")
# pointplot <- spplot(stations, zcol = "Ta_200", col.regions = "black")
# comboplot <- ndviplot + as.layer(pointplot)
# comboplot