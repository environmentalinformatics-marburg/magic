# train test split and data frame merging

tile_fls <- list.files("/media/marvin/Seagate Expansion Drive/extraction_cleaned", full.names = TRUE)

round(length(tile_fls) /4)
set.seed(1)
train_id <- sample(length(tile_fls), size = 368)
test_id <- seq(length(tile_fls))
test_id <- test_id[!(test_id %in% train_id)]

train <- lapply(seq(length(train_id)), function(i){
  read.csv(tile_fls[i])
})

train_df <- do.call(rbind, train)
str(train_df)

train_df$X <- NULL
train_df$class_1 <- NULL
train_df$class_2 <- NULL
train_df$class_3 <- NULL
train_df$class_4 <- NULL
train_df$class_na <- NULL

write.csv(train_df, "/media/marvin/Seagate Expansion Drive/extraction_train_test/train.csv", row.names = FALSE)
saveRDS(train_df, file = "/media/marvin/Seagate Expansion Drive/extraction_train_test/train.RDS")


test <- lapply(seq(801, 1103), function(i){
  read.csv(tile_fls[i])
})
test_df <- do.call(rbind, test)

str(test_df)

test_df$X <- NULL
test_df$class_1 <- NULL
test_df$class_2 <- NULL
test_df$class_3 <- NULL
test_df$class_4 <- NULL
test_df$class_na <- NULL

saveRDS(test_df, file = "/media/marvin/Seagate Expansion Drive/extraction_train_test/test_03.RDS")

