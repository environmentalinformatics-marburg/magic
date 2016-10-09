library(hsdar)
library(randomForest)
library(caret)
library(rgdal)

###################################
### Begin Functions
selectAlbedofile <- function(dir)
{
  fi <- list.files(dir)
  fi <- fi[substr(fi, 1, 7) == "albedo_"]
  if (length(fi) == 0)
    return(NULL)
  fi <- fi[substr(fi, nchar(fi)-3, nchar(fi)) == ".raw"]
  if (length(fi) == 0)
    return(NULL)
  fi <- fi[substr(fi, nchar(fi)-7, nchar(fi)) != "_TOA.raw"]
  if (length(fi) != 1)
    return(NULL)
  return(fi)
}
getSatelliteMetaData <- function(fi)
{
  img <- brick(fi)
  sat <- switch(substr(fi, nchar(fi)-5, nchar(fi)-4),
                qb = list(i = 2, wavelength = sort(c(830, 660, 560, 485)), addvar = c("VegType")),
                re = list(i = 3, wavelength = sort(c(805, 657.5, 710, 555, 475)), addvar = c("VegType")),
                wv = list(i = 4, wavelength = sort(c(724, 659, 831, 908, 546, 478, 427, 608)), addvar = NULL)
         )
  nbands <- c(4,5,8)[sat$i-1]
  if (nlayers(img) != nbands)
    stop()
  return(sat)  
}

as.data.frame_nri <- function(x)
{
  .ConvertNri <- function(x)
  {
    lyr <- as.matrix(x)
    lt <- lower.tri(lyr)
    data <- matrix(0, ncol = sum(lt), nrow = x@nlyr)
    data[1,] <- lyr[lt]
    if (x@nlyr > 1)
    {
      for (i in 2:x@nlyr)
      {
        lyr <- as.matrix(x, lyr = i)
        data[i,] <- lyr[lt]
      }
    }
    return(data)
  }
  bnd_nam_data <- x@dimnames
  bnd_nam_ch <- character()
  for (i in 1:(length(bnd_nam_data[[1]])-1))
    for (k in (i+1):length(bnd_nam_data[[2]]))
      bnd_nam_ch <- c(bnd_nam_ch, paste(bnd_nam_data[[2]][k], bnd_nam_data[[1]][i], sep = "_"))
  nri_data <- as.data.frame(.ConvertNri(x@nri))
  names(nri_data) <- bnd_nam_ch
  return(nri_data)
}

writeCompressedTif <- function(outfile, type = "Float32", ...)
{
  out <- readGDAL(outfile, silent = TRUE)
  system(paste("rm", outfile))
  status <- writeGDAL(out, outfile, type = type,
                      options=c("COMPRESS=LZW"), ...)
}
### End Functions
###################################

## Models
load("/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/aktuelles/rfeModel_Vegcover.RData")

## Images
maindir <- "/home/lehnert/data/Local_scale"
outdir <- "/home/lehnert/Öffentlich/Dropbox/Paper_Hanna/aktuelles/predictions"
nrowthresh <- 10

img_dir <- list.dirs(maindir)
imgs <- character()

for (i in img_dir)
{
  if (substr(basename(i), 1, 2) == "ID")
  {
    imgs <- c(imgs, i)
  }
}
img_dir <- imgs

## Process images
for (i in 1:length(img_dir))
{
  fi  <- selectAlbedofile(img_dir[i])
  sat <- getSatelliteMetaData(file.path(img_dir[i], fi))
  
  if (sat[[1]] %in% c(4))
  {
    img <- HyperSpecRaster(file.path(img_dir[i], fi), sat$wavelength)
    
    tr <- blockSize(img)
    if (tr$nrows[1] > nrowthresh)
    {
      tr <- list(row = seq(1, nrow(img), nrowthresh))
      tr$nrows <- rep.int(nrowthresh, length(tr[[1]]))
      nb <- ceiling(nrow(img)/nrowthresh)
      dif <- nb * nrowthresh - nrow(img)
      tr$nrows[length(tr$nrows)] <- tr$nrows[length(tr$nrows)] - dif
      tr$n <- length(tr$nrows)
    }
    outfile <- file.path(outdir, "vegCover", paste(basename(img_dir[i]), "_sat_", sat[[1]] - 1, ".tif", sep = "")) 
    res <- writeStart(img, outfile, overwrite = TRUE, nl = 1)
    

    pb <- pbCreate(tr$n, 'text', style = 3, label = 'Progress')

    for (irow in 1:tr$n) 
    {
      v <- getValuesBlock(img, row=tr$row[irow], nrows=tr$nrows[irow])
      nri_vals <- nri(v, recursive = TRUE)
      nri_vals <- as.data.frame_nri(nri_vals)
      for (n in 1:length(rfeModel_Vegcover[[sat[[1]]]]$optVariables))
      {
        if (sum(names(nri_vals) == rfeModel_Vegcover[[4]]$optVariables[n]) != 1)
          stop()
      }
      
      if (! is.null(sat[[3]]))
      {
        ## Hier muss der VegType rein
      }
      
      pred_vals <- predict(rfeModel_Vegcover[[sat[[1]]]], nri_vals)
      
      res <- writeValues(res, matrix(pred_vals, ncol = 1), tr$row[irow])
      pbStep(pb, step = NULL, label = '')
    }
    res <- writeStop(res)
    writeCompressedTif(outfile)
    pbClose(pb, TRUE)  
  }
}


