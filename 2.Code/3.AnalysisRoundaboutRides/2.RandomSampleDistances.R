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
analysis_path <- "3.Analysis/"
data_path <- "1.Data/"

# Import batch
sample_size <- 10000
batch <- readRDS(paste0(analysis_path, "taxi_14_sample_", sample_size, ".Rda"))

# *************************************************
# Data & queries
# *************************************************

# Import and clean data
mapped <- tryCatch({
  file.list <- lapply(Sys.glob(paste0(analysisPath, "rand_trips_mapped_*.Rda")),readRDS)
  return(rbindlist(file.list))
}, error = function(err) {
  return(NULL)
})

if (is.null(mapped) || nrow(mapped) == 0) {
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
saveRDS(rand_trips_mapped, paste0(analysis_path, "rand_trips_mapped_", i, ".Rda"))
