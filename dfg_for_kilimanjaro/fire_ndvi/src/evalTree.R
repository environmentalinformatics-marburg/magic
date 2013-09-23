evalTree <- function(independ = NULL, 
                     depend, 
                     data, 
                     seed = 10, 
                     size = 1000,
                     minbucket = 100,
                     rainy.areas = F,
                     ...) {

  ##############################################################################
  ##  
  ##  This function builts a conditional inference tree (see ?ctree for details) 
  ##  and evaluates it by calling another function that calculates various 
  ##  scores, e.g. accuracy, probability of detection, false alarm ratio. See
  ##  http://cawcr.gov.au/projects/verification/ for further information.
  ##  
  ##  Parameters are as follows:
  ##
  ##  independ (numeric):   Column number(s) of independent variables.
  ##  depend (numeric):     Column number of dependent variable. 
  ##  data (data.frame):    Data frame containing independent and dependent
  ##                        variables.
  ##  seed (numeric):       Seed for random number generation.
  ##  size (numeric):       Size of the training sample.
  ##  minbucket (numeric):  Numeric vector specifying the minimum sum of weights
  ##                        in a terminal node.
  ##  ...                   Further arguments passed on to ctree_control().
  ##
  ##############################################################################
  
  # Load required packages and functions
  lib <- c("foreach", "party")
  sapply(lib, function(...) stopifnot(require(..., character.only = T)))
  
  source("src/calcScores.R")
  
  # Draw random sample
  set.seed(seed)
  index <- sample(nrow(data), size)
  
  # Training and validation data
  train <- data[index, ]
  valid <- data[-index, ]
  
  # Setup ctree() formula
  if (is.null(independ)) {
    frml <- as.formula(paste(names(data)[depend], ".", sep = " ~ "))
  } else {
    frml <- as.formula(paste("as.factor(", names(data)[depend], ") ~ ", 
                             paste(names(data)[independ], collapse = " + "), 
                             sep = ""))
  }
  
  # Loop through different bucket sizes
  out.tree <- foreach(i = minbucket, .combine = "rbind") %do% { 
    
    # Conditional inference tree
    tree <- ctree(frml, data = train, 
                  controls = ctree_control(minbucket = i, ...))
    
    # Prediction
    pred <- predict(tree, valid, type = "response")
    
    # Calculate and return scores
    calcScores(predicted = pred, 
               observed = valid$fire, 
               rainy.areas = rainy.areas)
  }
    
  # Return output
  return(data.frame(minbucket = minbucket, out.tree))
}