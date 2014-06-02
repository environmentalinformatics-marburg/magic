#svm with cutoff as additional tuning parameter
#original script for rf bases on http://www.r-bloggers.com/optimizing-probability-thresholds-for-class-imbalances/
library(caret)
## Get the model code for the original svm method:

svm_thres <- getModelInfo("svmRadial", regex = FALSE)[[1]]
svm_thres$type <- c("Classification")
## Add the threshold as another tuning parameter
svm_thres$parameters <- data.frame(parameter = c("sigma", "C", "threshold"),
                                    class = c("numeric", "numeric", "numeric"),
                                    label = c("Sigma","Cost",
                                              "Probability Cutoff"))
## The default tuning grid code:
svm_thres$grid <- function(x, y, len = NULL) {
  library(kernlab)
  sigmas <- sigest(as.matrix(x), na.action = na.omit, scaled = TRUE)
  expand.grid(sigma = mean(as.vector(sigmas[-2])), 
              C = 2^((1:len) -  3),
              threshold = seq(.01, .99, length = len))
}

## Here we fit a single random forest model (with a fixed mtry)
## and loop over the threshold values to get predictions from the same
## randomForest model.
svm_thres$loop = function(grid) {
  library(plyr)
  loop <- ddply(grid, c("sigma", "C"),
                function(x) c(threshold = max(x$threshold)))
  submodels <- vector(mode = "list", length = nrow(loop))
  for(i in seq(along = loop$threshold)) {
    index <- which(grid$sigma == loop$sigma[i] & grid$C == loop$C[i])
    cuts <- grid[index, "threshold"]
    submodels[[i]] <- data.frame(threshold = cuts[cuts != loop$threshold[i]])
  }
  list(loop = loop, submodels = submodels)
}

## Fit the model independent of the threshold parameter
svm_thres$fit = function(x, y, wts, param, lev, last, classProbs, ...) {
  if(length(levels(y)) != 2)
    stop("This works only for 2-class problems")
  out <- ksvm(x = as.matrix(x), y = y,
              kernel = rbfdot,
              kpar = list(sigma = param$sigma),
              C = param$C,
              prob.model = classProbs,
              ...)
  attr(out, "threshold") <- param$threshold
  out
}

## Now get a probability prediction and use different thresholds to
## get the predicted class
svm_thres$predict = function(modelFit, newdata, submodels = NULL) {
  class1Prob <- predict(modelFit,
                        newdata,
                        type = "prob")[, lev(modelFit)[1]]
  ## Raise the threshold for class #1 and a higher level of
  ## evidence is needed to call it class 1 so it should 
  ## decrease sensitivity and increase specificity
  threshold <- attributes(modelFit)$threshold
  out <- ifelse(class1Prob >= threshold,
                lev(modelFit)[1],
                lev(modelFit)[2])
  if(!is.null(submodels)) {
    tmp2 <- out
    out <- vector(mode = "list", length = length(submodels$threshold))
    out[[1]] <- tmp2
    for(i in seq(along = submodels$threshold)) {
      out[[i+1]] <- ifelse(class1Prob >= submodels$threshold[[i]],
                           lev(modelFit)[1],
                           lev(modelFit)[2])
    }
  }
  out
}


## The probabilities are always the same but we have to create
## mulitple versions of the probs to evaluate the data across
## thresholds
svm_thres$prob = function(modelFit, newdata, submodels = NULL) {
  out <- as.data.frame(predict(modelFit, newdata, type = "prob"))
  if(!is.null(submodels)) {
    probs <- out
    out <- vector(mode = "list", length = length(submodels$threshold)+1)
    out <- lapply(out, function(x) probs)
  }
  out
}