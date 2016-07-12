mhtn_nhoods <- unique(taxi_working[pickup_borough == "Manhattan"]$pickup_nhood)
library(ggthemes)

# ****************************************************************************
# Exploratory analysis
# ****************************************************************************

taxi_working <- readRDS(paste0(analysis_path, "taxi_working_processed_2014_sample.Rda"))

taxi_working[, .(
    num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    , by = payment_type]

taxi_working[order(pickup_wday), .(
    num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    ,by = pickup_wday_l]

taxi_working[order(pickup_month), .(
     num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    ,by = pickup_month_l]

taxi_working[, .(
    num_trips = comma(.N)
    ,avg_fare = dollar(mean(fare_amount))
    ,sum_fare = dollar(sum(fare_amount))
    ,avg_tip = dollar(mean(tip_amount))
    ,sum_tip = dollar(sum(tip_amount))
    ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
    ,by = .(pickup_city, dropoff_city)]

taxi_working[, .(
  num_trips = comma(.N)
  ,avg_fare = dollar(mean(fare_amount))
  ,sum_fare = dollar(sum(fare_amount))
  ,avg_tip = dollar(mean(tip_amount))
  ,sum_tip = dollar(sum(tip_amount))
  ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
  ,by = .(dropoff_borough)]

taxi_working[, .(
  num_trips = comma(.N)
  ,avg_fare = dollar(mean(fare_amount))
  ,sum_fare = dollar(sum(fare_amount))
  ,avg_tip = dollar(mean(tip_amount))
  ,sum_tip = dollar(sum(tip_amount))
  ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
  ,by = .(is_holiday)]

taxi_working[, .(
  num_trips = comma(.N)
  ,avg_fare = dollar(mean(fare_amount))
  ,sum_fare = dollar(sum(fare_amount))
  ,avg_tip = dollar(mean(tip_amount))
  ,sum_tip = dollar(sum(tip_amount))
  ,tip_pct = percent(sum(tip_amount)/sum(fare_amount)))
  ,by = .(pickup_nhood)]

# Best tippers
taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = dollar(mean(fare_amount))
  ,sum_fare = dollar(sum(fare_amount))
  ,avg_tip = dollar(mean(tip_amount))
  ,sum_tip = dollar(sum(tip_amount))
  ,tip_pct = percent(sum(tip_amount)/sum(fare_amount))
  ,sum_dist = comma(sum(trip_distance))
  ,avg_dist = mean(trip_distance))
  ,by = .(pickup_nhood)][order(-tip_pct)]

# Vendor ID
taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = dollar(mean(fare_amount))
  ,sum_fare = dollar(sum(fare_amount))
  ,avg_tip = dollar(mean(tip_amount))
  ,sum_tip = dollar(sum(tip_amount))
  ,tip_pct = percent(sum(tip_amount)/sum(fare_amount))
  ,sum_dist = comma(sum(trip_distance))
  ,avg_dist = mean(trip_distance))
  ,by = .(vendor_id)][order(num_trips)]


# ****************************************************************************
# Top tip drivers
# ****************************************************************************

# Base fare
bplot2 <- taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = mean(fare_amount)
  ,sum_fare = sum(fare_amount)
  ,avg_tip = mean(tip_amount)
  ,sum_tip = sum(tip_amount)
  ,tip_pct = sum(tip_amount)/sum(fare_amount)
  ,sum_dist = sum(trip_distance)
  ,avg_dist = mean(trip_distance))
  ,by = .(x_var = round(fare_amount/20, 1)*20)]
ggplot(data = bplot2[num_trips >= 10], aes(x = x_var, y = tip_pct)) +
  geom_bar(stat = "identity") + expand_limits(y = 0) + scale_y_continuous(labels = percent) + theme_hc() +
  labs(title = "Tip by base fare", y = "Tip as a % of base fare", x = "Fare excluding tip")

# Day of week
bplot1 <- taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = mean(fare_amount)
  ,sum_fare = sum(fare_amount)
  ,avg_tip = mean(tip_amount)
  ,sum_tip = sum(tip_amount)
  ,tip_pct = sum(tip_amount)/sum(fare_amount)
  ,sum_dist = sum(trip_distance)
  ,avg_dist = mean(trip_distance))
  ,by = .(dropoff_wday_l)]
ggplot(data = bplot1, aes(x = dropoff_wday_l, y = tip_pct)) +
  geom_bar(stat = "identity") + expand_limits(y = 0) + scale_y_continuous(name = "Tip %", labels = percent)

