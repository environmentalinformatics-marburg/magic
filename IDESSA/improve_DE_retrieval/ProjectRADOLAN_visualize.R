library(raster)


rw <- raster("/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_RGrid/2010/10/16/201010161150_raa01_rw.rst")
msg <- raster("/media/hanna/ubt_kdata_0005/pub_rapidminer/mt09s_agg1h/2010/10/16/11/201010161150_mt09s_ca02p0002_m1hct_1000_rg01de_003000.rst")
rwcompareMeike <- raster("/media/hanna/ubt_kdata_0005/pub_rapidminer/radar/radolan_rst_SGrid/2010/10/16/201010161150_radolan_SGrid.rst")
msgcompareMeike <- msg

#adapt rw values
rw<-rw/10

#create template
#documents:software:  
#python testWradlib.py /home/hanna/Downloads/RW201401/raa01-rw_10000-1401010050-dwd---bin.gz /home/hanna/Downloads/RW201401/testetstetst.tif
#template_rw<-raster(ergebnis davon)
template_rw <- raster("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/templates/raa01-rw_10000-1005312050.tif")
template_msg <- raster("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/templates/201010101150_mt09s_B0103xxxx_m1hct_1000_rg01de_003000.rst")
proj4string(template_msg) <- "+proj=geos +lon_0=0 +h=35785831 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"


# use template information
extent(msg) <- extent(template_msg)
proj4string(msg) <- proj4string(template_msg)
extent(rw) <- extent(template_rw)
proj4string(rw) <- proj4string(template_rw)


#Radolan to MSG Projection and resolution
rwproj <- projectRaster(rw, crs=proj4string(msg))
rwproj <- resample(rwproj, msg)

################################################################################
#Plot and compare data
################################################################################
pdf("/home/hanna/Documents/Projects/IDESSA/Precipitation/improve_DE_retrieval/newProjection.pdf")
rw[rw<0.06] <- NA
plot(rw,main="original RADOLAN data (mm/h)",zlim=c(0,10))

msg[msg<0]=NA
rwproj[rwproj<0.06]=NA
plot(msg,col=grey.colors(250),legend=FALSE,main="new Solution (mm/h)")
plot(rwproj,add=TRUE,zlim=c(0,10))

msgcompareMeike[msgcompareMeike<0]=NA
rwcompareMeike[rwcompareMeike<0.06]=NA
plot(msgcompareMeike,col=grey.colors(250),legend=FALSE, main="old solution (mm/h)")
plot(rwcompareMeike,add=TRUE,zlim=c(0,10))

plot(density(values(rwcompareMeike)[!is.na(values(rwcompareMeike))],bw=0.15),
     ylim=c(0,1.3),main="Densities")
lines(density(values(rwproj)[!is.na(values(rwproj))],bw=0.15),col="red")
lines(density(values(rw)[!is.na(values(rw))],bw=0.15),col="blue",lty=2)
legend("topright",col=c("black","red","blue"),
       legend=c("alt","neu","RADOLAN original"),lwd=1,bty="n",lty=c(1,1,2))

dev.off()



