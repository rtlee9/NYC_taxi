# ****************************************************************************
# Plot maps
# ****************************************************************************

# Load maps
map_center <- c(lon = -73.968, lat = 40.775)
NYC <- get_googlemap(map_center, zoom = 12, size = c(350, 640))
NYC_bw <- get_googlemap(map_center, zoom = 12, size = c(350, 640), color = "bw")
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

# Map dropoff locations by pickup location
NYC_map +
  geom_point(size=0.2, alpha = 1/2, aes(pickup_longitude, pickup_latitude, color="pickup"), data=taxi_working[pickup_nhood %in% top_pickups]) +
  geom_point(size=0.2, alpha = 1/2, aes(dropoff_longitude, dropoff_latitude, color="dropoff"), data=taxi_working[pickup_nhood %in% top_pickups]) +
  geom_segment(data = taxi_working[pickup_nhood %in% top_pickups], aes(x = pickup_longitude, y = pickup_latitude, xend = dropoff_longitude, yend = dropoff_latitude), color = 'grey50', size = 0.05) +
  scale_alpha(guide = 'none') + facet_wrap(~ pickup_nhood, ncol = 6) +
  theme(legend.position = "bottom") + scale_colour_tableau()

# ****************************************************************************
# Alternative maps
# ****************************************************************************
#NYC <- get_map("manhattan", zoom = 12)
#NYC <- get_map("penn station", zoom = 13)