# Average speed
round_factor <- 10
bplot3 <- taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = mean(fare_amount)
  ,sum_fare = sum(fare_amount)
  ,avg_tip = mean(tip_amount)
  ,sum_tip = sum(tip_amount)
  ,tip_pct = sum(tip_amount)/sum(fare_amount)
  ,sum_dist = sum(trip_distance)
  ,avg_dist = mean(trip_distance))
  ,by = .(x_var = round(avg_speed/round_factor, 1)*round_factor)]
ggplot(data = bplot3[num_trips >= 10], aes(x = x_var, y = tip_pct)) +
  geom_bar(stat = "identity") + expand_limits(y = 0) + scale_y_continuous(labels = percent) + theme_hc() +
  labs(title = "Tip by average speed (MPH)", y = "Tip as a % of base fare", x = "Average speed (MPH)")

# Time of day and week
taxi_working$pod <- ordered(taxi_working$pickup_pod, levels = c("Night", "Morning commute", "Day", "Evening commute", "Expense cab"))
bplot5 <- taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = mean(fare_amount)
  ,sum_fare = sum(fare_amount)
  ,avg_tip = mean(tip_amount)
  ,sum_tip = sum(tip_amount)
  ,tip_pct = sum(tip_amount)/sum(fare_amount)
  ,sum_dist = sum(trip_distance)
  ,avg_dist = mean(trip_distance))
  ,by = .(x_var = pod, x2_var = pickup_wday_l)]
ggplot(data = bplot5[num_trips >= 10], aes(x = x_var, y = tip_pct)) +
  geom_bar(stat="identity") + expand_limits(y = 0) + scale_y_continuous(labels = percent) + theme_hc() +
  labs(title = "Tip by pickup hour", y = "Tip as a % of base fare", x = "Pickup hour") + facet_wrap(~ x2_var, nrow = 2)

# Elapsed time
round_factor <- 10
bplot6 <- taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = mean(fare_amount)
  ,sum_fare = sum(fare_amount)
  ,avg_tip = mean(tip_amount)
  ,sum_tip = sum(tip_amount)
  ,tip_pct = sum(tip_amount)/sum(fare_amount)
  ,sum_dist = sum(trip_distance)
  ,avg_dist = mean(trip_distance))
  ,by = .(x_var = round(elapsed/round_factor, 1)*round_factor)]
ggplot(data = bplot6[num_trips >= 10], aes(x = x_var, y = tip_pct)) +
  geom_bar(stat = "identity") + expand_limits(y = 0) + scale_y_continuous(labels = percent) + theme_hc() +
  labs(title = "Tip by elapsed time", y = "Tip as a % of base fare", x = "Elapsed time (sec)")


# Pickup neighborhood
bplot7 <- taxi_working[payment_type == "CRD" & pickup_nhood %in% mhtn_nhoods, .(
  num_trips = .N
  ,avg_fare = mean(fare_amount)
  ,sum_fare = sum(fare_amount)
  ,avg_tip = mean(tip_amount)
  ,sum_tip = sum(tip_amount)
  ,tip_pct = sum(tip_amount)/sum(fare_amount)
  ,sum_dist = sum(trip_distance)
  ,avg_dist = mean(trip_distance))
  ,by = .(x_var = pickup_nhood)]
ggplot(data = bplot7[num_trips >= 10], aes(x = x_var, y = tip_pct)) +
  geom_bar(stat = "identity") + expand_limits(y = 0) + scale_y_continuous(labels = percent) + theme_hc() +
  labs(title = "Tip by elapsed time", y = "Tip as a % of base fare", x = "Elapsed time (sec)")


gg < ggplot(data = dt, aes(x = reorder(route, Trips), y = Trips, fill = "temp")) +
  geom_bar(stat = "identity") + coord_flip() + expand_limits(y = 0) + scale_y_continuous(labels = scales::comma) + 
  labs(y = 'Trips', x = "Route") + theme_minimal() + scale_fill_tableau() + guides(fill=F)


gg <- ggplot(data = dt_plot, aes(x = reorder(route, trips), y = trips, fill = weekend)) +
  geom_bar(stat = "identity") + coord_flip() + expand_limits(y = 0) + scale_y_continuous(labels = scales::comma) + 
  labs(y = 'Trips', x = "Route") + theme_minimal() + scale_fill_tableau()