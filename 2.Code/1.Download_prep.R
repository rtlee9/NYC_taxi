# ****************************************************************************
# Prep data
# ****************************************************************************

# Set wd and install libraries
library(RSocrata)
library(data.table)
library(scales)
library(lubridate)
library(ggmap)
library(maptools)
library(rCharts)
library(scales)

setwd("E:/Github_personal/NYC_taxi/")
shared_path <- "E:/VM_Ubuntu_shared/"
data_path <- "./1.Data/"
lib_path <- "./2.Code/"
analysis_path <- "./3.Analysis"

map_neighborhoods <- dget(paste0(lib_path, "F.map_neighborhoods.R"))

# Download from API (2014)
#taxi_raw_2014 <- read.socrata("https://data.cityofnewyork.us/resource/gkne-dk5s.json")
taxi_raw_2014 <- fread(paste0(shared_path, "nyc_taxi_data.csv"))

# Download from API (2015, through June)
#taxi_raw <- read.socrata("https://data.cityofnewyork.us/resource/2yzn-sicd.json")

comma(nrow(taxi_raw_2014))
names(taxi_raw_2014)
head(taxi_raw_2014)

# Take a random sample for data exploration
taxi_sample <- taxi_raw_2014[sample(.N, 10000)]
write.csv(taxi_sample, paste0(data_path, "taxi_sample_raw.csv"))
saveRDS(taxi_sample, paste0(data_path, "taxi_sample_raw.Rda"))

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

saveRDS(taxi_sample, paste0(analysis_path, "taxi_sample_processed"))

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

