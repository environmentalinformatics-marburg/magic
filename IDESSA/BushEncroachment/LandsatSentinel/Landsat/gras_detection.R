
#GRAS DETECTION

require(spatialEco)
require(raster)
require(rgdal)
require(satellite)
require(RStoolbox)

main <- "F:/HK_Geoinfo/data/gras/"
tiles <- c(173078, 173079, 174078)

a <- list.files(main, pattern="T1$", full.names = T)
files <-list(a[c(1,3,5)], a[c(2,4,6)])

#list with: [[szenes]][[tiles]][[bands]]
stc <- lapply(seq(files), function(i){
        lapply(seq(files[[1]]), function(j){
          x <- list.files(files[[i]][[j]], pattern=".TIF$", full.names = T)
          x <- x[4:9]
          stack(x)
        })
      })

dirnam <- "ac"
sdirs <- list.files(paste0(main, "workflow/"), full.names = T)

md <- lapply(seq(2), function(i){
  paste0(sdirs[i], c("/173078", "/173079", "/174078"), "/run/")})

# md <- unlist(md)
# # 
# # MAKE SUBDIRECTORIES
# lapply(seq(md), function(l){
#   mainDir <- md[l]
#   subDir <- dirnam
#   if (file.exists(subDir) == FALSE){
#     dir.create(file.path(mainDir, subDir))}
# })
# 
# 
# lapply(seq(sdirs), function(l){
#   mainDir <- sdirs[l]
#   subDir <- c("/173078", "/173079", "/174078")
#   for(j in seq(3)){
#     if (file.exists(subDir[j]) == FALSE){
#     dir.create(file.path(mainDir, subDir[j]))}
#   }
# })


dirnam <- list.files(paste0(main, "workflow"), full.names=T)

########### DATA PREPARATION ############
newproj <- "+proj=utm +zone=34 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

#1=dry
#2=rainy
for(j in seq(2)){ #Szenen
  for(i in seq(3)){ #Kacheln
    for (l in seq(6)){ #Bänder
      writeto <- paste0(dirnam[j], c("/173078", "/173079", "/174078"))
      rstp <- projectRaster(stc[[j]][[i]][[l]], crs=newproj)
      writeRaster(rstp, paste0(writeto[i],"/", filename=names(stc[[j]][[i]][[l]])), format="GTiff", overwrite=T)
      #stc: Kacheln, Szenen, Bänder
      print(c(j,i,l))
      flush.console()
    }
    logx <- "projected"
    write.csv(logx, file=paste0(writeto[i],"/", "log.txt"))
  }
}

st <- NULL
fst <- lapply(seq(2), function(i){
  st <- lapply(seq(3), function(j){
    f <- list.files(paste0(dirnam[i], "/", tiles[j], "/"), pattern=".tif$", full.names = T)
    stack(f)
  })
})

#crop by molopo 
sh_mol <- "F:/HK_Geoinfo/data/Molopo-shape/"
molopo <- readOGR(dsn=paste0(sh_mol,"study_area.shp"))


for(i in seq(2)){
  for(j in seq(3)){
    writeto <- md[[i]][[j]]
    cr <- raster::crop(fst[[i]][[j]], molopo)
    for (l in seq(nlayers(cr))){ 
      writeRaster(cr[[l]], paste0(md[[i]][[j]],
                                  filename=names(stc[[i]][[j]][[l]])), format="GTiff", overwrite=T)
      #stc: Kacheln, Szenen, Bänder
      print(c(i,j,l))
      flush.console()
    }
    logx <- "cropped molopo"
    write.csv(logx, file=paste0(writeto, "log.txt"))
  }
}

st <- NULL
fst <- lapply(seq(2), function(i){
  st <- lapply(seq(3), function(j){
    f <- list.files(paste0(dirnam[i], "/", tiles[j], "/run"), pattern=".tif$", full.names = T)
    stack(f)
  })
})

#metadata
lapply(seq(2), function(i){
  lapply(seq(3), function(j){
    file.copy(list.files(files[[i]][[j]], pattern="MTL.txt", full.names = T),
                paste0(md[[i]][[j]]), overwrite=T)
  })
})

