library(raster)
library(latticeExtra)
library(fields)
library(grid)
library(maps)
library(mapdata)
library(sp)
library(rgdal)
library(RColorBrewer)
library(lattice)

dir.create (paste(resultpath,"/Spatial_comp",sep=""))

#####load predictions!!!!!!!!!
if (any(model=="rf")){
  load(paste(resultpath,"/prediction_rf.RData",sep=""))
}
if (any(model=="nnet")){
  load(paste(resultpath,"/prediction_nnet.RData",sep=""))
}
if (any(model=="svm")){
  load(paste(resultpath,"/prediction_svm.RData",sep=""))
}

######Land sea mask
lm <- raster(paste(datapath,"/europe_landsea_mask.rst",sep=""), 
             native = T, crs = "+proj=longlat +datum=WGS84")

ext <- extent(c(4, 17, 47.0, 54.45))
mm <- map('worldHires', plot = F, fill = T, col = "grey50")

lm <- crop(lm, ext)
lmplot <- spplot(lm, mm = mm, maxpixels = 400000, col.regions = "grey30",
                 colorkey = F, panel = function(..., mm) {
                   panel.levelplot(...)
                   panel.polygon(mm$x, mm$y, col = "grey50", border = "grey30", lwd = 0.1)
                 })

###plot settings
yat = seq(40, 70, 2.5)
ylabs = paste(yat, "°N", sep = "")
xat = seq(0, 100, 2.5)
xlabs = ifelse(xat < 0, paste(xat, "°W", sep = ""), 
               ifelse(xat > 0, paste(xat, "°E", sep = ""), 
                      paste(xat, "°", sep = "")))

#######################
#get x and y coordinates 
#######################

y=raster(paste(datapath,"/000000000000_00000_ml01danb1_na001_1000_rg01de_003000.rst",sep=""), 
         native = T, crs = "+proj=longlat +datum=WGS84")
x=raster(paste(datapath,"/000000000000_00000_ml02danb1_na001_1000_rg01de_003000.rst", sep=""),
         native = T, crs = "+proj=longlat +datum=WGS84")

#load rastervorlage von sagaraster
base=raster(paste(datapath,"/baseRaster_de.tiff",sep=""))#load rastervorlage von sagaraster


###########################
#load obs raster
#######

for (scene in 1:length(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))))){

  obs=eval(parse(text=paste("prediction_",model[1],"$observed",sep="")))[prediction_rf$chDate==unique(prediction_rf$chDate)[scene]]

  
  obsRaster=rasterize(cbind(modeldata$x[modeldata$chDate==unique(modeldata$chDate)[scene]],
                             modeldata$y[modeldata$chDate==unique(modeldata$chDate)[scene]]),x,field=obs)
  
  tmpObsRaster=obsRaster
  values(tmpObsRaster)[!is.na(values(obsRaster))]=1
  xRaster=tmpObsRaster*x
  yRaster=tmpObsRaster*y
  

  obsRasterProj=rasterize(cbind(values(xRaster),values(yRaster)),base,field=values(obsRaster))
  
  obsRasterProj <- crop(obsRasterProj, ext)
  
  datc=list()
  datp=list()
  diff=list()
  diffp=list()
  maxobs=max(values(obsRasterProj),na.rm=T)
  datc[[1]]=obsRasterProj
  datp[[1]] <- spplot(datc[[1]], mm= mm, maxpixels = 400000, colorkey = list(space = "top", width = 0.5,title="test"), main = " ",
                      col.regions = colorRampPalette(c(brewer.pal(4,"Greys")[1],brewer.pal(4,"Blues")[2],brewer.pal(4,"Blues")[3],brewer.pal(4,"Blues")[4])),
                      at = seq(-0, maxobs, 0.1),
                      panel = function(...) {
                        panel.abline(h = yat, v = xat,
                                     col = "grey80", lwd = 0.8, lty = 3)
                        panel.levelplot(...)
                        panel.polygon(mm$x, mm$y, border = "grey30", lwd = 0.7)
                      }, scales = list(x = list(at = xat, labels = xlabs), 
                                       y = list(at = yat, labels = ylabs))
  )
  
#############################
#load prediction
#############################

  for (i in 1:length(model)){
    
    modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))
    pred=modeldata$prediction[modeldata$chDate==unique(modeldata$chDate)[scene]]

