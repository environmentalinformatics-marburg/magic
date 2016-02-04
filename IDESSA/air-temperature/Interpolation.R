#Interpolation


library(automap)
loadMeuse()

plot(meuse)
data(meuse)
# Ordinary kriging
kriging_result = autoKrige(zinc~1, meuse, meuse.grid)
plot(kriging_result)
# Universal kriging
kriging_result = autoKrige(zinc~soil+ffreq+dist, meuse, meuse.grid)
plot(kriging_result)

##############################
##############################
##############################
full <- read.csv("E:/IDESSA/data/stichprobe/gesamt/gesamt.csv")

#NA entfernen
full <- na.omit(full)

full$x <- full$lon
full$y <- full$lat
## inverse distance weighted (IDW)
r <- raster(system.file("external/test.grd", package="raster"))
plot(r)

data(meuse)

t <- as.data.frame(extract(lst[[1]], clim))
t <- cbind(cli, t)
t$temp <- t[,4]
t$temp[t$temp == 0] <- NA

t[,4] <- NULL
t$temp <- t$temp*0.02-273.15

#t <- na.omit(t)
mg <- gstat(id = "temp", formula = temp~1, locations = ~x+y, 
            data=t, nmax=7, set=list(idp = 0.5))

z <- interpolate(raster(), mg, ext = extent(clim), na.rm = T)

spplot(z) + as.layer(spplot(af, col.regions="transparent"))# + as.layer(spplot(clim))


## kriging
coordinates(t) <- ~x+y
projection(t) <- projection(clim)
plot(t)

values(z) <- 0
spplot(z)
projection(z) <- projection(clim)

## ordinary kriging
v <- variogram(temp~1, t)
m <- fit.variogram(v, vgm(1, "Sph", 300, 1))
gOK <- gstat(id = "temp", formula = temp~1, data = t, model=m)
OK <- interpolate(z, gOK)
spplot(OK)
