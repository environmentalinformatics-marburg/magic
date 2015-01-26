mergeBfast <- function(obj, 
                       ...) {
  
  stopifnot(require(bfast))
  
  n_iter <- length(obj$output)
  
  sub <- obj$output[[n_iter]]
  
  yt <- obj$Yt
  st <- sub$St
  tt <- sub$Tt
  nt <- sub$Nt
  
  return(data.frame(yt, st, tt, nt))
  
}