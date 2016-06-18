# ****************************************************************************
# Lookup the neighborhood of a single coordinate
# ****************************************************************************

NY_nhoods <- readShapePoly(paste0(data_path, "ZillowNeighborhoods-NY/ZillowNeighborhoods-NY.shp"))

for (name in NY_nhoods$NAME) {
  lons <- s[s$NAME == name,]@polygons[[1]]@Polygons[[1]]@coords[,1];
  lats <- s[s$NAME == name,]@polygons[[1]]@Polygons[[1]]@coords[,2];
  res <- point.in.polygon(lon, lat, lons, lats);
}