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
source("src/EotControl.R")

# Launch just-in-time (JIT) compilation
enableJIT(3)


### Data processing 

## Real data

# Data import
pred.files <- list.files(path.data, pattern = "sst.*.rst$", full.names = TRUE)
resp.files <- list.files(path.data, pattern = "gpcp.*.rst$", full.names = TRUE)

pred.stck <- stack(pred.files)
resp.stck <- stack(resp.files)

# # Artificial cropping
# pred.stck.crp <- crop(pred.stck, extent(c(-180, -160, -20, 0)))
# resp.stck.crp <- crop(resp.stck, extent(c(-160, -130, -10, 20)))

# ## Mock data
# 
# pred.rst.stck <- do.call("stack", lapply(seq(10), function(i) {
#   pred.rst <- raster(nrows = 15, ncols = 15, xmn= 0, xmx = 10, ymn = 0, ymx = 10)
#   pred.rst[] <- rnorm(225, 50, 10)
#   return(pred.rst)
# })
# 
# resp.rst.stck <- do.call("stack", lapply(seq(10), function(i) {
#   resp.rst <- raster(nrows = 10, ncols = 10, xmn = 0, xmx = 10, ymn = 0, ymx = 10)
#   resp.rst[] <- rnorm(100, 50, 10)
#   return(resp.rst)
# })

## Perform EOT

system.time({
  out <- EotControl(pred = pred.stck, 
                    resp = resp.stck, 
                    n = 1, 
                    path.out = path.out)
})

### Plotting

spplot(out$rsq.predictor)
spplot(out$rsq.response)
spplot(out$residuals, 2)