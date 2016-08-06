# **************************************************************************** 
# Identify roundabout rides - compare random sample of recorded trip distances
# to Google Maps distance expecation 
# ****************************************************************************

# *************************************************
# Setup
# *************************************************

# Load packages
reqPackages <- c("RPostgreSQL", "data.table", "scales", "lubridate", "ggmap", "ggthemes", "rCharts", "e1071")
reqDownloads <- !reqPackages %in% rownames(installed.packages())
if (any(reqDownloads)) install.packages(wants[reqDownloads])
loadSuccess <- lapply(reqPackages, require, character.only = T)
if (any(!unlist(loadSuccess))) stop(paste("\n\tPackage load failed:", reqPackages[unlist(loadSuccess) == F]))

# Set paths
setwd("/Users/Ryan/Github/NYC_taxi/2.Code/3.AnalysisRoundaboutRides/")
analysisPath <- "../../3.Analysis/"

# Load maps
map_center <- c(lon = -73.94, lat = 40.75)
NYC <- get_googlemap(map_center, zoom = 12, size = c(500, 640))
NYC_bw <- get_googlemap(map_center, zoom = 12, size = c(500, 640), color = "bw")
NYC_map <- ggmap(NYC, extent = "device")
NYC_map_bw <- ggmap(NYC_bw, extent = "device")

# *************************************************
# Data & queries
# *************************************************

# Query data from PSQL server
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, password="", host="localhost", port=5432)
fileName <- 'query_rand.sql'
query_rand <- readChar(fileName, file.info(fileName)$size)
rand_trips <- as.data.table(dbGetQuery(con, query_rand))
hold <- dbDisconnect(con)

# Save full random sample (one time only)
saveRDS(rand_trips, paste0(analysisPath, "rand_trips_full.Rda"))
rand_trips <- readRDS(paste0(analysisPath, "rand_trips_full.Rda"))

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
quantile(mappedCurrent[!is.na(actualExepcted)]$actualExepcted, c(.01, .05, 0.1, .5, .9, .95, .99))

# Scatter plot of each trip
ggplot(mappedCurrent, aes(x=miles, y = trip_distance)) + geom_point(size = .05, alpha = .5)

# Interactive scatter (WIP)
# nPlot(trip_distance ~ miles, data = mappedCurrent, type = 'scatterChart')

# Deep dive into top 5% (exclude top 1%)

# Compare against geom_dist -- see if geom_dist compares to actual(with a
# constant multiplier)

# Compare against uber drivers
