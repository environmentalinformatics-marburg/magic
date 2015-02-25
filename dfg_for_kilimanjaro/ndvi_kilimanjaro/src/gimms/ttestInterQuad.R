ttestInterQuad <- function(ndvi_split_sp) {
  
  ls_t_interquad <- lapply(unique(ndvi_split_sp$group), function(h) {
    
    sub <- subset(ndvi_split_sp, group == h)
    
    ls_y_all <- lapply(unique(sub$quadrant), function(i) {
      tmp <- subset(sub, quadrant == i)
      return(tmp$y)
    })
    
    df_y_all <- do.call(function(...) data.frame(cbind(...)), ls_y_all)
    names(df_y_all) <- unique(sub$quadrant)
    
    mat_t <- sapply(1:4, function(i) {
      sapply(1:4, function(j) {
        if (i == j) {
          return(NA)
        } else {
          return(t.test(df_y_all[, i], df_y_all[, j])$p.value)
        }
      })
    })
    
    df_t <- data.frame(mat_t)
    colnames(df_t) <- unique(sub$quadrant)
    rownames(df_t) <- unique(sub$quadrant)
    
    return(df_t)
  })
  
  names(ls_t_interquad) <- unique(ndvi_split_sp$group)
  
  return(ls_t_interquad)
}