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
  scale_colour_manual(values = c("#FF7F0E", "#1F77B4"))


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

pg = dbDriver("PostgreSQL")
con = dbConnect(pg, password="", host="localhost", port=5432)
pick_by_pick_neigh<- as.data.table(dbReadTable(con, "pick_by_pick_neigh"))
drop_by_pick_neigh <- as.data.table(dbReadTable(con, "drop_by_pick_neigh"))
hold <- dbDisconnect(con)


alpha_range = c(0.005, 0.80)

plot_neigh <- function(pick_by_pick_neigh, drop_by_pick_neigh, neigh, alpha_range, plot_method = "print") {
  gg <- NYC_map_bw +
    geom_point(size = 0.001, aes(alpha = trips, lon, lat, color="pickup"), data=pick_by_pick_neigh[pick_neigh == neigh]) +
    geom_point(size = 0.001, aes(alpha = trips, lon, lat, color="dropoff"), data=drop_by_pick_neigh[pick_neigh == neigh]) +
    scale_colour_manual(values = c("#FF7F0E", "#1F77B4")) +
    guides(color = guide_legend(override.aes = list(size=2))) +
    scale_alpha_continuous(range = alpha_range, trans = "sqrt", guide = 'none') + 
    ggtitle(neigh) + annotate("text", x = -73.875, y = 40.675, colour = "#2CA02C", label = "eightportions.com", fontface="bold.italic", family="Arial", size = 2)
  
  
  if (plot_method == "print"){return(gg)}
  if (plot_method == "save") {
    ggsave(filename = paste0("Pick_neigh_", neigh, '.png'), plot = gg, path = '/Users/Ryan/Github/NYC_taxi/5.Plots', dpi = 150, height = 5, units = 'in')
  }
}

g <- plot_neigh(pick_by_pick_neigh, drop_by_pick_neigh, 'Chinatown', alpha_range, "print")
g
plot_neigh(pick_by_pick_neigh, drop_by_pick_neigh, 'Chinatown', alpha_range, "save")

for (i in manhattan_nhoods[order(name)]$name) {
  if (i != 'Inwood') {
    print(paste('Printing plot for', i))
    plot_neigh(pick_by_pick_neigh, drop_by_pick_neigh, i, alpha_range, "save")
  }
}
