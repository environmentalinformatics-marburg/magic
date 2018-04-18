# train test split and data frame merging

tile_fls <- list.files("D:/model_input/extraction_cleaned/", full.names = TRUE)

round(length(tile_fls) /4)
set.seed(1)
train_id <- sample(length(tile_fls), size = 368)
test_id <- seq(length(tile_fls))
test_id <- test_id[!(test_id %in% train_id)]

train <- lapply(seq(length(train_id)), function(i){
  read.csv(tile_fls[train_id[i]])
})

train_df <- do.call(rbind, train)
str(train_df)

train_df$X <- NULL
train_df$class_1 <- NULL
train_df$class_2 <- NULL
train_df$class_3 <- NULL
train_df$class_4 <- NULL
train_df$class_na <- NULL

saveRDS(train_df, file = "D:/model_input/train.RDS")


test <- lapply(seq(length(test_id)), function(i){
  read.csv(tile_fls[test_id[i]])
})
test_df <- do.call(rbind, test)

str(test_df)

test_df$X <- NULL
test_df$class_1 <- NULL
test_df$class_2 <- NULL
test_df$class_3 <- NULL
test_df$class_4 <- NULL
test_df$class_na <- NULL

saveRDS(test_df, file = "D:/model_validation/test_data.RDS")

