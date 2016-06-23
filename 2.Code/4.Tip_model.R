# ****************************************************************************
# Tip model
# ****************************************************************************

library(caret)
library(doMC)

model_in_raw <- copy(taxi_working)[payment_type == "CRD"]
exclude_cols <- c('pickup_datetime','dropoff_datetime','rate_code','pickup_dtime','dropoff_dtime','dropoff_dt','EST','Events','hday_name','date','rate_code_chr','tip_amount','total_amount','payment_type')

# Alert for 1-level variables and replace NAs with new level / median
for (i in names(model_in_raw)) {
  var <- model_in_raw[, get(i)]
  l <- length(unique(var))
  if (l == 1) {print(paste(i, "has only one level"))}
  
  nna <- model_in_raw[is.na(get(i)), .N]
  if (nna > 0) {
    if (class(var) == "character") {
      print(paste0("Replacing ", nna, " missing records as ", class(var)," for [", i, "]"))
      model_in_raw[is.na(get(i)), i := "missing", with = F]
    }
    else if (class(var) == "numeric") {
      print(paste0("Replacing ", nna, " missing records as ", class(var)," for [", i, "]"))
      model_in_raw[is.na(get(i)), i := median(get(i), na.rm = T), with = F]
    }
    else if (class(var) == "integer") {
      print(paste0("Replacing ", nna, " missing records as ", class(var)," for [", i, "]"))
      model_in_raw[is.na(get(i)), i := median(get(i), na.rm = T), with = F]
    }
    else {print(paste0(nna, " missing records not replaced [", i, "]; class ", class(var)))}
  }
}

trainIndex <- createDataPartition(model_in_raw$tip_pct, p=0.8, list=FALSE)
train <- model_in_raw[ trainIndex,][,!exclude_cols, with = F]
test <- model_in_raw[-trainIndex,]

# Remove records with new levels
# EDIT: move this into a for loop -> function
test[!dropoff_nhood %in% train$dropoff_nhood, dropoff_nhood := "missing"]
test[!dropoff_borough %in% train$dropoff_borough, dropoff_borough := "missing"]
test[!pickup_nhood %in% train$pickup_nhood, pickup_nhood := "missing"]

# Train model
fitControl <- trainControl(
  method = "repeatedcv",
  number = 7,
  repeats = 3)

registerDoMC(2)
explorer <- train(tip_pct ~ ., data = train,
                  method = "xgbTree",
                  trControl = fitControl)
explorer

varimp <- varImp(explorer, scale = F)
varimp

# Test model
# EDIT: there should be no NAs removed
test_comp <- test[complete.cases(test)]
test_comp$test_pred <- predict(explorer, test_comp)

ggplot(data = test_comp, aes(x = test_pred, y = tip_pct)) +
  geom_point(shape=1) 

