#' Predicts the rainfall rate based on a trained model and MSG data
#' 
#' @param model The final model from either caret's train or rfe. Use model$fit$finalModel or model$finalModel to get it
#' @param sunzenith A raster of the sunzenith
#' @param msg The 11 used channels of MSG. Use name conventions described in Details
#' @param variables A string vector of variables which are included in the model. Variables which are actualy not needed by the model are ignored.
#' @param xderivTexture A string vector of variables from which Textures are included in the model. Variables which are actualy not needed by the model are ignored.
#' @param rainmask A raster indicates areas which are not raining with NA values
#' @return A Raster Layer containing predicted rainfall  
#' @author Hanna Meyer


predictRainfall <- function (model, sunzenith, msg, variables, xderivTexture, rainmask){
  require(caret)
  library(raster)
  predVars<-calculatePredictors(msg,sunzenith,variables,xderivTexture )
  tmp<-stack(unlist(predVars$glcm_filter))
  names(tmp)<-names(as.data.frame(lapply(predVars$glcm_filter$size_3,values)))
  modeldata<-stack(c(unlist(predVars[names(predVars)!="glcm_filter"]),tmp))
  modeldata=modeldata[[model$coefnames]]
  values(modeldata)[is.na(values(rainmask))] =NA
  prediction<-predict(modeldata,model)
  
}