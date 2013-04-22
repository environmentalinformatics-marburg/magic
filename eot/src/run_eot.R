### Environmental settings

# Workspace clearance
rm(list = ls(all = TRUE))

# Working directory
path.wd <- "D:/programming/r/r_eot"
setwd(path.wd)

# Paths and files
path.data <- "data"
path.out <- "out"

# Required packages
library(compiler)
library(raster)

# Required functions
source("src/EotDeseason.R")
source("src/EotDenoise.R")
source("src/EotControl.R")

# Launch just-in-time (JIT) compilation
enableJIT(3)


### Data import 

pred.files <- list.files(path.data, pattern = "sst.*.rst$", full.names = TRUE, recursive = TRUE)
resp.files <- list.files(path.data, pattern = "gpcp.*.rst$", full.names = TRUE, recursive = TRUE)

pred.years <- unique(substr(basename(pred.files), 10, 13))
resp.years <- unique(substr(basename(resp.files), 13, 16))

pred.stck <- lapply(pred.years, function(i) {
  stack(pred.files[grep(i, pred.files)])
})
resp.stck <- lapply(resp.years, function(i) {
  stack(resp.files[grep(i, resp.files)])
})

# Artificial cropping
pred.stck <- lapply(pred.stck, function(i) crop(i, extent(c(-180, -120, -20, 20))))
resp.stck <- lapply(resp.stck, function(i) crop(i, extent(c(-160, -120, -10, 10))))


### Deseasoning

pred.stck.dsn <- EotDeseason(data = pred.stck)
resp.stck.dsn <- EotDeseason(data = resp.stck)


### Denoising

pred.stck.dns <- EotDenoise(data = pred.stck.dsn, k = 25)
resp.stck.dns <- EotDenoise(data = resp.stck.dsn, k = 5)


### EOT

# Output filenames
names.out <- sapply(pred.stck, function(i) {
  unique(substr(names(i), 1, 13))
})

out <- EotControl(pred = pred.stck.dns, 
                  resp = resp.stck.dns, 
                  n = 2, 
                  path.out = path.out, 
                  names.out = names.out)


### Plotting

spplot(out[[6]]$rsq.predictor[[1]])
spplot(out[[6]]$rsq.response[[1]])
spplot(out[[6]]$residuals[[1]], 2)