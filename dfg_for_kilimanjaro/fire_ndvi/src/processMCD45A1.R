processMCD45A1 <- function(indir = ".", 
                           template, 
                           outdir = ".", 
                           ranks = 1:4, 
                           ...) {
  
  stopifnot(require(raster))

  # SDS 1: Burn date
  fls_bd <- list.files(indir, pattern = "burndate.tif$", full.names = TRUE, ...)
  rst_bd <- stack(fls_bd)
  
  ls_bd_crp <- lapply(1:nlayers(rst_bd), function(i) {
    crop(rst_bd[[i]], template, 
         filename = paste0(outdir, "/CRP_", basename(fls_bd[i])), 
         overwrite = TRUE)
  })
  rst_bd_crp <- stack(ls_bd_crp)
 
  # SDS 2: Burned area pixel QA
  fls_qa <- list.files(indir, pattern = "ba_qa.tif$", full.names = TRUE, ...)
  rst_qa <- stack(fls_qa)

  ls_qa_crp <- lapply(1:nlayers(rst_qa), function(i) {
    crop(rst_qa[[i]], template, 
         filename = paste0(outdir, "/CRP_", basename(fls_qa[i])), 
         overwrite = TRUE)
  })
  rst_qa_crp <- stack(ls_qa_crp)
  
  # Pixel rejection based on quality criteria
  rst <- overlay(rst_bd_crp, rst_qa_crp, fun = function(x, y) {
    x[!y[] %in% ranks] <- NA
    return(x)
  }, filename = paste0(outdir, "/QA"), bylayer = TRUE, 
  suffix = names(rst_qa_crp), format = "GTiff", overwrite = TRUE)
  
  return(rst)
}