#set 0 values NA
lapply(seq(2), function(i){
  lapply(seq(3), function(j){
    for (l in seq(nlayers(fst[[i]][[j]]))){
      nam <- names(fst[[i]][[j]][[l]])
      fst[[i]][[j]][[l]][fst[[i]][[j]][[l]] <= 0]<- NA
      writeRaster(fst[[i]][[j]][[l]], 
                  paste0(md[[i]][[j]],filename=nam), 
                  format="GTiff", overwrite=T)
      print(c(i,j,l))}
    logx <- "<=0 = NA"
    write.csv(logx, file=paste0(writeto, "log.txt"))
  })
})

st <- NULL
fst <- lapply(seq(2), function(i){
  st <- lapply(seq(3), function(j){
    f <- list.files(paste0(dirnam[i], "/", tiles[j], "/run"), pattern=".tif$", full.names = T)
    stack(f)
  })
})

acto <- lapply(seq(2), function(i){
  paste0(sdirs[i], c("/173078", "/173079", "/174078"), "/ac/")})

#atmosphärenkorrektur
yi <- c(13:18)
i=2
j=1
for(i in seq(2)){ #scenes
  #for(j in c(2,3)){ #j 3 tiles
    tl <- md[[i]][[j]]
    setwd(tl)
    tb <- list.files(tl, pattern=".tif$", full.names = T)
    #met <- list.files(tl, pattern="MTL.txt", full.names=T)
    # metf <- compMetaLandsat(tb[3:8])
    # sttb <- lapply(c(3:8), function(x){
    #   raster(tb[[x]])
    # })
    tbsat <- satellite(tb)
    atmd <- calcAtmosCorr(tbsat, model = "DOS2", esun_method = "RadRef")
    print(c("atmd", j, i)) #tile, scene
    acst <- lapply(seq(yi), function(y){
      atmd@layers[[yi[y]]]
    })
    for(x in seq(length(acst))){
      writeRaster(acst[[x]], paste0(acto[[i]][[j]],filename=paste0(substring(names(acst[[x]]), 1,5), "_new")),
                  format="GTiff", overwrite=T)
    }
    print(c("writeras", j, i))
  #}
}

#dry=1, rainy=2
st <- NULL
fst <- lapply(seq(2), function(i){
  st <- lapply(seq(3), function(j){
    f <- list.files(paste0(dirnam[i], "/", tiles[j], "/ac"), pattern=".tif$", full.names = T)
    stack(f)
  })
})

plot(fst[[1]])

# plotRGB(fst[[1]][[1]], r=3, g=2, b=1, stretch="lin")
# plotRGB(fst[[1]][[2]], r=3, g=2, b=1, stretch="lin", add=T)
# plotRGB(fst[[1]][[3]], r=3, g=2, b=1, stretch="lin", add=T)
# 
# plotRGB(fst[[2]][[1]], r=3, g=2, b=1, stretch="lin")
# plotRGB(fst[[2]][[2]], r=3, g=2, b=1, stretch="lin", add=T)
# plotRGB(fst[[2]][[3]], r=3, g=2, b=1, stretch="lin", add=T)

#histogram matching (1=dry, 2=rainy)
hmdir <- paste0(sdirs, "/hm/")

hm2 <- NULL
hm3 <- NULL
lapply(seq(2), function(i){ #für alle Szenen
  lapply(seq(nlayers(fst[[i]][[1]])), function(j){ #für alle ac-korrigierten Bänder 
    hm2 <- histMatch(x=fst[[i]][[2]][[j]], ref=fst[[i]][[1]][[j]])
    writeRaster(hm2, paste0(hmdir[i], "t", i, "_hm2_l", j), format="GTiff", overwrite=T)
    print(c("hm2", i, j))
    hm3 <- histMatch(x=fst[[i]][[3]][[j]], ref=fst[[i]][[1]][[j]])
    writeRaster(hm3, paste0(hmdir[i], "t", i, "_hm3_l", j), format="GTiff", overwrite=T)
    print(c("hm3", i, j))
  })
})

