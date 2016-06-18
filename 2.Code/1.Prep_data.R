# ****************************************************************************
# Prep data
# ****************************************************************************

# Set wd and install libraries
library(RSocrata, quietly = T)
library(data.table, quietly = T)
library(scales, quietly = T)
library(lubridate, quietly = T)
library(ggmap, quietly = T)
library(maptools, quietly = T)
library(rCharts, quietly = T)
library(scales, quietly = T)

setwd("/Volumes/Ryan's SSD/Users/Ryan/Github/NYC_taxi/")
data_path <- "./1.Data/"
lib_path <- "./2.Code/"
analysis_path <- "./3.Analysis/"

map_neighborhoods <- dget(paste0(lib_path, "F.map_neighborhoods.R"))
neighborhood <- dget(paste0(lib_path, "F.neighborhood.R"))

# Read data
run_yr <- 2014
if (run_yr == 2014) {
  taxi_raw_2014 <- fread(paste0(data_path, "nyc_taxi_data.csv"))
  taxi_raw <- taxi_raw_2014
} else if (run_yr == 2015) {
  taxi_raw_2015 <- fread(paste0(data_path, "yellow_tripdata_2015-01-06.csv"))
  setnames(taxi_raw_2015, "tpep_pickup_datetime", "pickup_datetime")
  setnames(taxi_raw_2015, "tpe p_dropoff_datetime", "dropoff_datetime")
  taxi_raw <- taxi_raw_2015
} else stop("Incorrect run year")

comma(nrow(taxi_raw))
names(taxi_raw)
head(taxi_raw)

# Take a random sample for data exploration
taxi_sample <- taxi_raw[sample(.N, 10000)]
write.csv(taxi_sample, paste0(analysis_path, "taxi_sample_raw.csv"))
saveRDS(taxi_sample, paste0(analysis_path, "taxi_sample_raw.Rda"))

# Clean data / create working variables
taxi_sample[, `:=`(
    pickup_dtime = ymd_hms(taxi_sample$pickup_datetime)
    ,dropoff_dtime = ymd_hms(taxi_sample$dropoff_datetime)
)]
taxi_sample[, `:=`(
    pickup_wday = wday(pickup_dtime)
    ,dropoff_wday = wday(dropoff_dtime)
    ,pickup_wday_l = wday(pickup_dtime, label = T)
    ,dropoff_wday_l = wday(dropoff_dtime, label = T)
    ,pickup_month = month(pickup_dtime)
    ,dropoff_month = month(dropoff_dtime)
    ,pickup_month_l = month(pickup_dtime, label = T)
    ,dropoff_month_l = month(dropoff_dtime, label = T)
)]

# Neighborhood lookup from Google API, but limit 2,500 free queries per day
# (100,000 paid queries per day)
gc <- as.matrix(taxi_sample[1, .(pickup_longitude[1], pickup_latitude[1])])
rgc <- revgeocode(gc, output = 'more')
rgc$neighborhood
geocodeQueryCheck()

# Map coordinates to neighborhoods using Zillow shapefile
NY_nhoods <- readShapePoly(paste0(data_path, "ZillowNeighborhoods-NY/ZillowNeighborhoods-NY.shp"))

taxi_sample$pickup_nhood <- map_neighborhoods(NY_nhoods, taxi_sample$pickup_longitude, taxi_sample$pickup_latitude)
taxi_sample$dropoff_nhood <- map_neighborhoods(NY_nhoods, taxi_sample$dropoff_longitude, taxi_sample$dropoff_latitude)
taxi_sample[, .N, .(pickup_nhood, dropoff_nhood)]

city_nhood <- as.data.table(tstrsplit(unique(paste0(NY_nhoods$CITY, ";", NY_nhoods$NAME)), ";"))
names(city_nhood) <- c("city_borough", "neighborhood")
city_nhood[, c("city", "borough") := tstrsplit(city_borough, "-")]

# Test for duplicates
cities_w_dups <- city_nhood[, .N, neighborhood][N == 2]$neighborhood
city_nhood[neighborhood %in% cities_w_dups][order(city)]

taxi_sample <- merge(x = taxi_sample, y = city_nhood[, .(neighborhood, pickup_city = city, pickup_borough = borough)], by.x = "pickup_nhood", by.y = "neighborhood", all.x = T)
taxi_sample <- merge(x = taxi_sample, y = city_nhood[, .(neighborhood, dropoff_city = city, dropoff_borough = borough)], by.x = "dropoff_nhood", by.y = "neighborhood", all.x = T)
if (nrow(taxi_sample) != 10000) warning("Merge error")

saveRDS(taxi_sample, paste0(analysis_path, paste0("taxi_sample_processed_", run_yr, ".Rda")))

# Exploratory analysis
taxi_sample[, .(
    num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    , by = payment_type]

taxi_sample[order(pickup_wday), .(
    num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    ,by = pickup_wday_l]

taxi_sample[order(pickup_month), .(
     num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    ,by = pickup_month_l]

taxi_sample[, .(
    num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    ,by = .(pickup_city, dropoff_city)]

taxi_sample[, .(
  num_trips = comma(.N)
  ,avg_fare = dollar(mean(fare_amount))
  ,sum_fare = dollar(sum(fare_amount))
  ,avg_tip = dollar(mean(tip_amount))
  ,sum_tip = dollar(sum(tip_amount))
  ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
  ,by = .(dropoff_borough)]

