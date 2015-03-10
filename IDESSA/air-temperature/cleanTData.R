cleanTData <- function(input){
  # cleans the temperature data sets MYD11A1 & MOD11A1
  # - remove invalid values (<7500 & > 65535)
  # - apply scale factor
  # - convert from Kelvin to Celsius
  
  # Args:
  #   input = a vector of raw temperature data
  
  # Returns:
  #   a vector of valid temperatur data
  
  input[input < 7500] <- NA
  input[input > 65535] <- NA
  
  input <- input * 0.02 - 273.15
  
  return(input)
}
