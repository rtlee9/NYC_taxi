# ****************************************************************************
# Create random sample of taxi data for Google Maps API queries
# ****************************************************************************

# Setupd
sample_size <- 10000
set.seed(7298)

# Load packages
reqPackages <- c("RPostgreSQL", "quantmod", "data.table", "lubridate")
reqDownloads <- !reqPackages %in% rownames(installed.packages())
if (any(reqDownloads)) install.packages(reqPackages[reqDownloads], dependencies = T, repos = "http://cran.us.r-project.org")
loadSuccess <- lapply(reqPackages, require, character.only = T)
if (any(!unlist(loadSuccess))) stop(paste("\n\tPackage load failed:", reqPackages[unlist(loadSuccess) == F]))

# Other setup
data_path <- "1.Data/"
analysis_path <- "3.Analysis/"

# Read data from local machine, and exclude null coordinates
taxi_14 <- fread(paste0(data_path, "nyc_taxi_data.csv"))
taxi_14 <- taxi_14[pickup_longitude != 0 & pickup_latitude != 0 & dropoff_longitude != 0 & dropoff_latitude != 0]

# Save random sample of sample size sample_size
sample <- taxi_14[sample(.N, sample_size)]
saveRDS(sample, paste0(analysis_path, "taxi_14_sample_", sample_size, ".Rda"))