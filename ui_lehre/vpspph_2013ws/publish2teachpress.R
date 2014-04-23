publish2teachpress <- function(pwd, rmd.file, 
                    post.title = "Please provide a meaningful title", 
                    post.cats = "R") {
  
  stopifnot(require(knitr))
  
  if (!require('RWordPress'))
    install.packages('RWordPress', repos = 'http://www.omegahat.org/R', 
                     type = 'source')
  library(RWordPress)
  
  options(WordpressLogin = c(tappelhans = pwd),
          WordpressURL = 'http://teachpress.environmentalinformatics-marburg.de/xmlrpc.php')
  
  opts_knit$set(upload.fun = function(file){
    uploadFile(file)$url
    })
  
  knit2wp(input = rmd.file,
          title = post.title,
          shortcode = FALSE,
          categories = post.cats)

}
