# ****************************************************************************
# Upload taxi data and other dimensional data to default PostgreSQL schema
#
# Inputs (see Resources.md for data sources)
# 1. 2014 taxi data: nyc_taxi_data.csv
# 2. 2015 taxi data: yellow_tripdata_2015-01-06.csv
# 3. 2014 weather data: weather_2014.csv
# 4. List of bank holidays: US bank holidays.csv
#
# Outputs (PostgreSQL default schema)
# 1. nyc_taxi_yellow_14
# 2. nyc_taxi_yellow_15_1
# 3. weather_14
# 4. holidays
# 5. price_index
# 6. econ_index
# ****************************************************************************

# Load packages
reqPackages <- c("RPostgreSQL", "quantmod", "data.table", "lubridate")
reqDownloads <- !reqPackages %in% rownames(installed.packages())
if (any(reqDownloads)) install.packages(reqPackages[reqDownloads], dependencies = T, repos = "http://cran.us.r-project.org")
loadSuccess <- lapply(reqPackages, require, character.only = T)
if (any(!unlist(loadSuccess))) stop(paste("\n\tPackage load failed:", reqPackages[unlist(loadSuccess) == F]))

# Other setup
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, dbname = "nyc-taxi-data", password="", host="localhost", port=5432)
dataPath <- "1.Data/"

# Taxi data
dbWriteTable(con,'nyc_taxi_yellow_14', fread(paste0(dataPath, "nyc_taxi_data.csv")), row.names=FALSE)
dbWriteTable(con,'nyc_taxi_yellow_15_1', fread(paste0(dataPath, "yellow_tripdata_2015-01-06.csv")), row.names=FALSE)
dbSendQuery(con, "ALTER TABLE nyc_taxi_yellow_14 ADD COLUMN id BIGSERIAL PRIMARY KEY;")
dbSendQuery(con, "ALTER TABLE nyc_taxi_yellow_15_1 ADD COLUMN id BIGSERIAL PRIMARY KEY;")

# Weather data: 2014
weather <- fread(paste0(dataPath, "weather_2014.csv"))
names(weather) <- gsub(" ", "_", names(weather))
weather[, date := mdy(EST)]
weather[, WindDirDegrees := tstrsplit(`WindDirDegrees<br_/>`, "<")[1]]
weather[, `WindDirDegrees<br_/>` := NULL]
dbWriteTable(con,'weather_14', weather, row.names=FALSE)

# Weather data: 2015
weather <- fread(paste0(dataPath, "weather_2015.csv"))
names(weather) <- gsub(" ", "_", names(weather))
weather[, date := mdy(EST)]
weather[, WindDirDegrees := tstrsplit(`WindDirDegrees<br_/>`, "<")[1]]
weather[, `WindDirDegrees<br_/>` := NULL]
dbWriteTable(con,'weather_15', weather, row.names=FALSE)

# Holiday data
hdays <- fread(paste0(dataPath, "US bank holidays.csv"))
hdays[, V1 := NULL]
setnames(hdays, c("V2", "V3"), c("date_char", "hday_name"))
hdays[, date := ymd(date_char)]
hdays[, date_char := NULL]
dbWriteTable(con,'holidays', hdays, row.names=FALSE)

# Index data
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
dbWriteTable(con,'price_index', price, row.names=FALSE)

# Economic data
econ_dt <- NULL
for (ticker in c("CPIAUCSL", "UNRATE", "DFII10", "TWEXB", "CUSR0000SETB01")) {
  tmp_dt <- tryCatch(as.data.table(getSymbols(ticker, auto.assign = FALSE, src = "FRED")),
                     error=function(e){print(paste(ticker,'not found'));NA})
  if (!is.null(tmp_dt) && !is.na(tmp_dt) && nrow(tmp_dt) > 0) {
    tmp_dt$ticker <- gsub("\\^", "", ticker)
    setnames(tmp_dt, "index", "date")
    setnames(tmp_dt, ticker, "value")
    setkey(tmp_dt, date)
    tmp_dt <- tmp_dt[complete.cases(tmp_dt)]
    econ_dt <- rbindlist(list(econ_dt, tmp_dt))
  }
}
dbWriteTable(con,'econ_index', econ_dt, row.names=FALSE)

discStatus <- dbDisconnect(con)
if(discStatus == F) warning("Disconnect error")
