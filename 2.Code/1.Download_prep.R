# Set wd and install libraries
library(RSocrata)
library(data.table)
shared_path <- "/home/ryan/shared/"
setwd("/home/ryan/github/NYC_taxi/")

# Download from API (2014)
#taxi_raw_2014 <- read.socrata("https://data.cityofnewyork.us/resource/gkne-dk5s.json")
taxi_raw_2014 <- fread(paste0(shared_path, "nyc_taxi_data.csv"))

# Download from API (2015, through June)
#taxi_raw <- read.socrata("https://data.cityofnewyork.us/resource/2yzn-sicd.json")

nrow(taxi_raw_2014)