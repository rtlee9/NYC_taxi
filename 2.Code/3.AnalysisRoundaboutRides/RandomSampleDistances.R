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
library(pastecs)
setwd("/Users/Ryan/Github/NYC_taxi/2.Code/3.AnalysisRoundaboutRides/")

# Load maps
map_center <- c(lon = -73.94, lat = 40.75)
NYC <- get_googlemap(map_center, zoom = 12, size = c(500, 640))
NYC_bw <- get_googlemap(map_center, zoom = 12, size = c(500, 640), color = "bw")
NYC_map <- ggmap(NYC, extent = "device")
NYC_map_bw <- ggmap(NYC_bw, extent = "device")

# Query data from PSQL server
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, password="", host="localhost", port=5432)
fileName <- 'query_rand100000.sql'
query_rand100000 <- readChar(fileName, file.info(fileName)$size)
rand_trips <- as.data.table(dbGetQuery(con, query_rand100000))
hold <- dbDisconnect(con)

# Save full random sample (one time only)
saveRDS(rand_trips, "../../3.Analysis/rand_trips_full.Rda")

# Set run number


# Get expected distances for random sample
rand_trips_sample <- rand_trips[1:1000] # TEMP
rand_trips_sample$from <- paste(rand_trips_sample$pickup_latitude, rand_trips_sample$pickup_longitude)
rand_trips_sample$to <- paste(rand_trips_sample$dropoff_latitude, rand_trips_sample$dropoff_longitude)
gdist <- as.data.table(mapdist(from = from, to = to, mode = 'driving', output = 'simple', messaging = F))
distQueryCheck()

# Merge back with trip data and save
rand_trips_mapped <- cbind(rand_trips_sample, gdist)
saveRDS(rand_trips_mapped, paste0("rand_trips_mapped_", today(), ".Rda"))

# Distribution of actual v expected distance
rand_trips_mapped[, actualExepcted := trip_distance/miles]
ggplot(rand_trips_mapped[actualExepcted < 3], aes(x=actualExepcted)) + geom_density()
quantile(rand_trips_mapped[!is.na(actualExepcted)]$actualExepcted, c(.01, .05, .5, .95, .99))