#(1=dry, 2=rainy)
f <- list.files(hmdir)
sc <- NULL
sc <- lapply(seq(2), function(j){
  scene <- f[substr(f,2,2)==j]
  scene <- paste0(hmdir[j], scene)
})

#til[[1]] <- dry, til[[2]]<-rainy
til <- lapply(seq(2), function(j){
  t2 <- stack(sc[[j]][1:6])
  t3 <- stack(sc[[j]][7:12])
  return(list(t2,t3))
})


#mosaics
lapply(seq(2), function(i){
  lapply(seq(6), function(j){
    mo <- mosaic(fst[[i]][[1]][[j]], til[[i]][[1]][[j]], til[[i]][[2]][[j]], fun=mean)
    writeRaster(mo, paste0(main, "mosaics/mo_hm_", i, "_b", j), format="GTiff", overwrite=T)
  })
})

#########  INPUT PREPARED DATA ########

#read finished data:
#mo_hm_2_b5 <- 2 = rainy
f <- list.files(paste0(main, "mosaics/"), pattern=paste0("mo_hm"), full.names=T)
moscs <- lapply(seq(f), function(i){
  raster(f[i])
})

dry <- stack(moscs[1:6])
rainy <- stack(moscs[7:12])

acdat <- list(dry, rainy) #acdat ist später neu erstellt

#ndvi #mit atmosphärenkorrigierten Daten, alles unter 
#Stelle 1: 24.4.13/01.05.13 -> rainy
#Stelle 2:  05.08.13/14.08.13 -> dry

#läuft! 1 -> rainy 2 -> dry ###falschrum im Ordner, in workflow/dry sind rainys
ndvi_ac <- lapply(seq(2), function(i){ #Szenen
    za <- acdat[[i]][[4]]-acdat[[i]][[3]]
    ne <- acdat[[i]][[4]]+acdat[[i]][[3]]
    ndvi <- za/ne
})

ndvi_ac[[1]][ndvi_ac[[1]]>1] <- NA
ndvi_ac[[1]][ndvi_ac[[1]]<(-1)] <- NA

ndvi_ac[[2]][ndvi_ac[[2]]>1] <- NA
ndvi_ac[[2]][ndvi_ac[[2]]<(-1)] <- NA

plot(ndvi_ac[[1]])
plot(ndvi_ac[[2]])

writeRaster(ndvi_ac[[1]], paste0(main, "mosaics/ndvi_ges_rainy"), format="GTiff", overwrite=T)
writeRaster(ndvi_ac[[2]], paste0(main, "mosaics/ndvi_ges_dry"), format="GTiff", overwrite=T)


ndvi_ac[[1]][ndvi_ac[[1]]<0] <- NA
ndvi_ac[[2]][ndvi_ac[[2]]<0] <- NA

par(mfrow=c(1,2))
plot(ndvi_ac[[1]], main="dry")
plot(ndvi_ac[[2]], main="rainy")

ndvi_rainy <- raster(paste0(main, "mosaics/ndvi_ges_rainy.tif"))
ndvi_dry <- raster(paste0(main, "mosaics/ndvi_ges_dry.tif"))

load(paste0("F:/HK_Geoinfo/model_landsat/landsatmodel.RData"))
modnam <- c("b_dry","g_dry","r_dry","NIR_dry",
            "SWIR1_dry","SWIR2_dry","b_rainy","g_rainy",
            "r_rainy","NIR_rainy","SWIR1_rainy","SWIR2_rainy",
            "NDVI_dry","NDVI_rainy")

#make stack with predictors
inputpred <- stack(dry, rainy, ndvi_dry, ndvi_rainy)
names(inputpred) <- modnam

#predict
#total
testpred <- predict(inputpred, model, filename="graspred13.tif",
                    progress="window", overwrite=T)

writeRaster(testpred, filename = paste0(main,"graspred13_2.tif"), format="GTiff", overwrite=T)
testpred <- raster(paste0(main,"graspred13_2.tif"))

#### GRAS #####

# lm(preddry~ndvidry)
#extract values and write csvs.

#se <- drawExtent()
#predsmall <- crop(testpred, se)
#writeRaster(predsmall, paste0(main, "small_extent_prediction.tif"), format="GTiff", overwrite=T)

