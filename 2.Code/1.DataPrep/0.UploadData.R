library('RPostgreSQL')
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, password="", host="localhost", port=5432)

dbWriteTable(con,'nyc_taxi_yellow_14', fread(paste0(data_path, "nyc_taxi_data.csv")), row.names=FALSE)
dbWriteTable(con,'nyc_taxi_yellow_15_1', fread(paste0(data_path, "yellow_tripdata_2015-01-06.csv")), row.names=FALSE)

# Weather data
weather <- fread(paste0(data_path, "weather_2014.csv"))
names(weather) <- gsub(" ", "_", names(weather))
weather[, date := mdy(EST)]
weather[, WindDirDegrees := tstrsplit(`WindDirDegrees<br_/>`, "<")[1]]
weather[, `WindDirDegrees<br_/>` := NULL]
dbWriteTable(con,'weather_14', weather, row.names=FALSE)

# Holiday data
hdays <- fread(paste0(data_path, "US bank holidays.csv"))
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
dbWriteTable(con,'broad_index', price, row.names=FALSE)

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

dbWriteTable(con,'broad_index', price, row.names=FALSE)
