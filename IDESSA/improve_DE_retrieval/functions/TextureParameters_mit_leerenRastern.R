texture.variables.v2 <- function(x,nrasters=1:nlayers(x),filter,var,parallel=TRUE){
  #' Calculate selected Texture parameters from clouds based on spectral properties
  #' 
  #' @param x A rasterLayer or a rasterStack containing different channels
  #' @param nrasters A vector of channels to use from x. Default =nlayers(x)
  #' @param filter A vector of numbers indicating the environment sizes for which the textures are calculated
  #' @param var A string vector of parameters to be calculated (see ?glcm)
  #' @param parallel A logical value indicating whether parameters are calculated parallely or not
  #' @return A list of RasterStacks containing the texture parameters for each combination of channel and filter
  #' @details In contrast o function "texture.variables", this function accounts for NA rasters
  #' @author Hanna Meyer
  #' @seealso \code{?glcm}
  
  require(glcm) 
  if (parallel){
    require(doParallel)
    registerDoParallel(detectCores())
  }
  glcm_filter=list()
  if (class (x)=="RasterStack"||class (x)=="RasterBrick"){
    ### Adjust nlayers: select those with only NA ##################################  
    nrastersOut=c()
    meanNA=mean(apply(apply(values(x),2,is.na),2,sum))
    for (i in nrasters){
      #if (!all(is.na(values(x[[i]])))){
      if(sum(is.na(values(x[[i]])))>=meanNA) {
        nrastersOut=c(nrastersOut,i)
      }
    }
  }
  
  for (j in 1:length(filter)){
    if (class (x)=="RasterStack"||class (x)=="RasterBrick"){
      values(x)[,nrastersOut]=runif(4, min = 0, max = 1) #temporally reclassify unvalid rasters
      if (parallel){
        glcm_filter[[j]]=foreach(i=nrasters,.packages= c("glcm","raster"))%dopar%{
          glcm(x[[i]], window = c(filter[j], filter[j]), #n_grey kleiner dann schneller
              shift=list(c(0,1), c(1,1), c(1,0), c(1,-1)),statistics=var) #average texture for each shift
        } 
      } else {
        glcm_filter[[j]]=foreach(i=nrasters,.packages= c("glcm","raster"))%do%{
          glcm(x[[i]], window = c(filter[j], filter[j]), #n_grey kleiner dann schneller
               shift=list(c(0,1), c(1,1), c(1,0), c(1,-1)),statistics=var) #average texture for each shift  
        }
      }

      names(glcm_filter[[j]])=names(x)[nrasters]
      glcm_filter[[j]][nrastersOut]= lapply(glcm_filter[[j]][nrastersOut],function(x){x*NA})#set non valid rasters to NA

      
    } else {
      glcm_filter[[j]]=glcm(x[[i]], window = c(filter[j], filter[j]), #n_grey kleiner dann schneller
           shift=list(c(0,1), c(1,1), c(1,0), c(1,-1)),statistics=var) #average texture for each shift     
    }   
  }
  names(glcm_filter)=paste0("size_",filter)
  return(glcm_filter)
}




