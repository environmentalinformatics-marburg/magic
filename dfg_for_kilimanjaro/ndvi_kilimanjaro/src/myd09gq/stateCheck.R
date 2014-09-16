stateCheck <- function(band, 
                       state,
                       check_id = c(1, 1, 1, 1, 1, 1),                       
                       ...) {
  
  source("src/number2binary.R")
  
  corrBand <- 
    overlay(band, state, 
            fun = function(x, y) {
              index <- sapply(y[], function(i) {
                if (!is.na(i)) {
                  cstate <- shadow <- cirrus <- intcl <- snow <- adjcl <- TRUE
                  
                  # 16-bit string
                  bit <- number2binary(i, 16)
                  # Cloud state
                  if (check_id[1] == 1)
                    cstate <- paste(bit[c(15, 16)], 
                                    collapse = "") %in% c("00", "11", "10")
                  # Shadow
                  if (check_id[2] == 1)
                    shadow <- bit[14] == 0
                  # Cirrus
                  if (check_id[3] == 1)
                    cirrus <- paste(bit[c(7, 8)], 
                                    collapse = "") %in% c("00", "01", "10")
                  # Intern cloud algorithm
                  if (check_id[4] == 1)
                    intcl <- bit[6] == 0
                  # Snow mask
                  if (check_id[5] == 1)
                    snow <- bit[4] == 0
                  # Adjacent clouds
                  if (check_id[6] == 1)
                    adjcl <- bit[3] == 0
                  
                  # Did all activated checks succeed?
                  return(all(cstate, shadow, snow, cirrus, intcl, adjcl))
                } else {
                  # Return FALSE if current state pixel == NA
                  return(FALSE)
                }
              })
              
              # Set all pixels where activated checks failed to NA
              x[!index] <- NA
              return(x)
            }, ...)
  
  return(corrBand)
}