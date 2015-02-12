# packages
library(XLConnect)
library(plyr)

# functions
source("codeMatches.R")

# data control (dk) file
fls_dk <- "kili_datenkontrolle.xlsx"

# error codes
nom_dk <- readWorksheetFromFile(fls_dk, sheet = "Nomenclature")
  
# avl plots
plt_dk <- sheetNames(fls_dk)
plt_dk <- plt_dk[grep("COF1", plt_dk):length(plt_dk)]

# data import
ls_dk <- lapply(plt_dk, function(i) {
  readWorksheetFromFile(fls_dk, sheet = i)  
})

df_dk <- do.call("rbind.fill", ls_dk)

# error selection
codeMatches(df_dk, 6)
codeMatches(ls_dk, 6, single_obs = FALSE)
