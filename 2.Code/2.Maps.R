# ****************************************************************************
# Plot maps
# ****************************************************************************

# Load maps
NYC <- get_map(c(lon = -73.99, lat = 40.745), zoom = 13)
NYC_bw <- get_map(c(lon = -73.99, lat = 40.745), zoom = 13, color = "bw")
NYC_map <- ggmap(NYC, extent = "device")
NYC_map_bw <- ggmap(NYC_bw, extent = "device")

# Dot plot: pickups and dropoffs
NYC_map_bw +
  geom_point(size=0.2, alpha = 1/2, aes(pickup_longitude, pickup_latitude, color="pickup"), data=taxi_working) +
  geom_point(size=0.2, alpha = 1/2, aes(dropoff_longitude, dropoff_latitude, color="dropoff"), data=taxi_working) + 
  scale_colour_tableau()

# Map pickup locations by day of week
NYC_map + stat_density2d(
        aes(x = pickup_longitude, y = pickup_latitude, fill = ..level.., alpha = ..level..),
        size = .5, bins = 9, data = taxi_working,
        geom = "polygon") +
    scale_fill_gradient(low = "white", high = "orange") +
    scale_alpha(guide = 'none') +
    facet_wrap(~ pickup_wday_l, nrow = 2) +
    theme(legend.position = "bottom")

# Map pickup locations by day of week

# Map pickup locations by month

# Map pickup locations by month

# Map dropoff locations by pickup location

top_pickups <- taxi_working[!is.na(pickup_nhood), .N, by = .(pickup_nhood)][order(-N)][1:16]$pickup_nhood
NYC_map + stat_density2d(
        aes(x = dropoff_longitude, y = dropoff_latitude, fill = ..level.., alpha = ..level..),
        size = .5, bins = 9, data = taxi_working[pickup_nhood %in% top_pickups],
        geom = "polygon") +
    scale_fill_gradient(low = "white", high = "orange") +
    scale_alpha(guide = 'none') +
    facet_wrap(~ pickup_nhood, ncol = 4) +
    theme(legend.position = "bottom")

NYC_map +
  geom_point(size=0.2, alpha = 1/2, aes(pickup_longitude, pickup_latitude, color="pickup"), data=taxi_working[pickup_nhood %in% top_pickups]) +
  geom_point(size=0.2, alpha = 1/2, aes(dropoff_longitude, dropoff_latitude, color="dropoff"), data=taxi_working[pickup_nhood %in% top_pickups]) +
  geom_segment(data = taxi_working[pickup_nhood %in% top_pickups], aes(x = pickup_longitude, y = pickup_latitude, xend = dropoff_longitude, yend = dropoff_latitude), color = 'grey50', size = 0.05) +
  scale_alpha(guide = 'none') +
  facet_wrap(~ pickup_nhood, ncol = 4) +
  theme(legend.position = "bottom")

# ****************************************************************************
# Alternative maps
# ****************************************************************************
#NYC <- get_map("manhattan", zoom = 12)
#NYC <- get_map("penn station", zoom = 13)