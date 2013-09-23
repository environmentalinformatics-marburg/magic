gfGapLength <- function(data.dep, 
                        pos.na,
                        gap.limit,
                        end.datetime,
                        ...) {

  ################################################################################
  ##  
  ##  This program takes the data set of the dependent plot as well as its 
  ##  associated NA positions as input and calculates the length of each gap.
  ##  
  ##  parameters are as follows:
  ##  
  ##  data.dep (ki.data):         Data set of dependent plot.
  ##  pos.na (numeric):           NA positions in data set of dependent plot.
  ##  gap.limit (numeric):        Maximum length of a gap to be filled.
  ##  end.datetime (datetime):    End date and time to be set for final gap
  ##  ...                         Further arguments to be passed
  ##
  ################################################################################
  ##
  ##  Copyright (C) 2013 Florian Detsch, Tim Appelhans
  ##
  ##  This program is free software: you can redistribute it and/or modify
  ##  it under the terms of the GNU General Public License as published by
  ##  the Free Software Foundation, either version 3 of the License, or
  ##  (at your option) any later version.
  ##
  ##  This program is distributed in the hope that it will be useful,
  ##  but WITHOUT ANY WARRANTY; without even the implied warranty of
  ##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  ##  GNU General Public License for more details.
  ##
  ##  You should have received a copy of the GNU General Public License
  ##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
  ##
  ##  Please send any comments, suggestions, criticism, or (for our sake) bug
  ##  reports to florian.detsch@geo.uni-marburg.de
  ##
  ################################################################################
  
#   cat("\n",
#       "Module   :  gfGapLength", "\n",
#       "Author   :  Florian Detsch <florian.detsch@geo.uni-marburg.de>, Tim Appelhans <tim.appelhans@gmail.com>",
#       "Version  :  2013-01-08", "\n",
#       "License  :  GNU GPLv3, see http://www.gnu.org/licenses/", "\n",
#       "\n")
  
  ########## FUNCTION BODY #######################################################
  
  # Temporal space between single NA values
  pos.na.diff <- c(-99, diff(pos.na), -99)
  
  
  ## Determination of gap length
  
  # Single gaps --> starting point == endpoint
  gap.single <- unlist(lapply(seq(pos.na), function(i) {
    pos.na.diff[i] != 1 && pos.na.diff[i+1] != 1
  }))
  
  # Gap starting points
  gap.start <- unlist(lapply(seq(pos.na), function(i) {
    pos.na.diff[i] != 1 && pos.na.diff[i+1] == 1
  }))
  
  # Gap endpoints
  gap.end <- unlist(lapply(seq(pos.na) + 1, function(i) {
    pos.na.diff[i-1] == 1 && pos.na.diff[i] != 1
  }))
  
  # Concatenate starting points and endpoints
  gap <- as.data.frame(rbind(cbind(pos.na[which(gap.start)], pos.na[which(gap.end)]), 
               cbind(pos.na[which(gap.single)], pos.na[which(gap.single)])))
  gap <- gap[order(gap[,1]),]
#   gap.end.set <- as.Date(end.datetime, "%Y-%m-%d")
#   gap.end.act <- as.Date(paste(data.dep@Date$Year[gap[nrow(gap),2]],
#                                data.dep@Date$Month[gap[nrow(gap),2]],
#                                data.dep@Date$Day[gap[nrow(gap),2]], sep="-"),
#                          "%Y-%m-%d")
#   time.difference.hours <- difftime(gap.end.set, gap.end.act, units="hours")
#   if (time.difference.hours < 0.0) {
#     gap[nrow(gap),2] <- gap[nrow(gap),2] + time.difference.hours
#   }
  
  # Calculate gap length
  gap[,3] <- gap[,2] + 1 - gap[,1]
  
  # Reject too large gaps
  gap <- subset(gap, gap[,3] <= gap.limit)
 
  # Convert data frame to list
  if (nrow(gap) > 0) {
    gap <- lapply(1:nrow(gap), function(i) gap[i,])
  } else {
    gap <- list()
  }
    
  # Return output
  return(gap)
}


### Exemplary function call

# input.filepath <- "/media/permanent/r_mulreg/data/ki_0000cof3_000rug_201102010000_201102282355_eat_ca05_cti05_0050.dat"
# prm.dep <- "Ta_200"
# 
# source("/home/dogbert/software/development/julendat/src/julendat/rmodules/as.ki.data.R")
# ki.data.dep <- as.ki.data(input.filepath)
# 
# pos.na <- which(is.na(ki.data.dep@Parameter[[prm.dep]]))
# 
# gaps <- gfGapLength(data.dep = ki.data.dep, 
#                     pos.na = pos.na)