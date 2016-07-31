# **************************************************************************** 
# Identify roundabout rides - compare random sample of recorded trip distances
# to Google Maps distance expecation 
# ****************************************************************************

# Setup
library(RPostgreSQL, quietly = T)
library(data.table, quietly = T)
library(scales, quietly = T)
library(ggmap, quietly = T)
library(ggthemes, quietly = T)
library(rCharts, quietly = T)
library(knitr, quietly = T)
library(vegan, quietly = T)
setwd("/Users/Ryan/Github/NYC_taxi/2.Code/2.Analysis")

# Load maps
map_center <- c(lon = -73.94, lat = 40.75)
NYC <- get_googlemap(map_center, zoom = 12, size = c(500, 640))
NYC_bw <- get_googlemap(map_center, zoom = 12, size = c(500, 640), color = "bw")
NYC_map <- ggmap(NYC, extent = "device")
NYC_map_bw <- ggmap(NYC_bw, extent = "device")

# Query data from PSQL server
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, password="", host="localhost", port=5432)
fileName <- 'query_rand2500.sql'
query_rand2500 <- readChar(fileName, file.info(fileName)$size)
rand_trips <- as.data.table(dbGetQuery(con, query_rand2500))
hold <- dbDisconnect(con)

# Get expected distances for random sample
rand_trips_sample <- rand_trips[1:1000] # TEMP
rand_trips_sample$from <- paste(rand_trips_sample$pickup_latitude, rand_trips_sample$pickup_longitude)
rand_trips_sample$to <- paste(rand_trips_sample$dropoff_latitude, rand_trips_sample$dropoff_longitude)
gdist <- as.data.table(mapdist(from = from, to = to, mode = 'driving', output = 'simple', messaging = F))
distQueryCheck()

# Merge back with trip data
rand_trips_mapped <- cbind(rand_trips_sample, gdist)
rand_trips_mapped[, actualExepcted := trip_distance/miles]
