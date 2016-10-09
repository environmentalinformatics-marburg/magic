###plot Predictions
library(raster)
library(RColorBrewer)
setwd("/home/hanna/Dropbox/paper_biomasse/aktuelles/")
rgb<- brick("rgbPlots/ID_14.png")

vegcover <- raster("predictions/vegcover/ID_14_sat_1.tif")
biomass <- raster("predictions/biomass/ID_14_sat_1.tif")

#plot(biomass, col=colorRampPalette(brewer.pal(9,"YlGn"))(200))

imagedata <- brick("/home/hanna/Dropbox/paper_biomasse/aktuelles/imagepreparation/VielSpass/albedo_qb.raw")
imagedata_stretch <- stretch(imagedata, minv=0, maxv=255)



pdf("/home/hanna/Dropbox/paper_biomasse/manuscript/figures/predSpatial.pdf",width=10,height=5)
par(mfrow=c(1,2))
plot(vegcover, col=rev(colorRampPalette(brewer.pal(11, "Spectral"))(50)),asp=0)
plot(biomass, col=rev(colorRampPalette(brewer.pal(11, "Spectral"))(50)),asp=0)
dev.off()

pdf("/home/hanna/Documents/Presentations/Paper/PaDeMoS Paper/imagepreparation/rgb.pdf",width=7.4,height=6)
par(mar=c(4,6,2,4))
plotRGB(imagedata_stretch,r=4,g=3,b=2,asp=0,axes=T,stretch="hist")
dev.off()


