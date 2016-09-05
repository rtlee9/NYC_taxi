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

# Taxi data
taxi_14 <- fread(paste0(data_path, "nyc_taxi_data.csv"))
sample <- taxi_14[sample(.N, sample_size)]
saveRDS(sample, paste0(analysis_path, "taxi_14_sample_", sample_size, ".Rda"))