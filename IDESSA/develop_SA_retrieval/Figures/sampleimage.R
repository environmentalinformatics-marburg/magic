setwd("/home/hanna/Documents/Presentations/Paper/in_prep/Meyer2016_SARetrieval/figureDrafts/sampleimage/")
base <- readOGR("/media/hanna/data/CopyFrom181/auxiliarydata/TM_WORLD_BORDERS-0.3.shp",
                "TM_WORLD_BORDERS-0.3")

IMERG <- stack(list.files(,pattern=glob2rx("IMERG*tif$")))

rate <- stack(list.files(,pattern=glob2rx("rate*tif$")))
MSG <- stack(list.files(,pattern=glob2rx("msgdat*tif$")))
#IMERG <- mask(IMERG,MSG$msgdat_2014042410.5)
IMERG[IMERG<=0] <- NA 
stck <- stack(rate,IMERG)
stck <- projectRaster(stck, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
MSG <- projectRaster(MSG, crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
base <- crop(base,stck)

spplot(stck,col.regions = rev(viridis(100)),
       scales=list(draw=FALSE,x=list(rot=90)),#x=list(rot=90)
       at=seq(0.0,5.0,by=0.2),
       xlim=c(11.4,36.2),ylim=c(-35.4,-17),
       maxpixels=ncell(stck)*0.6,
      # colorkey = list(at=seq(0,max(values(monthly),na.rm=TRUE))),
       par.settings = list(strip.background=list(col="lightgrey")),
       sp.layout=list("sp.polygons", base, col = "black", first = FALSE))


plotRGB(MSG,r=2,g=4,b=9,stretch="lin")
plot(base,add=T)


