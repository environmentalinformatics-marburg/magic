library(RColorBrewer)
library(latticeExtra)
library(sp)
library(raster)

setwd(out)

rgb1<-brick("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/RGB_jpeg/RGB_272.jpeg")
rgb2<-brick("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/RGB_jpeg/RGB_275.jpeg")
rgb3<-brick("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/RGB_jpeg/RGB_484.jpeg")

prob1<-raster("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/predictionProb_272.tif")
prob2<-raster("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/predictionProb_275.tif")
prob3<-raster("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/predictionProb_484.tif")

class1<-raster("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/prediction_272.tif")
class2<-raster("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/prediction_275.tif")
class3<-raster("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/final/out/images/prediction_484.tif")



###class
c1<-spplot(class1,col.regions = colorRampPalette(c("seashell"," darkgreen")),colorkey=F)
c2<-spplot(class2,col.regions = colorRampPalette(c("seashell"," darkgreen")),colorkey=F)
c3<-spplot(class3,col.regions = colorRampPalette(c("seashell"," darkgreen")),colorkey=F)

clist=list(c1,c2,c3)

for (i in 1:3){
nam<- paste("c_", i,  ".jpeg", sep = "")
jpeg(file=nam)
clist[[i]]
dev.off()
}

c1<-update(c1,par.settings=list(superpose.polygon=list(col=c("seashell"," darkgreen"))),
           auto.key = list(text=c("Non Woody","Woody"), 
                           points=FALSE,space="right",rectangles=TRUE,columns=1))

comb_class <- c(c1,c2,c3,layout = c(3,1))


png("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/prepairImages/classification.png",
    width=12,height=5,units = "in",res=300)
print(comb_class)
dev.off()

#### probabilities
prob.colors <-  colorRampPalette(rev(brewer.pal(11,"Spectral")))

sp1<-spplot(prob1*100,
       col.regions = prob.colors(1000), colorkey = list(space = "bottom",at=seq(0,100)))

sp2<-spplot(prob2*100,
       col.regions = prob.colors(1000))
sp3<-spplot(prob3*100,
       col.regions = prob.colors(1000))
comb_prob <- c(sp1,sp2,sp3,layout = c(3,1))


splist=list(sp1,sp2,sp3)

for (i in 1:3){
  nam<- paste("prob_", i,  ".jpeg", sep = "")
  jpeg(file=nam)
  splist[[i]]
  dev.off()
}


png("/home/hanna/Documents/Presentations/LudwigEtAl2015_GoogleImages/prepairImages/prob.png",
    width=12,height=5,units = "in",res=300)
print(comb_prob)
dev.off()

