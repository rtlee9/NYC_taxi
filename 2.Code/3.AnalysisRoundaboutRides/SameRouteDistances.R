# **************************************************************************** 
# Identify roundabout rides - examine recorded trip distance distribution for
# the same census block routes 
# ****************************************************************************

# Setup
library(RPostgreSQL, quietly = T)
library(data.table, quietly = T)
library(scales, quietly = T)
library(ggmap, quietly = T)
library(ggthemes, quietly = T)
library(rCharts, quietly = T)
library(knitr, quietly = T)
library(vegan, quietly = T)
setwd("/Users/Ryan/Github/NYC_taxi/2.Code/2.Analysis")

# Load maps
map_center <- c(lon = -73.94, lat = 40.75)
NYC <- get_googlemap(map_center, zoom = 12, size = c(500, 640))
NYC_bw <- get_googlemap(map_center, zoom = 12, size = c(500, 640), color = "bw")
NYC_map <- ggmap(NYC, extent = "device")
NYC_map_bw <- ggmap(NYC_bw, extent = "device")

# Query data from PSQL server
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, password="", host="localhost", port=5432)
top_trips <- as.data.table(dbGetQuery(con, "select * from top10routes_full"))
hold <- dbDisconnect(con)

# Plot long trips
NYC_map_bw +
  geom_point(size=0.2, alpha = .1, aes(pickup_longitude, pickup_latitude, color="pickup"), data=top_trips[rank == 5262223]) +
  geom_point(size=0.2, alpha = .1, aes(dropoff_longitude, dropoff_latitude, color="dropoff"), data=top_trips[rank == 5262223]) +
  #geom_segment(data = long, aes(x = pickup_longitude, y = pickup_latitude, xend = dropoff_longitude, yend = dropoff_latitude), color = 'grey80', size = 0.01) +
  scale_alpha(guide = 'none') + theme(legend.position = "bottom") + scale_colour_manual(values = c("#FF7F0E", "#1F77B4"))


# Plot long trips
NYC_map_bw +
  geom_point(size=0.2, alpha = .1, aes(pickup_longitude, pickup_latitude, color="pickup"), data=top_trips[rank == 3339340]) +
  geom_point(size=0.2, alpha = .1, aes(dropoff_longitude, dropoff_latitude, color="dropoff"), data=top_trips[rank == 3339340]) +
  #geom_segment(data = long, aes(x = pickup_longitude, y = pickup_latitude, xend = dropoff_longitude, yend = dropoff_latitude), color = 'grey80', size = 0.01) +
  scale_alpha(guide = 'none') + theme(legend.position = "bottom") + scale_colour_manual(values = c("#FF7F0E", "#1F77B4"))

# Find longest distance : geom_distance ratio
