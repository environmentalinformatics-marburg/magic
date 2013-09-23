calcScores <- function(predicted, 
                       observed, 
                       rainy.areas = F) {
 
  ##############################################################################
  ##  
  ##  This function calculates various scores of a conditional inference tree, 
  ##  e.g. accuracy, probability of detection, false alarm ratio. See
  ##  http://cawcr.gov.au/projects/verification/ for further information.
  ##  
  ##  Parameters are as follows:
  ##
  ##  predicted (factor):     Predicted values.
  ##  observed (numeric):     Observed values. 
  ##  rainy.areas (logical):  Calculate rain areas?
  ##
  ##############################################################################
  
  # Contingency table
  table.result <- table(predicted, observed)
  
  H <- table.result[1,1]  # hits
  M <- table.result[2,1]  # misses
  F <- table.result[1,2]  # false alarm
  C <- table.result[2,2]  # correct negatives
  
  T <- C+F+M+H            # total      
  
  # Scores derived from contingency table
  Acc = (H+C)/T           # accuracy
  BIAS = (H+F)/(H+M)      # bias score
  POD = H/(H+M)           # probability of detection
  PFD = F/(F+C)           # probability of false detection
  FAR = F/(H+F)           # false alarm ratio
  CSI = H/(H+F+M)         # critical success index
  H_random1 = ( ((H+F)*(H+M)) + ((C+F)*(C+M)) ) /T
  HSS = ((H+C)-H_random1)/(T-H_random1) # Heidke skill score
  HKD = (H/(H+M))-(F/(F+C))             # Hanssen-Kuipers discriminant
  H_random2 = ((H+M)*(H+F))/(H+F+M+C)
  ETS=(H-H_random2)/((H+F+M)-H_random2) # equitable threat score
  
  # Combine scores
  score <- data.frame(Acc, BIAS, POD, PFD, FAR, CSI, HSS, HKD, ETS, T, C, F, M, H)  
  
  # Include rain areas (optional)
  if (rainy.areas) {
    AreaR = ((M+H)/T) * 100  # rain area radar
    AreaS = ((F+H)/T) * 100  # rain area satellite
    
    score <- data.frame(score, AreaR, AreaS)
  }
  
  return(score)
}