# ****************************************************************************
# Prep data
# ****************************************************************************

# Set wd and install libraries
library(RSocrata, quietly = T)
library(data.table, quietly = T)
library(scales, quietly = T)
library(lubridate, quietly = T)
library(ggmap, quietly = T)
library(rgeos)
library(maptools, quietly = T)
library(rCharts, quietly = T)
library(scales, quietly = T)
library(quantmod, quietly = T)

setwd("E:/Github_personal/NYC_taxi/")
data_path <- "./1.Data/"
lib_path <- "./2.Code/"
analysis_path <- "./3.Analysis/"
plots_path <- "./4.Plots/"

read_ind <- T
run_yr <- 2014

if (!run_yr %in% c(2014, 2015)) stop("Run year not available")

# Read data
print("Reading data")
if (read_ind) {
    if (run_yr == 2014) {
        taxi_raw_2014 <- fread(paste0(data_path, "nyc_taxi_data.csv"))
        taxi_raw <- taxi_raw_2014
    } else if (run_yr == 2015) {
        taxi_raw_2015 <- fread(paste0(data_path, "yellow_tripdata_2015-01-06.csv"))
        setnames(taxi_raw_2015, "tpep_pickup_datetime", "pickup_datetime")
        setnames(taxi_raw_2015, "tpe p_dropoff_datetime", "dropoff_datetime")
        taxi_raw <- taxi_raw_2015
    } else stop("Incorrect run year")
}

