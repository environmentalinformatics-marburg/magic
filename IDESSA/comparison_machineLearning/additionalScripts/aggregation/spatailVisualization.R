rm(list=ls())
usedPackages=c("raster","latticeExtra","fields","reshape2","grid","maps","mapdata","sp","rgdal","RColorBrewer","lattice")
lapply(usedPackages, library, character.only=T)



datapath="/media/hanna/ubt_kdata_0005/pub_rapidminer/input/"
aggregationDataPath="/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation/day/"
resultpath="/media/hanna/ubt_kdata_0005/pub_rapidminer/aggregation"

scene=c("rf/24h/20100506_24h.rst","nnet/24h/20100506_24h.rst","avNNet/24h/20100506_24h.rst","svm/24h/20100506_24h.rst")
observed="radolan/24h/20100506_24h.rst"
model=c("rf","nnet","avNNet","svm")

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


scene=stack(paste0(aggregationDataPath,scene))
observed=raster(paste0(aggregationDataPath,observed))
prediction=rasterize(cbind(coordinates(scene)[,1],coordinates(scene)[,2]), x,field=values(scene))
observed=rasterize(cbind(coordinates(observed)[,1],coordinates(observed)[,2]), x,field=values(observed))


tmpObsRaster=observed
values(tmpObsRaster)[!is.na(values(observed))]=1
xRaster=tmpObsRaster*x
yRaster=tmpObsRaster*y


observedProj=rasterize(cbind(values(xRaster),values(yRaster)),base,field=values(observed))
predictionProj=rasterize(cbind(values(xRaster),values(yRaster)),base,field=values(prediction))


observedProj <- crop(observedProj, ext)
predictionProj <- crop(predictionProj, ext)

observedProj[observedProj==0]=NA
predictionProj[predictionProj==0]=NA


mk.colors <- colorRampPalette(rev(brewer.pal(11,"Spectral")))



  datp=list()

  maxobs=max(values(observedProj),na.rm=T)

  datp[[1]] <- spplot(observedProj, mm= mm, maxpixels = 400000, colorkey = list(space = "top", width = 0.5,title="test"), main = " ",
                      col.regions =mk.colors(1000), 
                      #col.regions = colorRampPalette(c(brewer.pal(4,"Greys")[1],brewer.pal(4,"Blues")[2],brewer.pal(4,"Blues")[3],brewer.pal(4,"Blues")[4])),
                      at = seq(-0, maxobs, 0.1),
                      panel = function(...) {
                        panel.abline(h = yat, v = xat,
                                     col = "grey80", lwd = 0.8, lty = 3)
                        panel.levelplot(...)
                        panel.polygon(mm$x, mm$y, border = "grey30", lwd = 0.7)
                      }, scales = list(x = list(at = xat, labels = xlabs), 
                                       y = list(at = yat, labels = ylabs))
  )
  
  


  
  for (i in 1:length(model)){
    
    datp[[i+1]] <- spplot(predictionProj[[i]], mm= mm, maxpixels = 400000, colorkey = list(space = "top", width = 0.5), main = " ",
                          col.regions = mk.colors(1000),
                          at = seq(0, maxobs, 0.1),
                          panel = function(...) {
                            panel.abline(h = yat, v = xat,
                                         col = "grey80", lwd = 0.8, lty = 3)
                            panel.levelplot(...)
                            panel.polygon(mm$x, mm$y, border = "grey30", lwd = 0.7)
                          }, scales = list(x = list(at = xat, labels = xlabs), 
                                           y = list(at = yat, labels = ylabs))
    )
     
    
  }
  
  
datp[[1]]=update(datp[[1]],strip = strip.custom(bg = "grey20", 
                                                  factor.levels =paste0(c("observed",model),"[mm/1h]"),
                                                  par.strip.text = list(
                                                    col = "white", font = 2, cex = 1)))
                
  
####for publication
datp[[2]]=update(datp[[2]],strip = strip.custom(bg = "grey20", 
                                                  factor.levels =paste0(c(model,"observed"),"[mm/1h]"),
                                                  par.strip.text = list(
                                                    col = "white", font = 2, cex = 1)),main="")
comb <- c(datp[[2]]+ as.layer(lmplot, under = T),datp[[3]]+ as.layer(lmplot, under = T), 
            datp[[4]]+ as.layer(lmplot, under = T),datp[[5]]+ as.layer(lmplot, under = T),
            datp[[1]]+ as.layer(lmplot, under = T),
            x.same=T, y.same=T, layout = c(2,3))
tiff(paste(resultpath,"/SpatialComparison_pub.tiff",sep=""),
       width=12,height=12,units = "in",res=400,compression = "lzw")
print(comb)
dev.off()



