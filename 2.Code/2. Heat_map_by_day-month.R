# ****************************************************************************
# Map pickup locations by day of week
# ****************************************************************************

NYC <- get_map(c(lon = -73.99, lat = 40.745), zoom = 13)
NYC_map <- ggmap(NYC, extent = "panel")

NYC_map + stat_density2d(
        aes(x = pickup_longitude, y = pickup_latitude, fill = ..level.., alpha = ..level..),
        size = .5, bins = 9, data = taxi_sample,
        geom = "polygon") +
    scale_fill_gradient(low = "white", high = "orange") +
    scale_alpha(guide = 'none') +
    facet_wrap(~ pickup_wday_l, nrow = 2) +
    theme(legend.position = "bottom")

# ****************************************************************************
# Map pickup locations by day of week
# ****************************************************************************

# ****************************************************************************
# Map pickup locations by month
# ****************************************************************************

# ****************************************************************************
# Map pickup locations by month
# ****************************************************************************

# ****************************************************************************
# Alternative maps
# ****************************************************************************
#NYC <- get_map("manhattan", zoom = 12)
#NYC <- get_map("penn station", zoom = 13)