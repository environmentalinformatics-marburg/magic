ttestIntraQuad <- function(ndvi_split_sp) {
  
  ls_t_intraquad <- lapply(levels(ndvi_split_sp$quadrant), function(h) {
    
    sub <- subset(ndvi_split_sp, quadrant == h)
    
    ls_y_all <- lapply(unique(sub$group), function(i) {
      tmp <- subset(sub, group == i)
      return(tmp$y)
    })
    
    df_y_all <- do.call(function(...) data.frame(cbind(...)), ls_y_all)
    names(df_y_all) <- unique(sub$group)
    
    mat_t <- sapply(1:6, function(i) {
      sapply(1:6, function(j) {
        if (i == j) {
          return(NA)
        } else {
          return(t.test(df_y_all[, i], df_y_all[, j], paired = TRUE)$p.value)
        }
      })
    })
    
    df_t <- data.frame(mat_t)
    colnames(df_t) <- unique(sub$group)
    rownames(df_t) <- unique(sub$group)
    
    return(df_t)
  })
  
  names(ls_t_intraquad) <- unique(ndvi_split_sp$quadrant)
  
  return(ls_t_intraquad)
  
}