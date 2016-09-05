# **************************************************************************** 
# Identify roundabout rides - compare random sample of recorded trip distances
# to Google Maps distance expecation 
# ****************************************************************************

# *************************************************
# Setup
# *************************************************

# Load packages
reqPackages <- c("data.table", "scales", "lubridate", "ggmap")
reqDownloads <- !reqPackages %in% rownames(installed.packages())
if (any(reqDownloads)) install.packages(reqPackages[reqDownloads], dependencies = T)
loadSuccess <- lapply(reqPackages, require, character.only = T)
if (any(!unlist(loadSuccess))) stop(paste("\n\tPackage load failed:", reqPackages[unlist(loadSuccess) == F]))

# Set paths
setwd("/Users/Ryan/Github/NYC_taxi/2.Code/3.AnalysisRoundaboutRides/")
analysis_path <- "3.Analysis/"
data_path <- "1.Data/"

# Import batch
sample_size <- 10000
batch <- readRDS(paste0(analysis_path, "taxi_14_sample_", sample_size, ".Rda"))

# *************************************************
# Data & queries
# *************************************************

# Import and clean data
result <- tryCatch({
  file.list <- lapply(Sys.glob(paste0(analysisPath, "rand_trips_mapped_*.Rda")),readRDS)
  mapped <- rbindlist(file.list)
}, error = function(err) {
  return(NULL)
})

if (is.null(mapped) | nrow(mapped) == 0) {
  (i <- 1)
} else {
  (i <- max(mapped$batchID) + 1)
}

# Select current batch
batchSize <- 2500
startN <- batchSize*(i-1)+1
endN <- batchSize*i
rand_trips_sample <- batch[startN:endN]
rand_trips_sample[, batchID:=i]
rand_trips_sample[, runDT:=today()]

# Get expected distances for random sample
fromIN <- paste(rand_trips_sample$pickup_latitude, rand_trips_sample$pickup_longitude)
toIN <- paste(rand_trips_sample$dropoff_latitude, rand_trips_sample$dropoff_longitude)
gdist <- as.data.table(mapdist(from = fromIN, to = toIN, mode = 'driving', output = 'simple', messaging = F))
distQueryCheck()

# Merge back with trip data and save
rand_trips_mapped <- cbind(rand_trips_sample, gdist)
saveRDS(rand_trips_mapped, paste0(analysisPath, "rand_trips_mapped_", i, ".Rda"))

# Add current batch to previous batches
mappedCurrent <- rbindlist(list(mapped, rand_trips_mapped))

# *************************************************
# Distribution of actual v expected distance
# *************************************************

# Key metrics
mappedCurrent[, actualExpected := trip_distance/miles]
mappedCurrent[, degOff := atan(actualExpected)*180/pi]
mappedCurrent[, longHaul := actualExpected > 1.1 & actualExpected < 1.6]
mean(mappedCurrent$degOff, na.rm = T)
median(mappedCurrent$degOff, na.rm = T)
skewness(mappedCurrent$degOff, na.rm = T)
kurtosis(mappedCurrent$degOff, na.rm = T)

# Calculate time of week
mappedCurrent[,tow := ifelse(
  weekend == 'Weekday', ifelse(
    pick_hour <= 10, "Weekday morning", ifelse(
      pick_hour <= 15, "Weekday midday", "Weekday evening")), "Weekend")]
mappedCurrent[, partyInd := dayofweek %in% c(1, 7) & pick_hour < 5]

# Test for normality
shapiro.test(mappedCurrent$degOff)
qqnorm(mappedCurrent$degOff)

# Plot distribution
quantile(mappedCurrent[!is.na(actualExpected)]$actualExpected, c(.01, .05, 0.1, .5, .9, .95, .99))
# ggplot(mappedCurrent[actualExpected < 2], aes(x=actualExpected)) + geom_density()
ggplot(mappedCurrent, aes(x=degOff)) + geom_density()

# Scatter plot of each trip
ggplot(mappedCurrent, aes(x=miles, y = trip_distance)) + geom_point(size = .05, alpha = .5)

# Deep dive into top 5% (exclude top 1%)

# Compare against geom_dist -- see if geom_dist compares to actual(with a
# constant multiplier)

# *************************************************
# Distribution of actual v expected distance
# *************************************************

# Higher ratio for multiple passengers - could be due to multiple dropoffs for a single trip
mappedCurrent[, .(count = .N, pctLongHaul = mean(longHaul, na.rm = T), meanDegOff = mean(degOff, na.rm = T), medDegOff = median(degOff, na.rm = T)), .(passenger_count)][order(passenger_count)]

mappedCurrent[, .(count = .N, avgPass = mean(passenger_count), pctLongHaul = mean(longHaul, na.rm = T), meanDegOff = mean(degOff, na.rm = T), medDegOff = median(degOff, na.rm = T)), .(tow)][order(tow)]
mappedCurrent[, .(count = .N, avgPass = mean(passenger_count), pctLongHaul = mean(longHaul, na.rm = T), meanDegOff = mean(degOff, na.rm = T), medDegOff = median(degOff, na.rm = T)), .(partyInd)][order(partyInd)]

(sum <- mappedCurrent[, .(count = .N, pctLongHaul = mean(longHaul, na.rm = T), meanDegOff = mean(degOff, na.rm = T), medDegOff = median(degOff, na.rm = T)), .(pick_hour)][order(pick_hour)])
ggplot(data = sum, aes(x = pick_hour, y = pctLongHaul)) + geom_bar(stat = "identity")

# T test for difference in means
t.test(mappedCurrent[partyInd == T]$degOff, mappedCurrent[partyInd == F]$degOff)
t.test(mappedCurrent[partyInd == T]$longHaul, mappedCurrent[partyInd == F]$longHaul)
t.test(mappedCurrent[partyInd == T & passenger_count == 1]$longHaul, mappedCurrent[partyInd == F & passenger_count == 1]$longHaul)

# *************************************************
# Model
# *************************************************

train <- mappedCurrent[!is.na(longHaul), .(longHaul = as.factor(longHaul), tow, partyInd, pick_neigh, drop_neigh, passenger_count, weekend, americanholiday, weekdayname, pick_hour)]
control <- trainControl(method="repeatedcv", number=10, repeats=3)
set.seed(545177)
model <- train(longHaul ~., data = train, method = "xgbTree", trControl = control)
(imp <- varImp(model))
confusionMatrix(model)
