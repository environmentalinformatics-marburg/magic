#nnet with cutoff as additional tuning parameter
library(caret)
## Get the model code for the original nnet method:

nnet_thres <- getModelInfo("nnet", regex = FALSE)[[1]]
nnet_thres$type <- c("Classification")
## Add the threshold as another tuning parameter
nnet_thres$parameters <- data.frame(parameter = c("size", "decay", "threshold"),
                                  class = c("numeric", "numeric", "numeric"),
                                  label = c("#Hidden Units","Weight Decay",
                                            "Probability Cutoff"))
## The default tuning grid code:
nnet_thres$grid <- function(x, y, len = NULL) {
expand.grid(size = ((1:len) * 2) - 1, decay = c(0, 10 ^ seq(-1, -4, length = len - 1)), threshold = seq(.01, .99, length = len))
}

## Here we fit a single nnet model (with a fixed size and decay)
## and loop over the threshold values to get predictions from the same
## nnet model.
nnet_thres$loop = function(grid) {
  library(plyr)
  loop <- ddply(grid, c("size","decay"),
                function(x) c(threshold = max(x$threshold)))
  submodels <- vector(mode = "list", length = nrow(loop))
  for(i in seq(along = loop$threshold)) {
    index <- which(grid$size == loop$size[i]&grid$decay == loop$decay[i])
    #index <- which(grid$size == loop$size[i])
    cuts <- grid[index, "threshold"]
    submodels[[i]] <- data.frame(threshold = cuts[cuts != loop$threshold[i]])
  }
  list(loop = loop, submodels = submodels)
  
}

## Fit the model independent of the threshold parameter
nnet_thres$fit = function(x, y, wts, param, lev, last, classProbs, ...) {
  if(length(levels(y)) != 2) 
    stop("This works only for 2-class problems")

  dat <- x
  dat$.outcome <- y
  if (!is.null(wts)) {
    out <- nnet(.outcome ~ ., data = dat, weights = wts, 
              size = param$size, decay = param$decay, ...)
  }
  else out <- nnet(.outcome ~ ., data = dat, size = param$size, 
                 decay = param$decay, ...)
  out

}

## Now get a probability prediction and use different thresholds to
## get the predicted class
nnet_thres$predict = function(modelFit, newdata, submodels = NULL) {
#?????????????????????????????????????????????????????????????????????
    out <- predict(modelFit, newdata)
    if (ncol(as.data.frame(out)) == 1) {
      out <- cbind(out, 1 - out)
      dimnames(out)[[2]] <- rev(modelFit$obsLevels)
    }
#?????????????????????????????????????????????????????????????????????

class1Prob=out[,modelFit$obsLevels[1]]

  ## Raise the threshold for class #1 and a higher level of
  ## evidence is needed to call it class 1 so it should 
  ## decrease sensitivity and increase specificity
  out <- ifelse(class1Prob >= modelFit$tuneValue$threshold,
                modelFit$obsLevels[1],
                modelFit$obsLevels[2])
  if(!is.null(submodels))
  {
    tmp2 <- out
    out <- vector(mode = "list", length = length(submodels$threshold))
    out[[1]] <- tmp2
    for(i in seq(along = submodels$threshold)) {
      out[[i+1]] <- ifelse(class1Prob >= submodels$threshold[[i]],
                           modelFit$obsLevels[1],
                           modelFit$obsLevels[2])
    }
  }
  out
}

## The probabilities are always the same but we have to create
## mulitple versions of the probs to evaluate the data across
## thresholds
nnet_thres$prob = function(modelFit, newdata, submodels = NULL) {

  out <- predict(modelFit, newdata)
  if (ncol(as.data.frame(out)) == 1) {
    out <- cbind(out, 1 - out)
    dimnames(out)[[2]] <- rev(modelFit$obsLevels)
  }
  out <- as.data.frame(out)
  if(!is.null(submodels))
  {
    probs <- out
    out <- vector(mode = "list", length = length(submodels$threshold)+1)
    out <- lapply(out, function(x) probs)
  }
  out
}