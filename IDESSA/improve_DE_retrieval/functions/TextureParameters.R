texture.variables <- function(x,nrasters=1:nlayers(x),filter,var,parallel=TRUE,n_grey = 64){
  #' Calculate selected Texture parameters from clouds based on spectral properties
  #' 
  #' @param x A rasterLayer or a rasterStack containing different channels
  #' @param nrasters A vector of channels to use from x. Default =nlayers(x)
  #' @param filter A vector of numbers indicating the environment sizes for which the textures are calculated
  #' @param var A string vector of parameters to be calculated (see ?glcm)
  #' @param parallel A logical value indicating whether parameters are calculated parallely or not
  #' @return A list of RasterStacks containing the texture parameters for each combination of channel and filter  
  #' @author Hanna Meyer
  #' @seealso \code{?glcm}
  
  require(glcm) 
  if (parallel){
    require(doParallel)
    registerDoParallel(detectCores())
  }
  glcm_filter=list()

  
  for (j in 1:length(filter)){
    if (class (x)=="RasterStack"||class (x)=="RasterBrick"){
      if (parallel){
        glcm_filter[[j]]=foreach(i=nrasters,.packages= c("glcm","raster"))%dopar%{
          glcm(x[[i]], window = c(filter[j], filter[j]), #n_grey kleiner dann schneller
              shift=list(c(0,1), c(1,1), c(1,0), c(1,-1)),statistics=var,n_grey=n_grey) #average texture for each shift
        } 
      } else {
        glcm_filter[[j]]=foreach(i=nrasters,.packages= c("glcm","raster"))%do%{
          glcm(x[[i]], window = c(filter[j], filter[j]), #n_grey kleiner dann schneller
               shift=list(c(0,1), c(1,1), c(1,0), c(1,-1)),statistics=var,n_grey=n_grey) #average texture for each shift  
        }
      }

      names(glcm_filter[[j]])=names(x)[nrasters]


      
    } else {
      glcm_filter[[j]]=glcm(x[[i]], window = c(filter[j], filter[j]), #n_grey kleiner dann schneller
           shift=list(c(0,1), c(1,1), c(1,0), c(1,-1)),statistics=var,n_grey=n_grey) #average texture for each shift     
    }   
  }
  names(glcm_filter)=paste0("size_",filter)
  return(glcm_filter)
}




