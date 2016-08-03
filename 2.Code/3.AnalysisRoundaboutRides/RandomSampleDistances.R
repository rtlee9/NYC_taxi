# **************************************************************************** 
# Identify roundabout rides - compare random sample of recorded trip distances
# to Google Maps distance expecation 
# ****************************************************************************

# Setup
library(RPostgreSQL, quietly = T)
library(data.table, quietly = T)
library(scales, quietly = T)
library(lubridate, quietly = T)
library(ggmap, quietly = T)
library(ggthemes, quietly = T)
library(rCharts, quietly = T)

# Set paths
setwd("/Users/Ryan/Github/NYC_taxi/2.Code/3.AnalysisRoundaboutRides/")
analysisPath <- "../../3.Analysis/"

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
saveRDS(rand_trips, paste0(analysisPath, "rand_trips_full.Rda"))
rand_trips <- readRDS(paste0(analysisPath, "rand_trips_full.Rda"))

# Import and clean data
result <- tryCatch({
  file.list <- lapply(Sys.glob(paste0(analysisPath, "rand_trips_mapped_*.Rda")),readRDS)
  mapped <- rbindlist(file.list)
  print(paste(nrow(mapped), "records imported"))
}, error = function(err) {
  print("No files found")
  return(NULL)
})

if (is.null(result)) {
  (i <- 1)
} else {
  (i <- max(mapped$batchID) + 1)
}

# Select current batch
batchSize <- 2500
startN <- batchSize*(i-1)+1
endN <- batchSize*i
rand_trips_sample <- rand_trips[startN:endN]
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

# Distribution of actual v expected distance
mappedCurrent[, actualExepcted := trip_distance/miles]
ggplot(mappedCurrent[actualExepcted < 2], aes(x=actualExepcted)) + geom_density()
quantile(mappedCurrent[!is.na(actualExepcted)]$actualExepcted, c(.01, .05, .5, .95, .99))

# Deep dive into top 5% (exclude top 1%)

# Compare against geom_dist -- see if geom_dist compares to actual(with a
# constant multiplier)

