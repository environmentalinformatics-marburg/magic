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
lm <- raster("/home/hanna/Documents/Projects/IDESSA/Precipitation/skrips/figure_seviri2latlon_rinfo/europe_landsea_mask.rst"
             , native = T, crs = "+proj=longlat +datum=WGS84")

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

y=raster("/home/hanna/Documents/Projects/IDESSA/Precipitation/skrips/meteosat_de/000000000000_00000_ml01danb1_na001_1000_rg01de_003000.rst", 
         native = T, crs = "+proj=longlat +datum=WGS84")
x=raster("/home/hanna/Documents/Projects/IDESSA/Precipitation/skrips/meteosat_de/000000000000_00000_ml02danb1_na001_1000_rg01de_003000.rst", 
         native = T, crs = "+proj=longlat +datum=WGS84")

#load rastervorlage von sagaraster
base=raster(paste(datapath,"/baseRaster_de.tiff",sep=""))#load rastervorlage von sagaraster


###########################
#load obs raster
#######

for (scene in 1:length(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))))){

  obs=as.character(eval(parse(text=paste("prediction_",model[1],"$observed",sep=""))),sep="")[prediction_rf$chDate==unique(prediction_rf$chDate)[scene]]
  obs_recl=obs
  obs[obs=="rain"]=1
  obs[obs=="norain"]=0

  obsRaster=rasterFromXYZ(data.frame(
    eval(parse(text=paste("prediction_",model[1],"$x",sep="")))[eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))==
                                                                unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene]],
    eval(parse(text=paste("prediction_",model[1],"$y",sep="")))[eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))==
                                                                unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene]],
    obs[eval(parse(text=paste("prediction_",model[1],"$chDate",sep="")))==unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene]]))

#############################
#load prediction
#############################
  datc=list()
  datp=list()
  for (i in 1:length(model)){
    
    modeldata=eval(parse(text=paste("prediction_",model[i],sep="")))
    pred=as.character(modeldata$prediction[modeldata$chDate==unique(modeldata$chDate)[scene]])
    pred_recl=pred
    pred[pred_recl=="norain"&obs_recl=="norain"]=0
    pred[pred_recl=="rain"&obs_recl=="rain"]=1
    pred[pred_recl=="rain"&obs_recl=="norain"]=2
    pred[pred_recl=="norain"&obs_recl=="rain"]=3
    pred=as.numeric(pred)

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
    datc[[i]]=rasterize(cbind(values(xRaster),values(yRaster)),base,field=values(tmpPredRaster))


####################################################################################################################
#PLOT
####################################################################################################################
    datc[[i]] <- crop(datc[[i]], ext)
    datp[[i]] <- spplot(datc[[i]], mm= mm, maxpixels = 400000, colorkey = F, main = " ",
               col.regions = colorRampPalette(c("palegreen3"," darkgreen","darkorange","red")),
               #col.regions = colorRampPalette(c(brewer.pal(4,"Greys")[1],brewer.pal(4,"Blues")[2],brewer.pal(4,"Blues")[3],brewer.pal(4,"Blues")[4])),
               at = seq(-0.5, 3.5, 1),
               panel = function(...) {
                 panel.abline(h = yat, v = xat,
                              col = "grey80", lwd = 0.8, lty = 3)
                 panel.levelplot(...)
                 panel.polygon(mm$x, mm$y, border = "grey30", lwd = 0.7)
               }, scales = list(x = list(at = xat, labels = xlabs), 
                                y = list(at = yat, labels = ylabs))
               )

#    datp[[i]]=update(datp[[i]],par.settings=list(superpose.polygon=list(col=c("palegreen3"," darkgreen","darkorange","red"))),
#         auto.key = list(text=c("TN","TP","FP","FN"), points=FALSE,columns=4,rectangles=TRUE),
#         strip = strip.custom(bg = "grey20", 
#                            factor.levels =model[i],
#                            par.strip.text = list(
#                              col = "white", font = 2, cex = 1))
#        )

tmpdate=paste(unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene])
datp[[1]]=update(datp[[1]],par.settings=list(superpose.polygon=list(col=c("palegreen3"," darkgreen","darkorange","red"))),
                 auto.key = list(text=c("TN","TP","FP","FN"), points=FALSE,space="right",rectangles=TRUE), #columns=4
                 strip = strip.custom(bg = "grey20", 
                                      factor.levels =c("rf","nnet","svm"),
                                      par.strip.text = list(
                                        col = "white", font = 2, cex = 1)),
                 main=paste(substr(tmpdate,1,4),"-",substr(tmpdate,5,6),"-",
                            substr(tmpdate,7,8)," ",substr(tmpdate,9,10),":",substr(tmpdate,11,12),sep="")
)


  }
  comb <- c(datp[[1]]+ as.layer(lmplot, under = T), 
            datp[[2]]+ as.layer(lmplot, under = T),
            datp[[3]]+ as.layer(lmplot, under = T), 
            x.same=T, y.same=T, layout = c(3, 1))
  pdf(paste(resultpath,"/Spatial_comp/SpatialComparison_",
            unique(eval(parse(text=paste("prediction_",model[1],"$chDate",sep=""))))[scene],".pdf",sep=""),width=15,height=4.5)
   print(comb)
  dev.off()
}