ndvi_rainy[ndvi_rainy<0]<-NA
ndvi_dry[ndvi_dry<0]<-NA

par(mfrow=c(2,2))
plot(ndvi_rainy, main="NDVI rainy")
plot(ndvi_dry, main="NDVI dry")
plot(testpred, main="Bush prediction (%)")

e <- extent(testpred)
spred <- extract(testpred, e)
sndvid <- extract(ndvi_dry, e)
sndvir <- extract(ndvi_rainy, e)

write.csv(sndvir, file=paste0(main, "extr_ndvi_rainy.csv"))
write.csv(spred, file=paste0(main, "extr_prediction.csv"))
write.csv(sndvid, file=paste0(main, "extr_ndvi_dry.csv"))

spred <- read.csv(paste0(main, "extr_prediction.csv"))
sndvid <- read.csv(paste0(main, "extr_ndvi_dry.csv"))
sndvir <- read.csv(paste0(main, "extr_ndvi_dry.csv"))

dat <- data.frame(spred, sndvid, sndvir)

#dat <- data.frame(spred$x, sndvid$x, sndvir$x)
#dat <- data.frame(spred, sndvi, sndvir)

#make smaller sample
samp <- sample(seq(0:nrow(dat)), 2000000)
sampdat <- dat[samp,]
head(sampdat)

# #check how ndvi is working out
# se_ndvi_r <- crop(ndvi_rainy, se)
# se_ndvi_d <- crop(ndvi_dry, se)

# se_ndvi_r[se_ndvi_r<0]<-NA
# se_ndvi_d[se_ndvi_r<0]<-NA


#display
require(hexbin)
require(RColorBrewer)
rf <- colorRampPalette(rev(brewer.pal(11,'Spectral')))

#dry
df <- data.frame(sampdat$sndvid, sampdat$spred)
h <- hexbin(df, xbins=100)
plot(h, colramp=rf, main="lm dry season", xlab="NDVI_dry", ylab="bush prediction model")

# #rainy
# df <- data.frame(dat$sndvir, dat$spred)
# h <- hexbin(df)
# plot(h, colramp=rf, main="lm rainy season", xlab="NDVI_rainy", ylab="bush prediction model")

####LINEAR MODELs#######
#lm dry
moddry <- lm(sampdat$spred~sampdat$sndvid)
summary(moddry)
par(mfrow=c(1,1))
plot(sampdat$sndvid, sampdat$spred, main="lm dry", xlab="ndvi_dry", ylab="bush %",
     pch="19", cex=.1)
abline(moddry[[1]][[1]], moddry[[1]][[2]], col="red")

# #lm rainy
# modr <- lm(dat$spred~dat$sndvir)
# summary(modr)

# plot(dat$sndvir, dat$spred, main="lm rainy (small extent)", xlab="ndvi_rainy", ylab="bush %",
#      pch="19", cex=.1)
# abline(modr[[1]][[1]], modr[[1]][[2]], col="green")



# AB HIER

#prediction of bushes trained in dry season to rainy season 
lmdryrainy <- moddry[[1]][[1]]+ndvi_rainy*moddry[[1]][[2]]
writeRaster(lmdryrainy, paste0(main, "lmdryrainy.tif"), format="GTiff", overwrite=T)
plot(lmdryrainy, main="application of lm dry to NDVI_rainy")


#no extrapolation

lmdryrainy[lmdryrainy>1]<-1
lmdryrainy[lmdryrainy<0]<-0

par(mfrow=c(1,1))
plot(lmdryrainy, main="application of lm dry to NDVI_rainy, no extrapolation")



#difference to rf-trained bushes
gras <- lmdryrainy-testpred
par(mfrow=c(2,2))
plot(lmdryrainy, main="1 lm dry: NDVI_rainy")
plot(testpred, main="2 bush-prediction rf model")
plot(gras, main="1-2 = gras %")
gras[gras<0]<-0
plot(gras, main="gras % no under 0 values")

plot(gras)
writeRaster(gras, paste0(main, "gras.tif"), format="GTiff", overwrite=T)

