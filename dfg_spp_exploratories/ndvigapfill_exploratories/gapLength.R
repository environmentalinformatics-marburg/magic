gapLength <- function(pos.na,
                      ...) {

  # Temporal space between single NA values
  pos.na.diff <- c(-99, diff(pos.na), -99)
  
  
  ## Determination of gap length
  
  # Single gaps --> starting point == endpoint
  gap.single <- unlist(lapply(seq(pos.na), function(i) {
    pos.na.diff[i] != 1 && pos.na.diff[i+1] != 1
  }))
  
  # Gap starting points
  gap.start <- unlist(lapply(seq(pos.na), function(i) {
    pos.na.diff[i] != 1 && pos.na.diff[i+1] == 1
  }))
  
  # Gap endpoints
  gap.end <- unlist(lapply(seq(pos.na) + 1, function(i) {
    pos.na.diff[i-1] == 1 && pos.na.diff[i] != 1
  }))
  
  # Concatenate starting points and endpoints
  gap <- as.data.frame(rbind(cbind(pos.na[which(gap.start)], pos.na[which(gap.end)]), 
               cbind(pos.na[which(gap.single)], pos.na[which(gap.single)])))
  gap <- gap[order(gap[,1]),]

  # Calculate gap length
  gap[,3] <- gap[,2] + 1 - gap[,1]
  
  # Convert data frame to list
  if (nrow(gap) > 0) {
    gap <- lapply(1:nrow(gap), function(i) gap[i,])
  } else {
    gap <- list()
  }
    
  # Return output
  return(gap)
}