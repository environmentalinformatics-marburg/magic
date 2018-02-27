library(raster)
library(viridis)
library(latticeExtra)
library(rgdal)
datapath <- "/media/hanna/data/IDESSA_TAIR/spatialpred_daily/"
figurepath <- "/home/hanna/Documents/Presentations/Paper/in_prep/TairSouthAfrica/figures/"
setwd(datapath)

base <- readOGR("/home/hanna/Documents/Projects/IDESSA/GIS/TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp",
                "TM_WORLD_BORDERS-0.3")

fls <- list.files(,pattern="^averageT_2013")

dat <- list()
for (i in unique(substr(fls,10,15))){
  dat[[i]] <- mean(stack(fls[grepl(i,fls)]),na.rm=TRUE)
}


dats <- stack(unlist(dat))
dats <- projectRaster(dats,crs=projection(base))
dats <- crop(dats,c(16,34,-35.5,-21))
names(dats) <- c("January","February","March","April","May",
                 "June","July","August","September",
                 "October","November","December")

png(paste0(figurepath,"/spatialpreds.png"), width=13,height=10,units="cm",
    res = 500,type="cairo")
spplot(dats,col.regions=viridis(100),
       maxpixels=ncell(dats[[1]]*0.2),
       colorkey = list(at=seq(min(values(dats),na.rm=TRUE),
                              max(values(dats),na.rm=TRUE),by=0.5)),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE),
       par.settings = list(strip.background=list(col="lightgrey")))
trellis.focus("toplevel",highlight = FALSE)
panel.text(0.893, 0.5, "Modelled air temperature (°C)", 
           cex = 0.85,srt=270)
dev.off()
