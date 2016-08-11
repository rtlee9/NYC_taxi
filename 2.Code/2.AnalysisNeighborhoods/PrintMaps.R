# ****************************************************************************
# Genrate trip dot plots by pickup neighborhood
# ****************************************************************************

# Load packages
reqPackages <- c("RPostgreSQL", "data.table", "ggmap", "ggthemes")
reqDownloads <- !reqPackages %in% rownames(installed.packages())
if (any(reqDownloads)) install.packages(wants[reqDownloads], dependencies = T)
loadSuccess <- lapply(reqPackages, require, character.only = T)
if (any(!unlist(loadSuccess))) stop(paste("\n\tPackage load failed:", reqPackages[unlist(loadSuccess) == F]))

# Query data from PSQL server
pg = dbDriver("PostgreSQL")
con = dbConnect(pg, dbname = "nyc-taxi-data", password="", host="localhost", port=5432)
pick_by_pick_neigh<- as.data.table(dbReadTable(con, "pick_by_pick_neigh"))
drop_by_pick_neigh <- as.data.table(dbReadTable(con, "drop_by_pick_neigh"))
manhattan_nhoods <- as.data.table(dbGetQuery(con, "select name from zillow_sp where city = 'New York City-Manhattan'"))
hold <- dbDisconnect(con)

# Load maps
map_center <- c(lon = -73.94, lat = 40.75)
NYC <- get_googlemap(map_center, zoom = 12, size = c(500, 640))
NYC_bw <- get_googlemap(map_center, zoom = 12, size = c(500, 640), color = "bw")
NYC_map <- ggmap(NYC, extent = "device")
NYC_map_bw <- ggmap(NYC_bw, extent = "device")

# Create function to plot pickup, dropoff locations
plot_neigh <- function(pick_by_pick_neigh, drop_by_pick_neigh, neigh, alpha_range, plot_method = "print", h = 6, w = 4) {
  gg <- NYC_map_bw +
    geom_point(size = 0.001, aes(alpha = trips, lon, lat, color="pickup"), data=pick_by_pick_neigh[pick_neigh == neigh]) +
    geom_point(size = 0.001, aes(alpha = trips, lon, lat, color="dropoff"), data=drop_by_pick_neigh[pick_neigh == neigh]) +
    scale_colour_manual(values = c("#FF7F0E", "#1F77B4")) +
    guides(color = guide_legend(override.aes = list(size=2))) +
    scale_alpha_continuous(range = alpha_range, trans = "sqrt", guide = 'none') + 
    ggtitle(neigh) + annotate("text", x = -73.875, y = 40.675, colour = "#2CA02C", label = "eightportions.com", fontface="bold.italic", family="Arial", size = 3)
  
  if (plot_method == "print"){return(gg)}
  if (plot_method == "save") {
    ggsave(filename = paste0("Pick_neigh_", neigh, '.png'), plot = gg, path = './5.Plots', dpi = 150, height = h, width = w, units = 'in')
  }
}

# Plot Manhattan pickups, by neighborhood
for (i in manhattan_nhoods[order(name)]$name) {
  if (i != 'Inwood') {
    print(paste('Printing plot for', i))
    plot_neigh(pick_by_pick_neigh, drop_by_pick_neigh, i, alpha_range = c(0.005, 0.80), "save", 6, 7)
  }
}
