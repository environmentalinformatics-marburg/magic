library(latticeExtra)
library(kza)
library(Rsenal)
library(zoo)
library(ggplot2)
library(reshape)

dat <- read.csv("/media/windows/tappelhans/uni/marburg/colleagues/flowla/ndvi_fire/ndvi__cell_ts.csv")
head(dat)

vec <- dat$V2

xyplot(vec2 ~ seq(vec2), type = "l")

vec1 <- vec[seq(1, length(vec), 2)]
vec2 <- vec[seq(2, length(vec), 2)]
#vec1 <- c(NA, vec1)

xyplot(vec1 ~ seq(vec1), type = "l") +
  as.layer(xyplot(vec2 ~ seq(vec2), type = "l", col = 2))

vec <- vec2

n <- 3
s <- 30
seed <- 123

f1 <- zoo::na.approx
f2 <- function(x) kza(x, m = 5, k = s + 1, impute_tails = TRUE)$kz

gapImputeEval(vec, n = n, size = s, seed = seed, funs = c(f1, f2))

#############

gappy <- gapCreate(vec, n = n, seed = 9, size = s)
imptd1 <- gapImpute(gappy, f1)
imptd2 <- gapImpute(gappy, f2)

plot(vec, type = "l")
lines(imptd1, col = 4)

plot(vec, type = "l")
lines(imptd2, col = 4)


### bootstrap

n <- 20
s <- 3

bst <- lapply(seq(1000), function(i) {
  seed <- 154 + i
  gapImputeEval(vec, n = n, size = s, seed = seed, 
                fixed.size = TRUE, funs = c(f1, f2))
})
  
bst.df <- as.data.frame(do.call("rbind", bst))
bst.df.m <- melt(bst.df)

p <- ggplot(data = bst.df.m, aes(x = variable, y = value, fill = stat))
p + geom_boxplot(notch = TRUE)



# n <- seq(30)
# s <- seq(30)
# 
# seed <- 123
# 
# bst <- lapply(n, function(i) {
#   lapply(s, function(j) {
#     gapImputeEval(vec, n = n[i], size = s[j], seed = seed,
#                   fixed.size = TRUE, funs = c(f1, f2))
#     })
# })
# 
# rsq <- vector("numeric", 0)
# ioa <- vector("numeric", 0)
# 
# for (i in n) {
#   for (j in s) {
#     rsq <- append(rsq, 
#                   gapImputeEval(vec, n = n[i], size = s[j], seed = 43,
#                                 fixed.size = TRUE, funs = c(f1, f2))[1, 1:2])
#   }
# }
# 
# rsq.df <- data.frame(rsq = unlist(rsq), fun = c(1, 2),
#                      n = rep(1:30, each = length(s) * 2),
#                      s = rep(1:30, each = 2))
# 
# rsq.ls <- split(rsq.df, as.factor(rsq.df$fun))
# 
# p <- ggplot(data = rsq.df, aes(x = as.factor(n), y = rsq, 
#                                fill = as.factor(fun)))
# p + geom_boxplot()
###########################################################################

# gap.n <- seq(1, 20, 1)
# gap.length <- seq(1, 10, 1)
# gap.length <- gap.length[3]
# 
# set.seed(12)
# gap.start <- sample(seq(nrow(dat)), size = gap.n[20], replace = FALSE)
# gap.end <- gap.start + gap.length
# 
# gaps <- unlist(lapply(seq(length(gap.start)), function(i) {
#   seq(gap.start[i], gap.end[i], 1)
# }))
# 
# test.vec <- dat[, "V5"]
# test.vec <- test.vec[-seq(1, length(test.vec), 2)]
# test.vec.gappy <- test.vec
# test.vec.gaps <- test.vec[gaps]
# 
# test.vec.gappy[gaps] <- NA
# 
# 
# kz.vec <- kza(test.vec.gappy, 2, k = gap.length + 1)
# 
# plot(test.vec, type = "l")
# points(test.vec.gappy, col = 3, pch = "*")
# lines(test.vec.gappy, col = 3)
# lines(kz.vec$kz, col = 4)
# 
# summary(lm(test.vec.gaps ~ kz.vec$kz[gaps]))
# plot(test.vec.gaps ~ kz.vec$kz[gaps])
# 
# IOA(test.vec.gaps, kz.vec$kz[gaps])
