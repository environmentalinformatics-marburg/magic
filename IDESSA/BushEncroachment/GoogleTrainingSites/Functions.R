####################################
# Functions ##########################
####################################
RGB_to_HSV <- function(rgb, gamma = 1, maxColorValue = 255)
{
  if(!is.numeric(rgb)) stop("rgb matrix must be numeric")
  d <- dim(rgb)
  if(d[1] != 3) stop("rgb matrix must have 3 rows")
  n <- d[2]
  if(n == 0) return(cbind(c(h = 1, s = 1, v = 1))[,0])
  rgb <- rgb/maxColorValue
  if(gamma != 1) rgb <- rgb ^ (1/gamma)
  
  ## get the max and min
  v <- apply( rgb, 2, max)
  s <- apply( rgb, 2, min)
  D <- v - s # range
  
  ## set hue to zero for undefined values (gray has no hue)
  h <- numeric(n)
  notgray <- ( s != v )
  
  ## blue hue
  idx <- (v == rgb[3,] & notgray )
  if (any (idx))
    h[idx] <- 60 * (4 + ((rgb[1,idx] - rgb[2,idx]) / D[idx]))
  ## green hue
  idx <- (v == rgb[2,] & notgray )
  if (any (idx))
    h[idx] <- 60 * (2 + ((rgb[3,idx] - rgb[1,idx]) / D[idx]))
  ## red hue
  idx <- (v == rgb[1,] & notgray )
  if (any (idx))
    h[idx] <- 60 * (0 + ((rgb[2,idx] - rgb[3,idx]) / D[idx]))
  
  ## correct for negative red
  idx <- (h < 0)
  h[idx] <- 360+h[idx]
  
  ## set the saturation
  s[! notgray] <- 0;
  s[notgray] <- 1 - s[notgray] / v[notgray]
  
  rbind( h = h, s = s, v = v )
}



#Environmental Variables

#Mean 3x3

Mean3<- function(raster){
  gmap_hel_fcmu3 <- lapply(1:nlayers(raster), function(i) {
    focal(raster[[i]], w = matrix(1,3,3), fun = mean, na.rm = TRUE, pad = TRUE)
  })
  gmap_hel_fcmu3 <- stack(gmap_hel_fcmu3)
  names(gmap_hel_fcmu3) <- paste0(names(raster),"_Mean3")                 #set names
  return(gmap_hel_fcmu3)
}

#Mean 5x5

Mean5<- function(raster){
  gmap_hel_fcmu5 <- lapply(1:nlayers(raster), function(i) {
    focal(raster[[i]], w = matrix(1,5,5), fun = mean, na.rm = TRUE, pad = TRUE)
  })
  gmap_hel_fcmu5 <- stack(gmap_hel_fcmu5)
  names(gmap_hel_fcmu5) <- paste0(names(raster),"_Mean5")
  return(gmap_hel_fcmu5)
}


#SD 3x3

SD3<- function(raster){
  gmap_hel_fcsd3 <- lapply(1:nlayers(raster), function(i) {
    focal(raster[[i]], w = matrix(1,3,3), fun = sd, na.rm = TRUE, pad = TRUE)
  })
  gmap_hel_fcsd3 <- stack(gmap_hel_fcsd3)
  names(gmap_hel_fcsd3) <- paste0(names(raster),"_SD3")
  return(gmap_hel_fcsd3)
}

#SD 5x5

SD5<- function(raster){
  gmap_hel_fcsd5 <- lapply(1:nlayers(raster), function(i) {
    focal(raster[[i]], w = matrix(1,5,5), fun = sd, na.rm = TRUE, pad = TRUE)
  })
  gmap_hel_fcsd5 <- stack(gmap_hel_fcsd5)
  names(gmap_hel_fcsd5) <- paste0(names(raster),"_SD5")
  return(gmap_hel_fcsd5)
}

######################################################

VarFromRGB <- function (rgb){
  if (nlayers(rgb)!=3){ stop ("please provide a RGB Rasterstack")}
  
  names(rgb) <- c("R","G","B")
  # Calculate VVI (Visible Vegetation Index)
  rgb$VVI <- vvi(rgb) 
  
  ## Calculate HSV
  rgb4hsv<-t(as.data.frame(rgb[[1:3]]))
  train.hsv <- RGB_to_HSV(rgb4hsv , maxColorValue = 255) 
  rgb$H<-train.hsv[1, ]
  rgb$S<-train.hsv[2, ]
  rgb$V<-train.hsv[3, ]
  
  # Enviromental Variables (Mean, SD)
  rgb_fcmu3<-Mean3(rgb)
  #rgb_fcmu5<-Mean5(rgb)
  rgb_fcsd3<-SD3(rgb)
  #rgb_fcsd5<-SD5(rgb)
  

  ## assemble relevant raster data
  google_all <- stack(rgb,rgb_fcmu3, rgb_fcsd3)
 
  return (google_all)
}

