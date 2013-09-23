gfNogapLength <- function(gap.lengths, 
                          data.dep, 
                          ...) {
  
  if (is.data.frame(gap.lengths)) {
    gap.lengths <- lapply(seq(nrow(gap.lengths)), function(i) {
      gap.lengths[i, ]
    })
  }
  
  nogap.lengths <- lapply(seq(gap.lengths), function(i) {
    
    if (i == 1 & gap.lengths[[i]][[1]] != 1) {
      tmp.start <- 1
      tmp.end <- gap.lengths[[i]][[1]] - 1
      tmp.span <- length(seq(tmp.start, tmp.end))
    } else if (i > 1 & i < length(gap.lengths)) {
      tmp.start <- gap.lengths[[i-1]][[2]] + 1
      tmp.end <- gap.lengths[[i]][[1]] - 1
      tmp.span <- length(seq(tmp.start, tmp.end))
    } else if (i == length(gap.lengths) & gap.lengths[[i]][[2]] != length(data.dep)) {
      tmp.start <- gap.lengths[[i]][[2]] + 1
      tmp.end <- length(data.dep)
      tmp.span <- length(seq(tmp.start, tmp.end))
    }
    
    if (exists("tmp.start"))
      return(data.frame(start = tmp.start, end = tmp.end, span = tmp.span))
    
  })
  
  return(nogap.lengths)
  
}