run_data_prep <- function(run_yr, sample_ind = F, sample_size = 100, nchunks = 20, ichunk) {

    print("Checking data")
    if (sample_ind & !sample_size > 0) stop("Missing sample size")
    if (ichunk > nchunks) stop("ichunk must be smaller than or equal to nchunks")
    runname <- paste0(run_yr, "_", ifelse(sample_ind, paste0("sample_N", sample_size), paste0("full_", ichunk, "chunk", nchunks)))

    # Random sample or chunk data
    print("Chunking / sampling data")
    if (sample_ind) {
        taxi_working <- taxi_raw[sample(.N, sample_size)]
    } else {
        nrows <- nrow(taxi_raw)
        chunk_start <- floor((ichunk-1)/nchunks*nrows)
        chunk_end <- floor(ichunk/nchunks*nrows)
        if (ichunk > 1) chunk_start <- chunk_start + 1
        taxi_working <- taxi_raw[chunk_start:chunk_end]
    }

    # Clean data / create working variables
    print("Cleaning data")
    taxi_working[, `:=`(
        pickup_dtime = ymd_hms(pickup_datetime)
        ,dropoff_dtime = ymd_hms(dropoff_datetime)
        ,tip_pct = tip_amount/fare_amount
        ,total_amount = as.numeric(total_amount)
    )]
    taxi_working[, `:=`(
        pickup_wday = wday(pickup_dtime)
        ,pickup_wday_l = wday(pickup_dtime, label = T)
        ,dropoff_wday = wday(dropoff_dtime)
        ,dropoff_wday_l = wday(dropoff_dtime, label = T)
        ,pickup_month = lubridate::month(pickup_dtime)
        ,pickup_month_l = lubridate::month(pickup_dtime, label = T)
        ,quarter = quarter(pickup_dtime)
        ,pickup_dt = date(pickup_dtime)
        ,dropoff_dt = date(dropoff_dtime)
        ,pickup_hour = lubridate::hour(pickup_dtime)
        ,elapsed = as.numeric(dropoff_dtime - pickup_dtime)
        ,avg_speed = trip_distance/as.numeric(dropoff_dtime - pickup_dtime)*60*60
    )]
    taxi_working[, `:=`(
        pickup_pod = ifelse(pickup_hour <= 4 | pickup_hour >= 23, "Night",
                            ifelse(pickup_hour <= 10, "Morning commute",
                                   ifelse(pickup_hour <= 15, "Day",
                                          ifelse(pickup_hour <= 19, "Evening commute", "Expense cab")))),
        is_weekday = pickup_wday != 1 & pickup_wday != 7)]

    # Map coordinates to neighborhoods using Zillow shapefile
    print("Mapping coordinates to neighborhoods")
    NY_nhoods <- readShapePoly(paste0(data_path, "ZillowNeighborhoods-NY/ZillowNeighborhoods-NY.shp"))
    poi_pickup <- taxi_working[, .(x = pickup_longitude, y= pickup_latitude)]
    coordinates(poi_pickup) <- ~ x + y
    proj4string(poi_pickup) <- proj4string(NY_nhoods)
    poi_dropoff <- taxi_working[, .(x = dropoff_longitude, y= dropoff_latitude)]
    poi_dropoff[is.na(x) | is.na(y)] <- c(x = 0, y = 0)
    coordinates(poi_dropoff) <- ~ x + y
    proj4string(poi_dropoff) <- proj4string(NY_nhoods)

    pickup_poly <- over(poi_pickup, NY_nhoods)
    dropoff_poly <- over(poi_dropoff, NY_nhoods)
    taxi_working[, `:=`(
        pickup_nhood = pickup_poly$NAME, pickup_city = pickup_poly$CITY, pickup_county = pickup_poly$COUNTY, pickup_state = pickup_poly$STATE
        ,dropoff_nhood = dropoff_poly$NAME, dropoff_city = dropoff_poly$CITY, dropoff_county = dropoff_poly$COUNTY, dropoff_state = dropoff_poly$STATE
    )]
    taxi_working[, `:=`(pickup_borough = gsub("New York City-", "", pickup_city), dropoff_borough = gsub("New York City-", "", dropoff_city))]

    # Merge weather data
    print("Merging data with additional sources")
    weather <- fread(paste0(data_path, "weather_2014.csv"))
    names(weather) <- gsub(" ", "_", names(weather))
    weather[, date := mdy(EST)]
    weather[, WindDirDegrees := tstrsplit(`WindDirDegrees<br_/>`, "<")[1]]
    weather[, `WindDirDegrees<br_/>` := NULL]
    taxi_working <- merge(x = taxi_working, y = weather, by.x = "pickup_dt", by.y = "date", all.x = T)
    taxi_working[, `:=`(
        weather_snow = grepl("Snow", Events)
        ,weather_fog = grepl("Fog", Events)
        ,weather_rain = grepl("Rain", Events)
        ,weather_thunderstorm = grepl("Thunderstorm", Events)
    )]
    taxi_working[, WindDirDegrees := as.numeric(WindDirDegrees)]

    # Merge with holiday data
    hdays <- fread(paste0(data_path, "US bank holidays.csv"))
    hdays[, V1 := NULL]
    setnames(hdays, c("V2", "V3"), c("date_char", "hday_name"))
    hdays[, date := ymd(date_char)]
    hdays[, date_char := NULL]
    taxi_working <- merge(x = taxi_working, y = hdays, by.x = "pickup_dt", by.y = "date", all.x = T)
    taxi_working[, is_holiday := !is.na(hday_name)]
    setkey(taxi_working, pickup_dt)

    # Merge with stock data
    price_raw <- NULL
    for (ticker in c("^GSPC", "^RUT", "XLU", "XLP", "XLB", "XLE", "XLI", "XLK", "XLY", "XLV", "XLF")) {
        tmp_dt <- tryCatch(as.data.table(getSymbols(ticker, auto.assign = FALSE, src = "yahoo")),
                           error=function(e){print(paste(ticker,'not found'));NA})
        if (!is.null(tmp_dt) && !is.na(tmp_dt) && nrow(tmp_dt) > 0) {
            tmp_dt$ticker <- gsub("\\^", "", ticker)
            setnames(tmp_dt, "index", "date")
            names(tmp_dt) <- gsub(paste0("^", ticker, "\\."), "", names(tmp_dt))
            price_raw <- rbindlist(list(price_raw, tmp_dt))
        }
    }
    price <- dcast(price_raw, date ~ ticker, value.var = "Close")
    setkey(price, date)
    taxi_working <- price[taxi_working, roll = Inf]

    # Merge with economic data
    for (ticker in c("CPIAUCSL", "UNRATE", "DFII10", "TWEXB", "CUSR0000SETB01")) {
        tmp_dt <- tryCatch(as.data.table(getSymbols(ticker, auto.assign = FALSE, src = "FRED")),
                           error=function(e){print(paste(ticker,'not found'));NA})
        if (!is.null(tmp_dt) && !is.na(tmp_dt) && nrow(tmp_dt) > 0) {
            setnames(tmp_dt, "index", "date")
            setkey(tmp_dt, date)
            tmp_dt <- tmp_dt[complete.cases(tmp_dt)]
            taxi_working <- tmp_dt[taxi_working, roll = Inf]
        }
    }

    # Merge with rate desc
    rate_desc <- as.data.table(cbind(
        rate_code_chr = 1:6,
        rate_desc = c("Standard rate","JFK","Newark","Nassau or Westchester","Negotiated fare","Group ride")))
    rate_desc$rate_code <- as.integer(rate_desc$rate_code_chr)
    taxi_working <- merge(x = taxi_working, y = rate_desc, by = "rate_code", all.x = T)

    saveRDS(taxi_working, paste0(analysis_path, paste0("taxi_clean_", runname, ".Rda")))
}

n <- 10
for (i in 1:n) {
    print(paste(i, "of", n))
    run_data_prep(run_yr = 2014, sample_ind = FALSE, sample_size = 100000,
                  nchunks = n, ichunk = i)
}