#############################
#rasterize prediction
#############################

    predRaster=rasterize(cbind(modeldata$x[modeldata$chDate==unique(modeldata$chDate)[scene]],
                     modeldata$y[modeldata$chDate==unique(modeldata$chDate)[scene]]),x,field=pred)



    values(base)=NA

    tmpPredRaster=predRaster
    values(predRaster)[!is.na(values(predRaster))]=1
    xRaster=predRaster*x
    yRaster=predRaster*y


  #update base raster:
    datc[[i+1]]=rasterize(cbind(values(xRaster),values(yRaster)),base,field=values(tmpPredRaster))


####################################################################################################################
#PLOT
####################################################################################################################
    datc[[i+1]] <- crop(datc[[i+1]], ext)
    datp[[i+1]] <- spplot(datc[[i+1]], mm= mm, maxpixels = 400000, colorkey = list(space = "top", width = 0.5), main = " ",
               col.regions = colorRampPalette(c(brewer.pal(4,"Greys")[1],brewer.pal(4,"Blues")[2],brewer.pal(4,"Blues")[3],brewer.pal(4,"Blues")[4])),
               at = seq(0, maxobs, 0.1),
               panel = function(...) {
                 panel.abline(h = yat, v = xat,
                              col = "grey80", lwd = 0.8, lty = 3)
                 panel.levelplot(...)
                 panel.polygon(mm$x, mm$y, border = "grey30", lwd = 0.7)
               }, scales = list(x = list(at = xat, labels = xlabs), 
                                y = list(at = yat, labels = ylabs))
               )



########################################################################################
# DIFFs
########################################################################################
diff[[i]]=datc[[1]]-datc[[i+1]]
diffp[[i]] <- spplot(diff[[i]], mm= mm, maxpixels = 400000, colorkey = list(space = "top", width = 0.5), main = " ",
                      col.regions = colorRampPalette(c("blue","white","red")),
                      at = seq(-max(abs(values(diff[[i]])),na.rm=T), max(values(diff[[i]]),na.rm=T), 0.1),
                      panel = function(...) {
                        panel.abline(h = yat, v = xat,
                                     col = "grey80", lwd = 0.8, lty = 3)
                        panel.levelplot(...)
                        panel.polygon(mm$x, mm$y, border = "grey30", lwd = 0.7)
                      }, scales = list(x = list(at = xat, labels = xlabs), 
                                       y = list(at = yat, labels = ylabs))
)



  }

tmpdate=paste(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene])
datp[[1]]=update(datp[[1]],strip = strip.custom(bg = "grey20", 
                                                factor.levels =c("observed [mm/1h]","rf [mm/1h]","nnet[mm/1h]","svm[mm/1h]"),
                                                par.strip.text = list(
                                                  col = "white", font = 2, cex = 1)),
                 main=paste(substr(tmpdate,1,4),"-",substr(tmpdate,5,6),"-",
                            substr(tmpdate,7,8)," ",substr(tmpdate,9,10),":",substr(tmpdate,11,12),sep="")
)


diffp[[1]]=update(diffp[[1]],strip = strip.custom(bg = "grey20", 
                                                  factor.levels =c("rf[mm/1h]","nnet[mm/1h]","svm[mm/1h]"),
                                                  par.strip.text = list(
                                                    col = "white", font = 2, cex = 1)),
                  main=paste(substr(tmpdate,1,4),"-",substr(tmpdate,5,6),"-",
                             substr(tmpdate,7,8)," ",substr(tmpdate,9,10),":",substr(tmpdate,11,12),sep="")
)



  comb <- c(datp[[1]]+ as.layer(lmplot, under = T), 
            datp[[2]]+ as.layer(lmplot, under = T),
            datp[[3]]+ as.layer(lmplot, under = T), 
            datp[[4]]+ as.layer(lmplot, under = T),
            x.same=T, y.same=T, layout = c(4, 1))
  pdf(paste(resultpath,"/Spatial_comp/SpatialComparison_",
            unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],".pdf",sep=""),width=15,height=4.5)
   print(comb)
  dev.off()

  combDiff <- c(diffp[[1]]+ as.layer(lmplot, under = T), 
                diffp[[2]]+ as.layer(lmplot, under = T),
                diffp[[3]]+ as.layer(lmplot, under = T),
          x.same=T, y.same=T, layout = c(3, 1))

  pdf(paste(resultpath,"/Spatial_comp/Diff_",
          unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],".pdf",sep=""),width=15,height=4.5)
  print(combDiff)
  dev.off()
}


