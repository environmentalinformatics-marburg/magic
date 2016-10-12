dailyrasterpath <- "/media/memory01/data/IDESSA/Results/Predictions/Rate/"
outpath <- "/media/memory01/data/IDESSA/Results/Figures/timeseries/"
dir.create(outpath)

high <- 20
low <- 0

base <- readOGR("/media/memory01/data/IDESSA/auxiliarydata/TM_WORLD_BORDERS-0.3.shp",
                "TM_WORLD_BORDERS-0.3")
filelist <- list.files(dailyrasterpath, pattern="_rainsum.tif$")
for (i in 1:length(filelist)){
ri <- raster(filelist[i])
ri <- projectRaster(ri, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
ri <- mask(ri,base)
png(paste0(outpath,"rainsum_",i,".png"),
    width=15,height=15,units="cm",res = 600,type="cairo")
spplot(ri,col.regions = rev(viridis(high)),at=seq(low,high),
       scales=list(draw=TRUE),
       xlim=c(11.4,36.07),ylim=c(-35.4,-17.1),
       maxpixels=ncell(ri),colorkey = TRUE,
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE))
dev.off()
}
